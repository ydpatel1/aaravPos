import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../storage/secure_storage.dart';
import 'auth_interceptor.dart';

class DioClient {
  late final Dio _dio;
  final SecureStorage _storage;
  final GlobalKey<NavigatorState>? navigatorKey;

  DioClient(this._storage, {this.navigatorKey}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: AppConstants.connectionTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add auth token interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
      ),
    );

    // Add 401 error handling interceptor
    if (navigatorKey != null) {
      _dio.interceptors.add(AuthInterceptor(_storage, navigatorKey!));
    }
  }

  Dio get dio => _dio;
}
