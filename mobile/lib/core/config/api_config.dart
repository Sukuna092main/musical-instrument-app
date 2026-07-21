class ApiConfig {
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://musical-instrument-app-1.onrender.com/',
  );
}
