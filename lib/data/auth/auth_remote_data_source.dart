import '../../core/network/api_service.dart';
import '../../domain/model/outlet_status.dart';

/// Holds the token and kiosk metadata extracted from the login response.
class LoginResult {
  const LoginResult({
    required this.token,
    required this.tenantId,
    required this.outletId,
  });

  final String token;
  final String tenantId;
  final String outletId;
}

class AuthRemoteDataSource {
  AuthRemoteDataSource(this._apiService);

  final ApiService _apiService;

  Future<LoginResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiService.post(
        'auth/login',
        data: <String, dynamic>{'email': email, 'password': password},
      );
      final body = response.data;
      if (body is! Map<String, dynamic>) {
        throw Exception('Unexpected login response format.');
      }

      if (body['success'] == false) {
        final message = body['message'] as String?;
        throw Exception(message ?? 'Invalid login credentials.');
      }

      final nestedData = body['data'] as Map<String, dynamic>?;
      if (nestedData == null) {
        throw Exception('Authentication data missing.');
      }

      // Extract token
      final token = nestedData['token'] as String?;
      if (token == null || token.isEmpty) {
        throw Exception('Authentication token missing.');
      }

      // Extract tenantId and outletId from the nested "kiosk" object
      final kiosk = nestedData['kiosk'] as Map<String, dynamic>?;
      final tenantId = kiosk?['tenantId'] as String?;
      final outletId = kiosk?['outletId'] as String?;

      if (tenantId == null || outletId == null) {
        throw Exception('Kiosk configuration (tenantId/outletId) missing.');
      }

      return LoginResult(token: token, tenantId: tenantId, outletId: outletId);
    } catch (error) {
      if (error is Exception) rethrow;
      throw Exception('Login failed.');
    }
  }

  Future<OutletStatus> fetchOutletStatus() async {
    final response = await _apiService.get('outlet/status');
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return OutletStatus.fromJson(data);
    }
    throw Exception('Invalid outlet status response.');
  }
}
