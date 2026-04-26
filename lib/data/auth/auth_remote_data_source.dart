import '../../core/network/api_service.dart';
import '../../domain/model/outlet_status.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource(this._apiService);

  final ApiService _apiService;

  Future<String> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiService.post(
        'auth/login',
        data: <String, dynamic>{'email': email, 'password': password},
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        if (data['success'] == false) {
          final message = data['message'] as String?;
          throw Exception(message ?? 'Invalid login credentials.');
        }
        if (data['token'] is String) {
          return data['token'] as String;
        }
      }
      throw Exception('Authentication token missing.');
    } catch (error) {
      if (error is Exception) {
        rethrow;
      }
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
