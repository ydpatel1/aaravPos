import 'package:dio/dio.dart';

import 'dio_client.dart';

class ApiService {
  ApiService(this._client);

  final DioClient _client;

  Dio get _dio => _client.dio;

  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    return _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response<dynamic>> post(
    String path, {
    Map<String, dynamic>? data,
  }) {
    return _dio.post(path, data: data);
  }
}
