import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tahfidz_app/services/login_preferences_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('saves and restores last login credentials', () async {
    SharedPreferences.setMockInitialValues({});

    await LoginPreferencesService.saveLastCredentials(null, 'NIP-001', 'NIP-001');

    final restored = await LoginPreferencesService.loadLastCredentials();

    expect(restored, isNotNull);
    expect(restored!.username, 'NIP-001');
    expect(restored.password, 'NIP-001');
  });
}
