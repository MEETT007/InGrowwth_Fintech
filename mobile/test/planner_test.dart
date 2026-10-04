import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_finance/main.dart';
import 'package:home_finance/api.dart';

class OfflineApi extends BankingApi {
  Map<String, dynamic>? payload;
  @override
  Future<dynamic> request(String path, [Map<String, dynamic>? body]) async {
    payload = body;
    return {
      'interestSaved': 250000,
      'monthsSaved': 24,
      'planned': {'payoffDate': '2044-10-05', 'interest': 1500000, 'rows': []},
      'baseline': {'interest': 1750000},
      'assumptions': ['Monthly interest with unchanged rate.'],
    };
  }
}

void main() {
  testWidgets(
    'small-screen planner keeps fields reachable and marks stale results',
    (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final api = OfflineApi();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: Planner(api: api)),
        ),
      );
      expect(find.text('Outstanding principal (₹)'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Compare repayment'),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(FilledButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      expect(api.payload!['principal'], 4500000);
      await tester.scrollUntilVisible(
        find.text('Estimated interest saved'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('₹2,50,000'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Outstanding principal (₹)'),
        -400,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '4000000');
      await tester.scrollUntilVisible(
        find.text(
          'Inputs changed. Update the comparison to refresh these results.',
        ),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.text(
          'Inputs changed. Update the comparison to refresh these results.',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  for (final brightness in [Brightness.light, Brightness.dark]) {
    test('normal text and button contrast meet 4.5:1 in $brightness', () {
      final c = financeTheme(brightness).colorScheme;
      double contrast(Color a, Color b) {
        final x = a.computeLuminance(), y = b.computeLuminance();
        return ((x > y ? x : y) + .05) / ((x > y ? y : x) + .05);
      }

      expect(contrast(c.onSurface, c.surface), greaterThanOrEqualTo(4.5));
      expect(
        contrast(c.onSurfaceVariant, c.surface),
        greaterThanOrEqualTo(4.5),
      );
      expect(contrast(c.onPrimary, c.primary), greaterThanOrEqualTo(4.5));
    });
    testWidgets('landscape with large text and reduced motion in $brightness', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(812, 375);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: financeTheme(brightness),
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(812, 375),
              textScaler: TextScaler.linear(2),
              disableAnimations: true,
            ),
            child: Scaffold(body: Planner(api: OfflineApi())),
          ),
        ),
      );
      await tester.scrollUntilVisible(
        find.byType(FilledButton),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(FilledButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Estimated interest saved'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('₹2,50,000'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
