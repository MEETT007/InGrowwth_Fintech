import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A quiet, layered backdrop shared by login and every borrower section.
class AppBackdrop extends StatelessWidget {
  const AppBackdrop({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.backdropBlue,
          AppColors.lightBlue,
          AppColors.backdropBlue,
        ],
        stops: [0, .6, 1],
      ),
    ),
    child: child,
  );
}

/// Replays only the visible page entrance, preserving the tab's existing state.
class PageEntrance extends StatefulWidget {
  const PageEntrance({super.key, required this.revision, required this.child});
  final int revision;
  final Widget child;
  @override
  State<PageEntrance> createState() => _PageEntranceState();
}

class _PageEntranceState extends State<PageEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  )..value = 1;
  @override
  void didUpdateWidget(PageEntrance oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.revision != widget.revision &&
        widget.revision >= 0 &&
        !MediaQuery.disableAnimationsOf(context)) {
      controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    child: widget.child,
    builder: (_, child) {
      final value = Curves.easeOutCubic.transform(controller.value);
      return Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 8 * (1 - value)),
          child: child,
        ),
      );
    },
  );
}
