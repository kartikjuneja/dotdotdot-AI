import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sembast/sembast.dart';

import '../../core/logging.dart';
import '../../domain/models/sync_meta.dart';
import '../db/sembast_helpers.dart';
import '../db/stores.dart';
import '../secure/key_vault.dart';
import 'backup_package.dart';
import 'drive_client.dart';
import 'sync_merger.dart';

enum DriveConnectionState {
  disconnected,
  connecting,
  connected,
  syncing,
  error,
}

class DriveSyncStatus {
  const DriveSyncStatus({
    required this.state,
    this.message,
    this.lastSyncAt,
    this.backupKeysEnabled = false,
    this.backendLabel,
  });

  final DriveConnectionState state;
  final String? message;
  final DateTime? lastSyncAt;
  final bool backupKeysEnabled;

  /// e.g. "Google Drive" or "Local mirror".
  final String? backendLabel;

  bool get isConnected =>
      state == DriveConnectionState.connected ||
      state == DriveConnectionState.syncing;

  bool get isLocalMirror =>
      backendLabel != null && backendLabel!.toLowerCase().contains('local');

  DriveSyncStatus copyWith({
    DriveConnectionState? state,
    Object? message = _unset,
    Object? lastSyncAt = _unset,
    bool? backupKeysEnabled,
    Object? backendLabel = _unset,
  }) {
    return DriveSyncStatus(
      state: state ?? this.state,
      message: identical(message, _unset) ? this.message : message as String?,
      lastSyncAt: identical(lastSyncAt, _unset)
          ? this.lastSyncAt
          : lastSyncAt as DateTime?,
      backupKeysEnabled: backupKeysEnabled ?? this.backupKeysEnabled,
      backendLabel: identical(backendLabel, _unset)
          ? this.backendLabel
          : backendLabel as String?,
    );
  }
}

const Object _unset = Object();

/// Local-first sync: export → encrypt → upload; download → decrypt → merge.
///
/// Drive (or local mirror) holds an encrypted backup blob; Sembast remains
/// the source of truth for the running app.
class DriveSyncService {
  DriveSyncService({
    Database? database,
    KeyVault? keyVault,
    DriveClient? client,
    SyncMerger? merger,
  })  : _db = database,
        _keyVault = keyVault ?? KeyVault(),
        _client = client,
        _merger = merger ?? const SyncMerger();

  static const String metaRecordId = 'default';

  Database? _db;
  KeyVault _keyVault;
  DriveClient? _client;
  final SyncMerger _merger;

  final _controller = StreamController<DriveSyncStatus>.broadcast();
  DriveSyncStatus _status = const DriveSyncStatus(
    state: DriveConnectionState.disconnected,
  );

  final _metaStore = stringMapStoreFactory.store(Stores.syncMeta);

  DriveSyncStatus get status => _status;

  DriveClient? get client => _client;

  /// Lazy-inject Database / KeyVault once the app finishes bootstrapping.
  void attach({Database? database, KeyVault? keyVault}) {
    if (database != null) _db = database;
    if (keyVault != null) _keyVault = keyVault;
  }

  Stream<DriveSyncStatus> watchStatus() async* {
    yield _status;
    yield* _controller.stream;
  }

  Future<bool> get isConnected async => _status.isConnected;

