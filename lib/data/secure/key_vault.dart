import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure vault for BYOK API keys.
///
/// Settings / [ProviderAccount] rows store only a [ref] (e.g. provider id).
/// Raw secrets never enter Sembast.
///
/// Web note: on Flutter Web, `flutter_secure_storage` falls back to encrypted
/// browser storage (not OS keychain). Treat web key storage as weaker than
/// mobile/desktop; show a security note in Settings when running on web and
/// prefer not enabling “backup keys” to Drive.
class KeyVault {
  KeyVault([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  final FlutterSecureStorage _storage;

  static const String _prefix = 'ddd_key_';

  String _key(String ref) => '$_prefix$ref';

  Future<void> saveKey(String ref, String value) async {
    await _storage.write(key: _key(ref), value: value);
  }

  Future<String?> readKey(String ref) {
    return _storage.read(key: _key(ref));
  }

  Future<void> deleteKey(String ref) async {
    await _storage.delete(key: _key(ref));
  }

  Future<bool> containsKey(String ref) async {
    return (await readKey(ref)) != null;
  }
}
