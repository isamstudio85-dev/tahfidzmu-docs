import 'package:flutter_test/flutter_test.dart';
import 'package:tahfidz_app/database/db_helper.dart';

void main() {
  test('builds short numeric demo credentials from ids', () {
    final credential = DbHelper.buildDemoCredentialValue(
      'NIP-001',
      'Hasan Al-Fikri',
    );

    expect(credential, '0001');
    expect(RegExp(r'^\d+$').hasMatch(credential), isTrue);
    expect(credential.length, lessThanOrEqualTo(6));
  });
}
