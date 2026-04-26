class AppConstants {
  static const String appName = 'AaravPOS';
  static const String baseUrl =
      'https://prod.aaravpos.com/api/v1/'; // Replace with actual API URL

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String rememberMeKey = 'remember_me';
  static const String userEmailKey = 'user_email';
  static const String userPasswordKey = 'user_password';
  static const String tenantIdKey = 'tenant_id';
  static const String outletIdKey = 'outlet_id';

  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Debounce
  static const Duration searchDebounce = Duration(milliseconds: 500);
}
