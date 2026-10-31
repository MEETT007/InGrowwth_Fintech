import 'package:flutter/material.dart';
import 'app/app.dart';
// Historical demo remains available for migration reference and regression tests.
export 'legacy/legacy_app.dart' show HomeFinanceApp, Planner, financeTheme;
export 'app/app.dart' show HomeEaseApp;

void main() => runApp(const HomeEaseApp());
