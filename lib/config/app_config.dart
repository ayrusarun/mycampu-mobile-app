class AppConfig {
  // Backend URLs - Production Server Configuration
  //static const String baseUrl =
  //    'http://195.35.20.155:8000'; // Production API server
  static const String keycloakUrl = 'http://195.35.20.155:8080'; // Auth server

  // Development alternatives (commented out for production)
  // For Android Emulator (localhost development):
  static const String baseUrl = 'http://10.0.2.2:8000';
  // For Physical Device (local network):
  // static const String baseUrl = 'http://192.168.0.106:8000';

  static String get apiUrl => '$baseUrl/api/v1';
  static const String realm = 'mycampus';
  static const String clientId = 'mycampus';

  // API Endpoints
  static const String loginEndpoint =
      '/auth/login'; // Backend handles OAuth flow
  static const String logoutEndpoint = '/auth/logout'; // Backend handles logout
  static const String profileEndpoint = '/users/me/profile';
  static const String usersEndpoint = '/users/me';
}
