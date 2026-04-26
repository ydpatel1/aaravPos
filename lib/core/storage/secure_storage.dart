import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/app_constants.dart';

class SecureStorage {
  SecureStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  // ── Token ──────────────────────────────────────────────────────────────────
  Future<void> saveToken(String token) =>
      _storage.write(key: AppConstants.tokenKey, value: token);

  Future<String?> getToken() => _storage.read(key: AppConstants.tokenKey);

  Future<void> clearToken() => _storage.delete(key: AppConstants.tokenKey);

  // ── Remember Me ────────────────────────────────────────────────────────────
  Future<void> saveRememberMe(bool value) =>
      _storage.write(key: AppConstants.rememberMeKey, value: value.toString());

  Future<bool> getRememberMe() async {
    final value = await _storage.read(key: AppConstants.rememberMeKey);
    return value == 'true';
  }

  // ── Credentials ────────────────────────────────────────────────────────────
  Future<void> saveEmail(String email) =>
      _storage.write(key: AppConstants.userEmailKey, value: email);

  Future<String?> getEmail() => _storage.read(key: AppConstants.userEmailKey);

  Future<void> savePassword(String password) =>
      _storage.write(key: AppConstants.userPasswordKey, value: password);

  Future<String?> getPassword() =>
      _storage.read(key: AppConstants.userPasswordKey);

  Future<void> deleteEmail() => _storage.delete(key: AppConstants.userEmailKey);

  Future<void> deletePassword() =>
      _storage.delete(key: AppConstants.userPasswordKey);

  // ── Kiosk Info (from login response) ──────────────────────────────────────
  Future<void> saveTenantId(String tenantId) =>
      _storage.write(key: AppConstants.tenantIdKey, value: tenantId);

  Future<void> saveOutletId(String outletId) =>
      _storage.write(key: AppConstants.outletIdKey, value: outletId);

  Future<String?> getTenantId() => _storage.read(key: AppConstants.tenantIdKey);

  Future<String?> getOutletId() => _storage.read(key: AppConstants.outletIdKey);

  // ── Clear All ──────────────────────────────────────────────────────────────
  Future<void> clearSession() async {
    await _storage.delete(key: AppConstants.tokenKey);
    await _storage.delete(key: AppConstants.tenantIdKey);
    await _storage.delete(key: AppConstants.outletIdKey);
  }
}
