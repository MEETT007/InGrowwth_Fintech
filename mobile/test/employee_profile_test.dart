import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:home_finance/core/theme/app_theme.dart';
import 'package:home_finance/features/auth/controllers/auth_controller.dart';
import 'package:home_finance/features/employee/pan_details_controller.dart';
import 'package:home_finance/features/employee/pan_details_screen.dart';
import 'package:home_finance/services/pan_lookup_service.dart';

void main() {
  final profiles =
      (jsonDecode(
                File('test/fixtures/customer_profiles.json').readAsStringSync(),
              )
              as List)
          .cast<Map<String, dynamic>>();
  PanLookupService service() => PanLookupService(
    client: MockClient((request) async {
      final pan = jsonDecode(request.body)['panNumber'];
      final found = profiles.where(
        (p) => p['panInformation']['panNumber'] == pan,
      );
      if (found.isEmpty) {
        return http.Response('{"message":"No customer record found."}', 404);
      }
      return http.Response(jsonEncode({'data': found.first}), 200);
    }),
  );
  test(
    'nested profiles parse and sequential searches replace every section',
    () async {
      final api = service();
      final controller = PanDetailsController(api);
      for (final p in profiles) {
        await controller.fetch(p['panInformation']['panNumber'] as String);
        expect(
          controller.customer!.value('fullName'),
          p['basicInformation']['fullName'],
        );
        expect(
          controller.customer!.value('monthlyIncome'),
          p['employmentInformation']['monthlyIncome'].toString(),
        );
        expect(
          controller.customer!.homeLoans.length,
          (p['homeLoans'] as List).length,
        );
      }
      await controller.fetch('ZZZZZ9999Z');
      expect(controller.customer, isNull);
      expect(controller.error, contains('No customer'));
      controller.clear();
      expect(controller.error, isNull);
      controller.dispose();
      api.close();
    },
  );
  test('loading clears old results and prevents duplicates', () async {
    final pending = Completer<http.Response>();
    int requests = 0;
    final api = PanLookupService(
      client: MockClient((_) {
        requests++;
        return pending.future;
      }),
    );
    final c = PanDetailsController(api);
    final first = c.fetch('QWERT1234L');
    expect(c.loading, isTrue);
    expect(c.customer, isNull);
    await c.fetch('PLMNO5678K');
    await Future<void>.delayed(Duration.zero);
    expect(requests, 1);
    pending.complete(http.Response(jsonEncode({'data': profiles.first}), 200));
    await first;
    expect(c.loading, isFalse);
    expect(c.customer!.value('customerId'), 'CUS-1001');
    c.dispose();
    api.close();
  });
  for (final width in [375.0, 1200.0]) {
    testWidgets(
      'six cards, currency and sequential customer rendering at $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final auth = AuthController()..verify('8200229099', '123456');
        auth.employeeApi = service();
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: PanDetailsScreen(auth: auth),
          ),
        );
        for (final p in profiles) {
          await tester.enterText(
            find.byType(TextField),
            p['panInformation']['panNumber'] as String,
          );
          await tester.tap(find.text('Fetch PAN Details'));
          await tester.pumpAndSettle();
          expect(
            find.text(p['basicInformation']['fullName'] as String),
            findsOneWidget,
          );
          expect(find.text('Simulated Credit Score'), findsOneWidget);
          expect(
            find.text('Employment and Financial Information'),
            findsOneWidget,
          );
          expect(find.text('PAN and KYC Information'), findsOneWidget);
          expect(find.text('Home Loan Information'), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
        expect(
          find.text('No demo home-loan record available for this customer.'),
          findsOneWidget,
        );
        await tester.pumpWidget(const SizedBox());
        auth.logout();
        auth.dispose();
      },
    );
  }
}

