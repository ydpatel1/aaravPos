import '../model/auth_result.dart';
import '../model/outlet_status.dart';

abstract class AuthRepository {
  Future<AuthResult> login({
    required String email,
    required String password,
    required bool rememberMe,
  });

  Future<OutletStatus> fetchOutletStatus();

  Future<void> logout();

  Future<bool> getRememberMe();

  Future<String?> getRememberedEmail();

  Future<String?> getRememberedPassword();
}
