import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService()
      : _storage = const FlutterSecureStorage(
          // Enforces AES-256 encryption on Android
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
          // Locks data on iOS until the device has been unlocked at least once after a reboot
          iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
        );

  static const String _tokenKey = 'auth_jwt_token';
  static const String _roleKey = 'user_role';

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<void> saveUserRole(String role) async {
    await _storage.write(key: _roleKey, value: role);
  }

  Future<String?> getUserRole() async {
    return await _storage.read(key: _roleKey);
  }

  Future<void> clearSession() async {
    await _storage.deleteAll();
  }

  /// Reads a generic string value from the secure keystore
  Future<String?> read({required String key}) async {
    return await _storage.read(key: key);
  }

  /// Writes a generic string value to the secure keystore
  Future<void> write({required String key, required String value}) async {
    await _storage.write(key: key, value: value);
  }
}