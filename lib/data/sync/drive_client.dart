import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/logging.dart';
import 'drive_local_fs_io.dart'
    if (dart.library.html) 'drive_local_fs_web.dart' as local_fs;

/// Result of downloading a backup blob from a [DriveClient].
class DriveBlob {
  const DriveBlob({
    required this.bytes,
    this.fileId,
    this.revision,
  });

  final Uint8List bytes;
  final String? fileId;
  final String? revision;
}

/// Abstract backup transport. Local DB remains source of truth.
abstract class DriveClient {
  String get backendLabel;

  bool get isConnected;

  Future<void> connect();

  Future<void> disconnect();

  /// Upload encrypted backup bytes. Returns remote file id when applicable.
  Future<String?> upload(
    Uint8List bytes, {
    String? existingFileId,
  });

  /// Download latest backup, or null if none exists.
  Future<DriveBlob?> download();
}

/// Google Drive appDataFolder client (optional OAuth).
class GoogleDriveClient implements DriveClient {
  GoogleDriveClient({
    GoogleSignIn? googleSignIn,
    String fileName = defaultFileName,
  })  : _fileName = fileName,
        _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: const [drive.DriveApi.driveAppdataScope],
            );

  static const String defaultFileName = 'dotdotdot_backup.ddd';

  final GoogleSignIn _googleSignIn;
  final String _fileName;
  drive.DriveApi? _api;
  GoogleSignInAccount? _account;

  @override
  String get backendLabel => 'Google Drive';

  @override
  bool get isConnected => _api != null && _account != null;

  @override
  Future<void> connect() async {
    final account =
        await _googleSignIn.signInSilently() ?? await _googleSignIn.signIn();
    if (account == null) {
      throw StateError('Google Sign-In cancelled or unavailable');
    }
    final headers = await account.authHeaders;
    _account = account;
    _api = drive.DriveApi(_GoogleAuthClient(headers));
  }

  @override
  Future<void> disconnect() async {
    try {
      await _googleSignIn.signOut();
    } catch (e, st) {
      AppLog.w('Google sign-out failed', error: e, stackTrace: st);
    }
    _account = null;
    _api = null;
  }

  @override
  Future<String?> upload(
    Uint8List bytes, {
    String? existingFileId,
  }) async {
    final api = _api;
    if (api == null) throw StateError('Google Drive not connected');

    final media = drive.Media(
      Stream<List<int>>.fromIterable([bytes]),
      bytes.length,
      contentType: 'application/octet-stream',
    );

    if (existingFileId != null && existingFileId.isNotEmpty) {
      final updated = await api.files.update(
        drive.File(),
        existingFileId,
        uploadMedia: media,
      );
      return updated.id;
    }

    final meta = drive.File()
      ..name = _fileName
      ..parents = ['appDataFolder'];
    final created = await api.files.create(meta, uploadMedia: media);
    return created.id;
  }

  @override
  Future<DriveBlob?> download() async {
    final api = _api;
    if (api == null) throw StateError('Google Drive not connected');

    final listed = await api.files.list(
      spaces: 'appDataFolder',
      q: "name = '$_fileName' and trashed = false",
      $fields: 'files(id, name, headRevisionId)',
      pageSize: 1,
    );
    final files = listed.files;
    if (files == null || files.isEmpty) return null;
    final file = files.first;
    final id = file.id;
    if (id == null) return null;

    final media = await api.files.get(
      id,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;

    final builder = BytesBuilder(copy: false);
    await for (final chunk in media.stream) {
      builder.add(chunk);
    }
    return DriveBlob(
      bytes: builder.takeBytes(),
      fileId: id,
      revision: file.headRevisionId,
    );
  }
}

class _GoogleAuthClient extends http.BaseClient {
  _GoogleAuthClient(this._headers);

  final Map<String, String> _headers;
  final http.Client _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _inner.send(request);
  }
}

/// Local filesystem (or SharedPreferences on web) mirror for tests / no OAuth.
class LocalDriveClient implements DriveClient {
  LocalDriveClient({
    this.relativeDir = '.drive_mirror',
    this.fileName = 'backup.ddd',
    this.prefsKey = 'ddd_drive_mirror_backup',
  });

  final String relativeDir;
  final String fileName;
  final String prefsKey;

  bool _connected = false;

  @override
  String get backendLabel =>
      kIsWeb ? 'Local mirror (browser storage)' : 'Local mirror';

  @override
  bool get isConnected => _connected;

  @override
  Future<void> connect() async {
    if (!kIsWeb) {
      await local_fs.ensureLocalMirrorDir(relativeDir);
    }
    _connected = true;
  }

  @override
  Future<void> disconnect() async {
    _connected = false;
  }

  @override
  Future<String?> upload(
    Uint8List bytes, {
    String? existingFileId,
  }) async {
    if (!_connected) throw StateError('Local Drive mirror not connected');
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(prefsKey, base64Encode(bytes));
      return prefsKey;
    }
    await local_fs.writeLocalMirrorBytes(
      relativeDir: relativeDir,
      fileName: fileName,
      bytes: bytes,
    );
    return local_fs.localMirrorPath(
      relativeDir: relativeDir,
      fileName: fileName,
    );
  }

  @override
  Future<DriveBlob?> download() async {
    if (!_connected) throw StateError('Local Drive mirror not connected');
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final b64 = prefs.getString(prefsKey);
      if (b64 == null || b64.isEmpty) return null;
      return DriveBlob(bytes: base64Decode(b64), fileId: prefsKey);
    }
    final bytes = await local_fs.readLocalMirrorBytes(
      relativeDir: relativeDir,
      fileName: fileName,
    );
    if (bytes == null) return null;
    final path = await local_fs.localMirrorPath(
      relativeDir: relativeDir,
      fileName: fileName,
    );
    return DriveBlob(bytes: bytes, fileId: path);
  }
}

/// Alias used in tests / docs.
typedef FileDriveClient = LocalDriveClient;
