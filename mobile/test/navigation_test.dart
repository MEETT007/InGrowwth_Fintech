import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_finance/app/app_router.dart';
import 'package:home_finance/core/theme/app_theme.dart';
import 'package:home_finance/core/strings/app_strings.dart';
import 'package:home_finance/features/auth/controllers/auth_controller.dart';

void main() {
  for (final size in [const Size(375, 812), const Size(1440, 900)]) {
    testWidgets('five sections preserve inputs at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final auth = AuthController()..verify('9876543210', '123456');
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: AppRouter(auth: auth),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('${S.welcome} Aarav'), findsOneWidget);
      expect(tester.takeException(), isNull);
      Future<void> tab(int index) async {
        if (size.width < 900) {
          await tester.tap(
            find.descendant(
              of: find.byType(NavigationBar),
              matching: find.text(S.shortNav[index]),
            ),
          );
        } else {
          await tester.tap(
            find.descendant(
              of: find.byType(NavigationRail),
              matching: find.text(S.nav[index]),
            ),
          );
        }
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }

      await tab(1);
      expect(find.text(S.loanTitle), findsOneWidget);
      await tab(2);
      expect(find.text(S.protectionTitle), findsOneWidget);
      final field = find.widgetWithText(TextField, S.principalInput);
      await tester.enterText(field, '2500000');
      await tab(3);
      expect(find.text(S.repayHeading), findsOneWidget);
      await tab(4);
      expect(find.text(S.helpTitle), findsOneWidget);
      await tab(2);
      expect(find.text('2500000'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      auth.dispose();
    });
  }
  testWidgets('employee sees PAN destination', (tester) async {
    final auth = AuthController()..verify('8200229099', '123456');
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: AppRouter(auth: auth),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Customer PAN Details'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    await tester.tap(find.byTooltip('Sign out'));
    await tester.pumpAndSettle();
    expect(find.text(S.getOtp), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    auth.dispose();
  });
}
