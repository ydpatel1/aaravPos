import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router/app_routes.dart';
import '../storage/secure_storage.dart';

class AuthInterceptor extends Interceptor {
  final SecureStorage _storage;
  final GlobalKey<NavigatorState> navigatorKey;

  AuthInterceptor(this._storage, this.navigatorKey);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Check if the error is 401 Unauthorized
    if (err.response?.statusCode == 401) {
      debugPrint('🔴 401 Unauthorized detected - logging out user');

      // Clear all stored data
      await _clearUserData();

      // Navigate to login screen (schedule after current frame to avoid navigation conflicts)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateToLogin();
      });

      // Return a custom error message
      return handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          response: err.response,
          type: err.type,
          error: 'Session expired. Please login again.',
        ),
      );
    }

    // For other errors, pass them through
    return handler.next(err);
  }

  Future<void> _clearUserData() async {
    try {
      debugPrint('🔴 Clearing user session data...');
      await _storage.clearSession();
      debugPrint('✅ User session data cleared');
    } catch (e) {
      debugPrint('❌ Error clearing user data: $e');
    }
  }

  void _navigateToLogin() {
    final context = navigatorKey.currentContext;
    debugPrint(
      '🔴 Attempting to navigate to login. Context available: ${context != null}',
    );

    if (context != null && context.mounted) {
      debugPrint('✅ Navigating to login screen');

      // Show snackbar message to inform user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session expired. Please login again.'),
          backgroundColor: Color(0xFFE12242),
          duration: Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Use GoRouter to navigate to login and clear the stack
      context.go(AppRoutes.login);
    } else {
      debugPrint('❌ Cannot navigate - context not available or not mounted');
    }
  }
}
