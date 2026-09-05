import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Provides hardware-backed secure storage for sensitive credentials.
class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
          iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
        );

  static const String _tokenKey = 'auth_jwt_token';
  static const String _roleKey = 'user_role';
  static const String _userIdKey = 'user_id';
  static const String _userNameKey = 'user_name';
  static const String _societyIdKey = 'society_id';

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

  Future<void> saveUserId(int id) async {
    await _storage.write(key: _userIdKey, value: id.toString());
  }

  Future<int?> getUserId() async {
    final val = await _storage.read(key: _userIdKey);
    return val != null ? int.tryParse(val) : null;
  }

  Future<void> saveUserName(String name) async {
    await _storage.write(key: _userNameKey, value: name);
  }

  Future<String?> getUserName() async {
    return await _storage.read(key: _userNameKey);
  }

  Future<void> saveSocietyId(int id) async {
    await _storage.write(key: _societyIdKey, value: id.toString());
  }

  Future<int?> getSocietyId() async {
    final val = await _storage.read(key: _societyIdKey);
    return val != null ? int.tryParse(val) : null;
  }

  Future<void> clearSession() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _roleKey);
    await _storage.delete(key: _userIdKey);
    await _storage.delete(key: _userNameKey);
    await _storage.delete(key: _societyIdKey);
  }

  /// Reads a generic string value from the secure keystore.
  Future<String?> read({required String key}) async {
    return await _storage.read(key: key);
  }

  /// Writes a generic string value to the secure keystore.
  Future<void> write({required String key, required String value}) async {
    await _storage.write(key: key, value: value);
  }
}