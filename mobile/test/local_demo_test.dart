import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_finance/main.dart';
import 'package:home_finance/api.dart';

void main() {
  testWidgets('opens demo without credentials or backend', (tester) async {
    await tester.pumpWidget(const HomeFinanceApp());
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
    await tester.tap(find.text('Open local demo'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome, Demo borrower'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  test(
    'local planner conserves zero-rate repayment and rewards extras',
    () async {
      final api = BankingApi();
      final p = <String, dynamic>{
        'principal': 120000,
        'annualRate': 0,
        'months': 12,
        'extraMonthly': 10000,
        'annualExtra': 0,
        'oneTime': 0,
        'oneTimeMonth': 0,
        'prepayMode': 'TENURE',
        'startDate': '2026-11-05',
      };
      final result = await api.request('planner', p);
      expect(result['baseline']['months'], 12);
      expect(result['planned']['months'], 6);
      expect(result['planned']['interest'], 0);
      expect(result['planned']['rows'].last['closing'], 0);
      api.dispose();
    },
  );
}
