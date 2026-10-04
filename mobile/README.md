# InGrowwth Home Finance mobile

Flutter companion to the Java/Next.js project in the parent directory. Android and iOS runner projects are included. See the parent README for the complete product, accounts, database and integration boundaries.

From this directory:

```sh
flutter pub get
flutter analyze
flutter test
# iOS simulator (requires Xcode and simulator SDK)
flutter run --dart-define=API_URL=http://127.0.0.1:8080
# Android emulator (requires Android SDK)
flutter run --dart-define=API_URL=http://10.0.2.2:8080
# Hosted HTTPS deployment
flutter run --dart-define=API_URL=https://your-home-finance-host.example
```

Shared borrower sign-in, live loan tracking, clarifications, pre-EMI/EMI/principal requests, cancellation, closure status, and repayment comparisons are implemented. Application creation and private document uploads/downloads use the web portal. The mobile app stores session cookies only in memory and requires sign-in again when reopened. Staff should use the web review workspace.

The Dart transport smoke test connects to the actual Java service:

```sh
dart run tool/api_smoke.dart
```

The Flutter widget suite covers a small phone, landscape at 200% text size with reduced motion, light/dark contrast, input reachability, calculation and stale-result disclosure. Native release builds have not been verified on this machine; its platform SDKs are unavailable.
