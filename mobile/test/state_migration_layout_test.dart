import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_finance/app/app_router.dart';
import 'package:home_finance/core/theme/app_theme.dart';
import 'package:home_finance/features/auth/controllers/auth_controller.dart';

void main() {
  for (final width in [390.0, 1280.0]) {
    testWidgets('state migration preserves layout at $width', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final auth = AuthController();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: RepaintBoundary(
            key: const ValueKey('screen'),
            child: AppRouter(auth: auth),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byKey(const ValueKey('screen')),
        matchesGoldenFile('goldens/login-${width.toInt()}.png'),
      );
      auth.verify('9876543210', '123456');
      await tester.pumpAndSettle();
      await expectLater(
        find.byKey(const ValueKey('screen')),
        matchesGoldenFile('goldens/home-${width.toInt()}.png'),
      );
      await tester.pumpWidget(const SizedBox());
      auth.onDelete();
    });
  }
}
