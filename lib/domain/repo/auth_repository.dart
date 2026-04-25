import '../model/auth_result.dart';

abstract class AuthRepository {
  Future<AuthResult> login({
    required String email,
    required String password,
    required bool rememberMe,
  });

  Future<void> logout();

  Future<bool> getRememberMe();

  Future<String?> getRememberedEmail();
}
