import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_finance/core/theme/app_theme.dart';
import 'package:home_finance/core/strings/app_strings.dart';
import 'package:home_finance/data/mock/mock_loans.dart';
import 'package:home_finance/features/emi_protection/screens/protection_screen.dart';
import 'package:home_finance/features/repayment/screens/repayment_screen.dart';
import 'package:home_finance/features/help_insights/screens/help_screen.dart';

void main() {
  testWidgets('protection comparison and target work on phone', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: ProtectionScreen(loan: mockLoan)),
      ),
    );
    await tester.scrollUntilVisible(
      find.text(S.calculate),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text(S.calculate));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text(S.scenarioExtra),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text(S.scenarioExtra), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text(S.targetButton),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text(S.targetButton));
    await tester.pumpAndSettle();
    expect(find.textContaining(S.required), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('repayment and unknown charges render result states', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: RepaymentScreen(loan: mockLoan)),
      ),
    );
    await tester.scrollUntilVisible(
      find.text(S.calculate),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text(S.calculate));
    await tester.pumpAndSettle();
    expect(find.text(S.strategyTenure), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(child: ChargeAnalyzer(loan: mockLoan)),
        ),
      ),
    );
    await tester.scrollUntilVisible(
      find.text(S.calculate),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text(S.calculate));
    await tester.pumpAndSettle();
    expect(find.text(S.unknown), findsNWidgets(4));
    expect(tester.takeException(), isNull);
  });
}
