// Central config: backend URL must be configurable for tests (subject V.5).
// Compile-time override: `flutter build web --dart-define=BACKEND_URL=...`
// (see mobile/Dockerfile). Default keeps local Android emulator + tests working.
class AppConfig {
  static String backendUrl =
      const String.fromEnvironment('BACKEND_URL', defaultValue: 'http://10.0.2.2:3000');
  static const platform = 'android'; // filled per device
  static const device = 'Pixel';
  static const appVersion = '1.0.0';
}
