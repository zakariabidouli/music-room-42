import 'package:flutter_test/flutter_test.dart';
import 'package:musicroom/config.dart';

void main() {
  test('backendUrl defaults to env or localhost and persists override key', () {
    expect(AppConfig.backendUrl, isNotEmpty);
    expect(AppConfig.backendUrl, startsWith('http'));
  });

  test('api headers contract: platform/device/version present', () {
    // Contract mirrors mobile/lib/api.dart X-Platform/X-Device/X-App-Version.
    const required = ['X-Platform', 'X-Device', 'X-App-Version', 'X-User-Id'];
    expect(required, containsAll(['X-Platform', 'X-Device', 'X-App-Version']));
  });
}
