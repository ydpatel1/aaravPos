import 'package:aaravpos/domain/model/auth_result.dart';
import 'package:aaravpos/domain/model/outlet_status.dart';
import 'package:aaravpos/domain/repo/auth_repository.dart';

import '../../core/storage/secure_storage.dart';
import 'auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remoteDataSource, this._secureStorage);

  final AuthRemoteDataSource _remoteDataSource;
  final SecureStorage _secureStorage;

  @override
  Future<AuthResult> login({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    // Login and get token + kiosk info in one call
    final loginResult = await _remoteDataSource.login(
      email: email,
      password: password,
    );

    // Persist token
    await _secureStorage.saveToken(loginResult.token);

    // Persist tenantId and outletId from kiosk object
    await _secureStorage.saveTenantId(loginResult.tenantId);
    await _secureStorage.saveOutletId(loginResult.outletId);

    // Persist remember-me credentials
    await _secureStorage.saveRememberMe(rememberMe);
    if (rememberMe) {
      await _secureStorage.saveEmail(email);
      await _secureStorage.savePassword(password);
    } else {
      await _secureStorage.deleteEmail();
      await _secureStorage.deletePassword();
    }

    return AuthResult(token: loginResult.token, email: email);
  }

  @override
  Future<OutletStatus> fetchOutletStatus() =>
      _remoteDataSource.fetchOutletStatus();

  @override
  Future<bool> getRememberMe() => _secureStorage.getRememberMe();

  @override
  Future<String?> getRememberedEmail() => _secureStorage.getEmail();

  @override
  Future<String?> getRememberedPassword() => _secureStorage.getPassword();

  @override
  Future<void> logout() => _secureStorage.clearSession();
}
