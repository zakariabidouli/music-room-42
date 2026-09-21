// Central config: backend URL must be configurable for tests (subject V.5).
class AppConfig {
  static String backendUrl = 'http://10.0.2.2:3000';
  static const platform = 'android'; // filled per device
  static const device = 'Pixel';
  static const appVersion = '1.0.0';
}
