import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as enc;
import 'package:sembast/sembast.dart';

import '../db/sembast_helpers.dart';
import '../db/stores.dart';
import '../secure/key_vault.dart';

/// Encrypted Drive / local-mirror backup package.
///
/// Local DB is source of truth. Providers are exported without raw API keys
/// unless [keys] is populated (opt-in via backupKeysEnabled).
class BackupPackage {
  const BackupPackage({
    required this.version,
    required this.exportedAt,
    required this.chats,
    required this.messages,
    required this.projects,
    required this.plans,
    required this.memory,
    required this.context,
    required this.providers,
    this.keys,
  });

  static const int currentVersion = 1;
  static const String backupKeyRef = 'drive_backup_key';

  final int version;
  final DateTime exportedAt;
  final List<Map<String, dynamic>> chats;
  final List<Map<String, dynamic>> messages;
  final List<Map<String, dynamic>> projects;
  final List<Map<String, dynamic>> plans;
  final List<Map<String, dynamic>> memory;
  final List<Map<String, dynamic>> context;
  final List<Map<String, dynamic>> providers;

  /// Optional map of keyVaultRef → raw secret. Omitted by default.
  final Map<String, String>? keys;

  Map<String, dynamic> toJson() => {
        'version': version,
        'exportedAt': exportedAt.toIso8601String(),
        'chats': chats,
        'messages': messages,
        'projects': projects,
        'plans': plans,
        'memory': memory,
        'context': context,
        'providers': providers,
        if (keys != null) 'keys': keys,
      };

  factory BackupPackage.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> listOf(String key) {
      final raw = json[key] as List<dynamic>? ?? const [];
      return raw
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(growable: false);
    }

    Map<String, String>? keys;
    final rawKeys = json['keys'];
    if (rawKeys is Map) {
      keys = rawKeys.map(
        (k, v) => MapEntry(k.toString(), v?.toString() ?? ''),
      );
    }

    return BackupPackage(
      version: json['version'] as int? ?? currentVersion,
      exportedAt: DateTime.parse(json['exportedAt'] as String),
      chats: listOf('chats'),
      messages: listOf('messages'),
      projects: listOf('projects'),
      plans: listOf('plans'),
      memory: listOf('memory'),
      context: listOf('context'),
      providers: listOf('providers'),
      keys: keys,
    );
  }

  /// Snapshot all Sembast stores (including soft-deleted rows).
  static Future<BackupPackage> exportFromDatabase(
    Database db, {
    KeyVault? keyVault,
    bool backupKeysEnabled = false,
  }) async {
    Future<List<Map<String, dynamic>>> dump(String name) async {
      final store = stringMapStoreFactory.store(name);
      final rows = await store.find(db);
      return rows.map(mapFromRecord).toList(growable: false);
    }

    Map<String, String>? keys;
    if (backupKeysEnabled && keyVault != null) {
      final providers = await dump(Stores.providers);
      keys = <String, String>{};
      for (final p in providers) {
        final ref = p['keyVaultRef'] as String?;
        if (ref == null || ref.isEmpty) continue;
        final secret = await keyVault.readKey(ref);
        if (secret != null && secret.isNotEmpty) {
          keys[ref] = secret;
        }
      }
      if (keys.isEmpty) keys = null;
    }

    return BackupPackage(
      version: currentVersion,
      exportedAt: DateTime.now().toUtc(),
      chats: await dump(Stores.chats),
      messages: await dump(Stores.messages),
      projects: await dump(Stores.projects),
      plans: await dump(Stores.planNodes),
      memory: await dump(Stores.memoryItems),
      context: await dump(Stores.contextDocs),
      providers: await dump(Stores.providers),
      keys: keys,
    );
  }

  /// Persist package rows into Sembast (full replace per store).
  Future<void> writeToDatabase(Database db) async {
    Future<void> writeAll(
      String name,
      List<Map<String, dynamic>> rows,
    ) async {
      final store = stringMapStoreFactory.store(name);
      await db.transaction((txn) async {
        await store.delete(txn);
        for (final row in rows) {
          final id = row['id'] as String?;
          if (id == null) continue;
          await store.record(id).put(txn, mapForPut(row));
        }
      });
    }

    await writeAll(Stores.chats, chats);
    await writeAll(Stores.messages, messages);
    await writeAll(Stores.projects, projects);
    await writeAll(Stores.planNodes, plans);
    await writeAll(Stores.memoryItems, memory);
    await writeAll(Stores.contextDocs, context);
    await writeAll(Stores.providers, providers);
  }

  /// Restore optional secrets into [keyVault].
  Future<void> restoreKeys(KeyVault keyVault) async {
    final map = keys;
    if (map == null) return;
    for (final entry in map.entries) {
      if (entry.value.isEmpty) continue;
      await keyVault.saveKey(entry.key, entry.value);
    }
  }

  // --- Encryption (AES-256-CBC via package:encrypt) ---

  /// Ensure a device backup key exists in the vault; returns base64 AES key.
  static Future<String> ensureBackupKey(KeyVault vault) async {
    final existing = await vault.readKey(backupKeyRef);
    if (existing != null && existing.isNotEmpty) return existing;

    final random = Random.secure();
    final bytes = Uint8List.fromList(
      List<int>.generate(32, (_) => random.nextInt(256)),
    );
    final encoded = base64Encode(bytes);
    await vault.saveKey(backupKeyRef, encoded);
    return encoded;
  }

  /// Encrypt JSON payload to an envelope byte blob.
  static Future<Uint8List> encrypt(
    BackupPackage package,
    KeyVault vault,
  ) async {
    final keyB64 = await ensureBackupKey(vault);
    final key = enc.Key.fromBase64(keyB64);
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final plain = utf8.encode(jsonEncode(package.toJson()));
    final encrypted = encrypter.encryptBytes(plain, iv: iv);
    final envelope = <String, dynamic>{
      'alg': 'AES-256-CBC',
      'v': currentVersion,
      'iv': iv.base64,
      'data': encrypted.base64,
    };
    return Uint8List.fromList(utf8.encode(jsonEncode(envelope)));
  }

  /// Decrypt envelope bytes back to a [BackupPackage].
  static Future<BackupPackage> decrypt(
    Uint8List blob,
    KeyVault vault,
  ) async {
    final keyB64 = await ensureBackupKey(vault);
    final envelope =
        jsonDecode(utf8.decode(blob)) as Map<String, dynamic>;
    final key = enc.Key.fromBase64(keyB64);
    final iv = enc.IV.fromBase64(envelope['iv'] as String);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final decrypted = encrypter.decryptBytes(
      enc.Encrypted.fromBase64(envelope['data'] as String),
      iv: iv,
    );
    final json = jsonDecode(utf8.decode(decrypted)) as Map<String, dynamic>;
    return BackupPackage.fromJson(json);
  }
}
