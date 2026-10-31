import 'package:flutter_test/flutter_test.dart';
import 'package:home_finance/services/pan_lookup_service.dart';

void main() {
  test('live Flutter service retrieves all three profiles from Spring Boot and SQLite', () async {
    final api = PanLookupService();
    try {
      await api.signIn('8200229099', '123456');
      final examples = [
        ['QWERT1234L', 'CUS-1001', 'Saurav Kumar Patel', '782'],
        ['PLMNO5678K', 'CUS-1002', 'Priya Sharma', '715'],
        ['ZXCVB9012M', 'CUS-1003', 'Rahul Mehta', '642'],
      ];
      for (final example in examples) {
        final profile = await api.lookup(example[0]);
        expect(profile.value('customerId'), example[1]);
        expect(profile.value('fullName'), example[2]);
        expect(profile.value('simulatedCreditScore'), example[3]);
      }
    } finally { api.close(); }
  }, skip: !const bool.fromEnvironment('RUN_EMPLOYEE_LIVE'));
}
