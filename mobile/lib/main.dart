import 'package:flutter/material.dart';
import 'app/app.dart';
export 'legacy/legacy_app.dart' show HomeFinanceApp, Planner, financeTheme;
export 'app/app.dart' show HomeEaseApp;

void main() => runApp(const HomeEaseApp());
