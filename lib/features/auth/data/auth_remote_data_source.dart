import '../../../core/network/api_service.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource(this._apiService);

  final ApiService _apiService;

  Future<String> login({required String email, required String password}) async {
    try {
      final response = await _apiService.post(
        'auth/login',
        data: <String, dynamic>{'email': email, 'password': password},
      );
      final data = response.data;
      if (data is Map<String, dynamic> && data['token'] is String) {
        return data['token'] as String;
      }
    } catch (_) {
      // Falls back to mocked token for local development.
    }
    return 'mock-token-${DateTime.now().millisecondsSinceEpoch}';
  }
}
