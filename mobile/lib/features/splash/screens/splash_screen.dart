import 'package:flutter/material.dart';
import '../../../core/strings/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onComplete});
  final VoidCallback onComplete;
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 850), () {
      if (mounted) widget.onComplete();
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(
          milliseconds: MediaQuery.disableAnimationsOf(context) ? 0 : 450,
        ),
        builder: (_, value, child) => Opacity(opacity: value, child: child),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.home_rounded, size: 72, color: AppColors.deepBlue),
            SizedBox(height: 20),
            Text(
              S.brand,
              style: AppTextStyles.responsive(context, AppTextStyles.heading),
            ),
            SizedBox(height: 8),
            Text(
              S.tagline,
              style: AppTextStyles.responsive(context, AppTextStyles.caption),
            ),
            SizedBox(height: 28),
            SizedBox(width: 100, child: LinearProgressIndicator()),
          ],
        ),
      ),
    ),
  );
}
