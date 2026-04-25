import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/app_constants.dart';

class SecureStorage {
  SecureStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  Future<void> saveToken(String token) =>
      _storage.write(key: AppConstants.tokenKey, value: token);

  Future<String?> getToken() => _storage.read(key: AppConstants.tokenKey);

  Future<void> clearToken() => _storage.delete(key: AppConstants.tokenKey);

  Future<void> saveRememberMe(bool value) => _storage.write(
    key: AppConstants.rememberMeKey,
    value: value.toString(),
  );

  Future<bool> getRememberMe() async {
    final value = await _storage.read(key: AppConstants.rememberMeKey);
    return value == 'true';
  }

  Future<void> saveEmail(String email) =>
      _storage.write(key: AppConstants.userEmailKey, value: email);

  Future<String?> getEmail() => _storage.read(key: AppConstants.userEmailKey);

  Future<void> clearSession() async {
    await _storage.delete(key: AppConstants.tokenKey);
    await _storage.delete(key: AppConstants.userEmailKey);
  }
}
