import 'package:flutter/material.dart';
import '../core/strings/app_strings.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/controllers/auth_controller.dart';
import '../features/splash/screens/splash_screen.dart';
import 'app_router.dart';

class HomeEaseApp extends StatefulWidget {
  const HomeEaseApp({super.key});
  @override
  State<HomeEaseApp> createState() => _HomeEaseAppState();
}

class _HomeEaseAppState extends State<HomeEaseApp> {
  final auth = AuthController();
  bool ready = false;
  @override
  void dispose() {
    auth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: S.brand,
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    home: ready
        ? AppRouter(auth: auth)
        : SplashScreen(onComplete: () => setState(() => ready = true)),
  );
}
