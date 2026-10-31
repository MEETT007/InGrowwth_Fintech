import 'package:flutter/material.dart';
import '../../../models/loan_model.dart';
import '../../../core/strings/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../services/emi_calculator_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.loan,
    required this.name,
    required this.onNavigate,
  });
  final LoanModel loan;
  final String name;
  final ValueChanged<int> onNavigate;
  @override
  Widget build(BuildContext context) {
    final emi = EmiCalculatorService().emi(
      loan.balance,
      loan.rateBps,
      loan.months,
    );
    final progress = loan.principalPaid / loan.original;
    return PageBody(
      title: '${S.welcome} $name',
      subtitle: S.homeBody,
      children: [
        AppCard(
          highlight: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                S.homeTitle,
                style: AppTextStyles.responsive(context, AppTextStyles.title),
              ),
              const SizedBox(height: 24),
              Text(
                S.balance,
                style: AppTextStyles.responsive(context, AppTextStyles.caption),
              ),
              Text(
                currency(loan.balance),
                style: AppTextStyles.responsive(context, AppTextStyles.amount),
              ),
              const SizedBox(height: 28),
              AdaptiveGrid(
                minWidth: 180,
                children: [
                  Metric(S.emi, currency(emi)),
                  Metric(S.rate, '${loan.rateBps / 100}%'),
                  Metric(S.nextDue, displayDate(loan.nextDue)),
                  Metric(S.remaining, S.years(loan.months)),
                ],
              ),
            ],
          ),
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle(S.progress),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress),
                duration: Duration(
                  milliseconds: MediaQuery.disableAnimationsOf(context)
                      ? 0
                      : 650,
                ),
                builder: (_, v, _) => LinearProgressIndicator(
                  value: v,
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${(progress * 100).toStringAsFixed(1)}% ${S.paidOff}',
                style: AppTextStyles.responsive(context, AppTextStyles.caption),
              ),
              const SizedBox(height: 24),
              AdaptiveGrid(
                children: [
                  Metric(S.principalRepaid, currency(loan.principalPaid)),
                  Metric(S.totalPaid, currency(loan.totalPaid)),
                ],
              ),
            ],
          ),
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.shield_outlined,
                color: AppColors.deepBlue,
                size: 32,
              ),
              const SizedBox(height: 16),
              const SectionTitle(S.protectTitle),
              Text(S.protectBody),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => onNavigate(2),
                icon: const Icon(Icons.arrow_forward),
                label: Text(S.explore),
              ),
            ],
          ),
        ),
        AdaptiveGrid(
          minWidth: 330,
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle(S.repayTitle),
                  Text(S.repayBody),
                  TextButton(
                    onPressed: () => onNavigate(3),
                    child: Text(S.open),
                  ),
                ],
              ),
            ),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle(S.missed),
                  Text(S.missedBody),
                  TextButton(
                    onPressed: () => onNavigate(4),
                    child: Text(S.open),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
