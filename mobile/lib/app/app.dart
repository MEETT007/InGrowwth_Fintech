import 'package:get/get.dart';
import 'shell_controller.dart';
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
  final auth = AuthController()..onStart.call();
  final controller = AppController()..onStart.call();
  @override
  void dispose() {
    auth.onDelete();
    controller.onDelete();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GetBuilder<AppController>(
    init: controller,
    global: false,
    autoRemove: false,
    builder: (_) => buildContent(context),
  );

  Widget buildContent(BuildContext context) => MaterialApp(
    title: S.brand,
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    home: controller.ready
        ? AppRouter(auth: auth)
        : SplashScreen(onComplete: controller.finishSplash),
  );
}