  Future<void> connect() async {
    _emit(_status.copyWith(
      state: DriveConnectionState.connecting,
      message: 'Connecting…',
    ));
    try {
      await _ensureDb();
      await _loadMetaIntoStatus();

      DriveClient? connected;
      String? fallbackNote;

      if (!kIsWeb) {
        try {
          final google = GoogleDriveClient();
          await google.connect();
          connected = google;
        } catch (e, st) {
          AppLog.w(
            'Google Drive unavailable; using local mirror',
            error: e,
            stackTrace: st,
          );
          fallbackNote =
              'Google Sign-In unavailable (configure OAuth client IDs for '
              'cloud sync). Using encrypted local mirror under '
              '.drive_mirror/backup.ddd.';
        }
      } else {
        fallbackNote =
            'Google Drive OAuth is not configured for web. '
            'Using browser local mirror storage.';
      }

      if (connected == null) {
        final local = LocalDriveClient();
        await local.connect();
        connected = local;
      }

      _client = connected;
      _emit(_status.copyWith(
        state: DriveConnectionState.connected,
        backendLabel: connected.backendLabel,
        message: fallbackNote ?? 'Connected to ${connected.backendLabel}.',
      ));
      await _persistMeta();
      AppLog.i('DriveSyncService: connected via ${connected.backendLabel}');
    } catch (e, st) {
      AppLog.e('Drive connect failed', error: e, stackTrace: st);
      _client = null;
      _emit(_status.copyWith(
        state: DriveConnectionState.error,
        message: 'Could not connect: $e',
        backendLabel: null,
      ));
    }
  }

  Future<void> disconnect() async {
    try {
      await _client?.disconnect();
    } catch (e, st) {
      AppLog.w('Drive disconnect error', error: e, stackTrace: st);
    }
    _client = null;
    final keysEnabled = _status.backupKeysEnabled;
    _emit(DriveSyncStatus(
      state: DriveConnectionState.disconnected,
      backupKeysEnabled: keysEnabled,
      message: 'Disconnected',
    ));
    await _persistMeta();
    AppLog.i('DriveSyncService: disconnected');
  }

  Future<void> syncNow() async {
    final client = _client;
    if (client == null || !_status.isConnected) {
      _emit(_status.copyWith(
        state: DriveConnectionState.error,
        message: 'Connect before syncing.',
      ));
      return;
    }

    _emit(_status.copyWith(state: DriveConnectionState.syncing));
    try {
      final db = await _ensureDb();
      final meta = await _readMeta();

      // 1) Pull remote (if any) → decrypt → merge into local.
      final remoteBlob = await client.download();
      var conflictCount = 0;
      if (remoteBlob != null) {
        final remotePkg =
            await BackupPackage.decrypt(remoteBlob.bytes, _keyVault);
        final localPkg = await BackupPackage.exportFromDatabase(
          db,
          keyVault: _keyVault,
          backupKeysEnabled: false,
        );
        final merged = _merger.mergePackages(
          localChats: localPkg.chats,
          localMessages: localPkg.messages,
          localProjects: localPkg.projects,
          localPlans: localPkg.plans,
          localMemory: localPkg.memory,
          localContext: localPkg.context,
          localProviders: localPkg.providers,
          remoteChats: remotePkg.chats,
          remoteMessages: remotePkg.messages,
          remoteProjects: remotePkg.projects,
          remotePlans: remotePkg.plans,
          remoteMemory: remotePkg.memory,
          remoteContext: remotePkg.context,
          remoteProviders: remotePkg.providers,
        );
        conflictCount = merged.conflictCount;
        final mergedPkg = BackupPackage(
          version: BackupPackage.currentVersion,
          exportedAt: DateTime.now().toUtc(),
          chats: merged.chats,
          messages: merged.messages,
          projects: merged.projects,
          plans: merged.plans,
          memory: merged.memory,
          context: merged.context,
          providers: merged.providers,
          keys: remotePkg.keys,
        );
        await mergedPkg.writeToDatabase(db);
        if (_status.backupKeysEnabled && remotePkg.keys != null) {
          await remotePkg.restoreKeys(_keyVault);
        }
      }

      // 2) Push encrypted local snapshot.
      final export = await BackupPackage.exportFromDatabase(
        db,
        keyVault: _keyVault,
        backupKeysEnabled: _status.backupKeysEnabled,
      );
      final encrypted = await BackupPackage.encrypt(export, _keyVault);
      final existingId = _usableRemoteFileId(client, meta?.driveFileId);
      final fileId = await client.upload(
        encrypted,
        existingFileId: existingId,
      );

      final now = DateTime.now().toUtc();
      final conflictNote = conflictCount > 0
          ? ' ($conflictCount conflict copy${conflictCount == 1 ? '' : 'ies'})'
          : '';
      _emit(_status.copyWith(
        state: DriveConnectionState.connected,
        lastSyncAt: now,
        message:
            'Synced via ${client.backendLabel}$conflictNote at ${now.toIso8601String()}',
      ));
      await _persistMeta(
        driveFileId: fileId ?? meta?.driveFileId,
        revision: remoteBlob?.revision,
        conflictState: conflictCount > 0 ? '$conflictCount conflicts' : null,
      );
      AppLog.i('DriveSyncService: sync complete via ${client.backendLabel}');
    } catch (e, st) {
      AppLog.e('Drive sync failed', error: e, stackTrace: st);
      _emit(_status.copyWith(
        state: DriveConnectionState.error,
        message: 'Sync failed: $e',
      ));
      await _persistMeta(conflictState: '$e');
    }
  }

