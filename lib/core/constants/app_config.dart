enum ApiMode { mock, real }

class AppConfig {
  static const String baseUrl = 'http://localhost:3000';
  static const Duration apiTimeout = Duration(seconds: 10);
  static const ApiMode apiMode = ApiMode.real;
  static bool get useMockApi => apiMode == ApiMode.mock;
}
