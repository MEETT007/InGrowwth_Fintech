import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_text_styles.dart';

class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.highlight = false});
  final Widget child;
  final bool highlight;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppDimensions.radius),
      border: Border.all(
        color: highlight
            ? AppColors.sky.withValues(alpha: .35)
            : AppColors.border,
      ),
      boxShadow: const [
        BoxShadow(
          color: AppColors.shadow,
          blurRadius: 28,
          offset: Offset(0, 8),
        ),
      ],
    ),
    padding: const EdgeInsets.all(AppDimensions.md),
    child: child,
  );
}

class PageBody extends StatelessWidget {
  const PageBody({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
  });
  final String title, subtitle;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppDimensions.maxWidth),
        child: Padding(
          padding: EdgeInsets.all(
            MediaQuery.sizeOf(context).width < 600 ? 20 : 32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.responsive(context, AppTextStyles.heading),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: AppTextStyles.responsive(context, AppTextStyles.caption),
              ),
              const SizedBox(height: 28),
              ...children.expand((w) => [w, const SizedBox(height: 20)]),
            ],
          ),
        ),
      ),
    ),
  );
}

class Metric extends StatelessWidget {
  const Metric(this.label, this.value, {super.key, this.positive = false});
  final String label, value;
  final bool positive;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: AppTextStyles.responsive(context, AppTextStyles.caption),
      ),
      const SizedBox(height: 6),
      Text(
        value,
        style: AppTextStyles.responsive(
          context,
          AppTextStyles.metric,
        ).copyWith(color: positive ? AppColors.success : null),
      ),
    ],
  );
}

class AdaptiveGrid extends StatelessWidget {
  const AdaptiveGrid({super.key, required this.children, this.minWidth = 240});
  final List<Widget> children;
  final double minWidth;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final count = (c.maxWidth / minWidth).floor().clamp(1, children.length);
      final width = (c.maxWidth - 16 * (count - 1)) / count;
      return Wrap(
        spacing: 16,
        runSpacing: 20,
        children: children
            .map((w) => SizedBox(width: width, child: w))
            .toList(),
      );
    },
  );
}

class NumberField extends StatelessWidget {
  const NumberField(
    this.label,
    this.controller, {
    super.key,
    this.onChanged,
    this.integer = false,
  });
  final String label;
  final TextEditingController controller;
  final VoidCallback? onChanged;
  final bool integer;
  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    keyboardType: TextInputType.numberWithOptions(decimal: !integer),
    onChanged: (_) => onChanged?.call(),
    decoration: InputDecoration(labelText: label),
  );
}

class InfoNote extends StatelessWidget {
  const InfoNote(this.text, {super.key, this.error = false});
  final String text;
  final bool error;
  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Text(
      text,
      style: AppTextStyles.responsive(
        context,
        AppTextStyles.caption,
      ).copyWith(color: error ? AppColors.error : AppColors.secondary),
    ),
  );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Text(
      text,
      style: AppTextStyles.responsive(context, AppTextStyles.title),
    ),
  );
}

class BreakdownBar extends StatelessWidget {
  const BreakdownBar({
    super.key,
    required this.principal,
    required this.interest,
  });
  final int principal, interest;
  @override
  Widget build(BuildContext context) {
    final total = principal + interest;
    return Semantics(
      label: '${principal / 100} / ${interest / 100}',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          height: 14,
          child: Row(
            children: [
              Expanded(
                flex: total == 0 ? 1 : principal.clamp(1, total),
                child: Container(color: AppColors.sky),
              ),
              Expanded(
                flex: total == 0 ? 1 : interest.clamp(1, total),
                child: Container(color: AppColors.deepBlue),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