  Future<void> setBackupKeysEnabled(bool enabled) async {
    if (kIsWeb && enabled) {
      AppLog.w('Refusing key backup on web (weaker secure storage)');
      _emit(_status.copyWith(
        backupKeysEnabled: false,
        message: 'Key backup is not recommended on web.',
      ));
      await _persistMeta();
      return;
    }
    _emit(_status.copyWith(backupKeysEnabled: enabled));
    await _persistMeta();
  }

  SyncMeta toMeta({required String id}) {
    return SyncMeta(
      id: id,
      lastSyncAt: _status.lastSyncAt,
      backupKeysEnabled: _status.backupKeysEnabled,
      conflictState: _status.state == DriveConnectionState.error
          ? _status.message
          : null,
    );
  }

  Future<Database> _ensureDb() async {
    final db = _db;
    if (db == null) {
      throw StateError(
        'Database not attached. Wait for app bootstrap before syncing.',
      );
    }
    return db;
  }

  Future<SyncMeta?> _readMeta() async {
    final db = _db;
    if (db == null) return null;
    final snap = await _metaStore.record(metaRecordId).getSnapshot(db);
    if (snap == null) return null;
    return SyncMeta.fromJson(mapFromRecord(snap));
  }

  Future<void> _loadMetaIntoStatus() async {
    final meta = await _readMeta();
    if (meta == null) return;
    _emit(_status.copyWith(
      lastSyncAt: meta.lastSyncAt,
      backupKeysEnabled: meta.backupKeysEnabled,
    ));
  }

  Future<void> _persistMeta({
    String? driveFileId,
    String? revision,
    Object? conflictState = _unset,
  }) async {
    final db = _db;
    if (db == null) return;
    final existing = await _readMeta();
    final meta = SyncMeta(
      id: metaRecordId,
      driveFileId: driveFileId ?? existing?.driveFileId,
      revision: revision ?? existing?.revision,
      lastSyncAt: _status.lastSyncAt ?? existing?.lastSyncAt,
      conflictState: identical(conflictState, _unset)
          ? (_status.state == DriveConnectionState.error
              ? _status.message
              : existing?.conflictState)
          : conflictState as String?,
      backupKeysEnabled: _status.backupKeysEnabled,
    );
    await _metaStore.record(metaRecordId).put(db, mapForPut(meta.toJson()));
  }

  void _emit(DriveSyncStatus next) {
    _status = next;
    if (!_controller.isClosed) _controller.add(next);
  }

  Future<void> dispose() async {
    await _controller.close();
  }

  /// Avoid passing a local-mirror path into Google Drive update().
  static String? _usableRemoteFileId(DriveClient client, String? stored) {
    if (stored == null || stored.isEmpty) return null;
    if (client is LocalDriveClient) return stored;
    if (client is GoogleDriveClient) {
      if (stored.contains('/') ||
          stored.contains('\\') ||
          stored.startsWith('ddd_')) {
        return null;
      }
      return stored;
    }
    return stored;
  }
}
