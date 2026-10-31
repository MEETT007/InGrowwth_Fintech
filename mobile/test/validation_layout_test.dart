import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_finance/core/theme/app_theme.dart';
import 'package:home_finance/core/strings/app_strings.dart';
import 'package:home_finance/features/auth/screens/login_screen.dart';
import 'package:home_finance/features/auth/controllers/auth_controller.dart';

void main() {
  testWidgets(
    'long phone validation wraps on narrow mobile at large text size',
    (tester) async {
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final auth = AuthController();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 740),
              textScaler: TextScaler.linear(1.5),
            ),
            child: LoginScreen(auth: auth),
          ),
        ),
      );
      await tester.ensureVisible(find.text(S.getOtp));
      await tester.tap(find.text(S.getOtp));
      await tester.pumpAndSettle();
      final error = find.text(S.invalidMobile);
      expect(error, findsOneWidget);
      expect(tester.widget<Text>(error).maxLines, isNull);
      expect(tester.getSize(error).height, greaterThan(30));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      auth.dispose();
    },
  );
}
