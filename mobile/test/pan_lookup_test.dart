import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:home_finance/services/pan_lookup_service.dart';

void main() {
  test('PAN normalization and validation', () {
    expect(PanLookupService.valid(' abcde1234f '), isTrue);
    expect(PanLookupService.valid('123'), isFalse);
  });
  test('employee token and exact repeated lookups', () async {
    final seen = <String>[];
    final service = PanLookupService(
      client: MockClient((request) async {
        if (request.url.path.endsWith('demo-session')) {
          return http.Response('{"token":"demo-token"}', 200);
        }
        expect(request.headers['Authorization'], 'Bearer demo-token');
        final pan = jsonDecode(request.body)['panNumber'] as String;
        seen.add(pan);
        return http.Response(
          jsonEncode({
            'data': {'customerId': pan},
          }),
          200,
        );
      }),
    );
    await service.signIn('8200229099', '123456');
    expect(
      (await service.lookup('abcde1234f')).value('customerId'),
      'ABCDE1234F',
    );
    await service.lookup('PQRST5678Z');
    expect(seen, ['ABCDE1234F', 'PQRST5678Z']);
    service.close();
  });
  test('not found has useful message', () async {
    final service = PanLookupService(
      client: MockClient(
        (_) async =>
            http.Response('{"message":"No customer record found."}', 404),
      ),
    );
    await expectLater(service.lookup('ZZZZZ9999Z'), throwsA(isA<Exception>()));
    service.close();
  });
}
