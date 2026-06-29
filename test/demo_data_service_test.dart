import 'package:flutter_test/flutter_test.dart';
import 'package:tahfidz_app/services/demo_data_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads demo data from bundled JSON asset', () async {
    final bundle = await DemoDataService.loadDemoData();

    expect(bundle.musyrifList, isNotEmpty);
    expect(bundle.halaqahList, isNotEmpty);
    expect(bundle.santriList, isNotEmpty);
    expect(bundle.musyrifList.first.nama, contains('Hasan'));
  });
}
