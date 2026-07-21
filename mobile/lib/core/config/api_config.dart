class ApiConfig {
  static const _rawBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://musical-instrument-app-1.onrender.com',
  );

  static String get baseUrl {
    if (_rawBaseUrl.endsWith('/')) {
      return _rawBaseUrl.substring(0, _rawBaseUrl.length - 1);
    }
    return _rawBaseUrl;
  }
}
