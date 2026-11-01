# HomeEase AI

Standalone Flutter home-loan planning app for Chrome and Android. No banking, authentication, SMS, payment or Java service is called.

## Run

From mobile:

```sh
flutter pub get
flutter run -d chrome -t lib/main.dart
flutter run -d emulator-5554 -t lib/main.dart
flutter build web
flutter analyze
flutter test
```

Use any valid Indian mobile number (10 digits, beginning with 6–9) and demo OTP **123456**. Number **8200229099** opens an isolated pending destination; its business flow is intentionally unspecified. No SMS is delivered. Login and calculator state are in memory. Sign out ends the session; Reset demo clears borrower inputs after confirmation.

## App icon

Android and iOS launcher icons use `assets/branding/homeease-ai-icon-blue-glass-transparent-v3.png` on a pure white background (`#FFFFFF`). The source artwork and Android adaptive foreground remain transparent, with safe padding for launcher masks. iOS icons are opaque.

To regenerate all native sizes on Windows, run `./scripts/generate-app-icons.ps1` from `mobile`. Rebuild and reinstall the app to see icon changes; hot reload does not update launcher resources.

## Source layout

- `lib/app`: app entry and responsive navigation; an IndexedStack preserves each tab's input state.
- `lib/core/theme`: centralized sky-blue/white palette, typography, spacing and light theme. Secondary text and semantic status colors use darker accessible variants of the suggested palette.
- `lib/core/strings`: centralized visible product text.
- `lib/core/widgets`: shared fields, cards, metrics, grids and breakdown bars.
- `lib/features`: splash, local OTP authentication, dashboard, My Loan, EMI Protection, repayment and Help & Insights.
- `lib/models`, `lib/data`: typed loan/user/payment data and fictional repositories.
- `lib/services`: independent financial engines; integer paise, integer basis-point rates, monthly half-up interest rounding.
- `lib/legacy`: preserved previous demo for historical regression tests; not used by the HomeEase entry point. The compatibility api.dart export has no network implementation.

Related small features share string/widget files instead of empty per-feature boilerplate. GetX (`get` 4.7.3) manages the active application's state using `GetxController` and `GetBuilder`: authentication, splash readiness, selected tab, login/OTP forms, employee PAN lookup, loan-table selection, EMI protection, repayment planning and charge analysis. Calculation inputs/results live in dedicated feature controllers. Controllers are scoped to their owning widget and closed on disposal, avoiding shared state between sessions or dialogs. `IndexedStack` still preserves each tab's inputs. Flutter widget lifecycle remains responsible for animations, menu anchors and the splash timer; the historical legacy demo remains unchanged. MaterialApp, navigation, theme, visual widgets, APIs and financial services are preserved.

## Calculation assumptions

EMI is the smallest paise payment that repays the balance in the selected number of monthly cycles. Interest uses monthly reducing balance. Prepayments follow the scheduled payment; one-time contributions post in the chosen month. The final payment is capped to the amount owed. Rate reset happens before the selected month's payment. Choose whether EMI or tenure adjusts; the tool never guarantees unchanged EMI. Protection contributions stop at reset. With the maintain-tenure policy, the scheduled EMI also recalculates after each prepayment. Cash-reserve comparisons assume no returns and no principal reduction.

Target EMI uses a bounded binary search over monthly contributions before reset. This is a model estimate, not an affordability recommendation. Repayment planning shows entered income, expenses, reserve coverage and a separate lump sum. Rates, taxes, lender rules and fees must be confirmed independently.

The charge analyzer leaves unknown fees unknown. Its subtotal excludes unknowns. Entered tax applies only to entered return and flat penal fees, while overdue interest is simple amount × annual rate × days/365. Users must verify contract terms and tax basis. Waiver text is editable and can be copied; nothing is submitted.

Loan Freedom Score is only the share of original principal repaid, labelled as internal guidance, not a credit score. All customer/lender/payment/rate history records are fictional.

Web rendering assets are served locally using web/flutter_bootstrap.js; no external fonts or business-service calls are required. Initial package/tool downloads require connectivity. Native iOS runner remains present, but this Windows environment cannot validate iOS builds.
