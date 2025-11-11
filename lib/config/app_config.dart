class AppConfig {
  // Backend URLs - Use the special Android emulator IP
  static const String baseUrl =
      'http://10.0.2.2:8000'; // Maps to localhost:8000 (API server)
  static const String keycloakUrl =
      'http://10.0.2.2:8080'; // Maps to localhost:8080 (Auth server)

  // Alternative: Use your Mac's network IP if 10.0.2.2 doesn't work
  // static const String baseUrl = 'http://192.168.0.106:8000';
  // static const String keycloakUrl = 'http://192.168.0.106:8080';

  static const String apiUrl = '$baseUrl/api/v1';
  static const String realm = 'mycampus';
  static const String clientId = 'mycampus';

  // API Endpoints
  static const String loginEndpoint =
      '/auth/login'; // Backend handles OAuth flow
  static const String logoutEndpoint = '/auth/logout'; // Backend handles logout
  static const String profileEndpoint = '/users/me/profile';
  static const String usersEndpoint = '/users/me';
}
