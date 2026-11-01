import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_finance/app/app.dart';
import 'package:home_finance/core/strings/app_strings.dart';
import 'package:home_finance/core/theme/app_theme.dart';
import 'package:home_finance/features/auth/screens/login_screen.dart';
import 'package:home_finance/features/auth/controllers/auth_controller.dart';

void main() {
  testWidgets('splash transitions to mobile login', (tester) async {
    await tester.pumpWidget(const HomeEaseApp());
    expect(find.text(S.brand), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text(S.getOtp), findsOneWidget);
  });
  testWidgets('mobile validation and OTP error then borrower navigation', (
    tester,
  ) async {
    final auth = AuthController();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: LoginScreen(auth: auth),
      ),
    );
    await tester.tap(find.text(S.getOtp));
    await tester.pumpAndSettle();
    expect(find.text(S.invalidMobile), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, S.mobile), '9876543210');
    await tester.tap(find.text(S.getOtp));
    await tester.pumpAndSettle();
    expect(find.text(S.verifyTitle), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, '000000');
    await tester.tap(find.text(S.verify));
    await tester.pumpAndSettle();
    expect(find.text(S.invalidOtp), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, '123456');
    await tester.tap(find.text(S.verify));
    await tester.pumpAndSettle();
    expect(auth.user!.isSpecial, isFalse);
    await tester.pumpWidget(const SizedBox());
    auth.onDelete();
  });
  test('primary action and secondary text have accessible contrast', () {
    final c = AppTheme.light.colorScheme;
    double contrast(Color a, Color b) {
      final x = a.computeLuminance(), y = b.computeLuminance();
      return ((x > y ? x : y) + .05) / ((x > y ? y : x) + .05);
    }

    expect(contrast(c.onPrimary, c.primary), greaterThanOrEqualTo(4.5));
    expect(contrast(c.onSurfaceVariant, c.surface), greaterThanOrEqualTo(4.5));
  });
}

