import 'package:aaravpos/domain/repo/auth_repository.dart';
import 'package:aaravpos/domain/model/auth_result.dart';

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
    final token = await _remoteDataSource.login(
      email: email,
      password: password,
    );
    await _secureStorage.saveToken(token);
    await _secureStorage.saveRememberMe(rememberMe);
    if (rememberMe) {
      await _secureStorage.saveEmail(email);
    }
    return AuthResult(token: token, email: email);
  }

  @override
  Future<bool> getRememberMe() => _secureStorage.getRememberMe();

  @override
  Future<String?> getRememberedEmail() => _secureStorage.getEmail();

  @override
  Future<void> logout() => _secureStorage.clearSession();
}
