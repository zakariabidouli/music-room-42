// Central config: backend URL must be configurable for tests (subject V.5).
// Compile-time default via `flutter build web --dart-define=BACKEND_URL=...`
// (see mobile/Dockerfile); runtime override in Settings screen, persisted
// locally with shared_preferences.
import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  static String backendUrl = const String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'http://10.0.2.2:3001',
  );
  static const backendUrlKey = 'mr_backend_url';
  static const platform = 'android'; // filled per device
  static const device = 'Pixel';
  static const appVersion = '1.0.0';

  /// Load the persisted Settings override (if any) at startup.
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(backendUrlKey);
    if (saved != null && saved.isNotEmpty) backendUrl = saved;
  }

  static Future<void> saveBackendUrl(String url) async {
    backendUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(backendUrlKey, url);
  }
}
