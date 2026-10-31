import '../../../data/mock/mock_payments.dart';
import '../../../data/mock/mock_interest_rates.dart';
import 'package:flutter/material.dart';
import '../../../models/loan_model.dart';
import '../../../core/strings/app_strings.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../services/emi_calculator_service.dart';

class MyLoanScreen extends StatefulWidget {
  const MyLoanScreen({super.key, required this.loan});
  final LoanModel loan;
  @override
  State<MyLoanScreen> createState() => _MyLoanScreenState();
}

class _MyLoanScreenState extends State<MyLoanScreen> {
  int page = 0, selected = 0;
  @override
  Widget build(BuildContext context) {
    final l = widget.loan, engine = EmiCalculatorService();
    final plan = engine.schedule(
      principal: l.balance,
      rateBps: l.rateBps,
      months: l.months,
    );
    final first = plan.rows.first, row = plan.rows[selected];
    return PageBody(
      title: S.loanTitle,
      subtitle: S.loanBody,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle(S.overview),
              AdaptiveGrid(
                children: [
                  Metric(S.lender, l.lender),
                  Metric(S.nickname, l.nickname),
                  Metric(S.sanctioned, currency(l.original)),
                  Metric(S.disbursed, currency(l.original)),
                  Metric(S.balance, currency(l.balance)),
                  Metric(S.rate, '${l.rateBps / 100}%'),
                  const Metric(S.rateType, S.floating),
                  Metric(S.emi, currency(first.emi)),
                  Metric(S.remaining, S.years(l.months)),
                  Metric(S.started, displayDate(l.start)),
                  Metric(S.nextDue, displayDate(l.nextDue)),
                ],
              ),
            ],
          ),
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle(S.breakdown),
              BreakdownBar(
                principal: first.principal,
                interest: first.interest,
              ),
              const SizedBox(height: 20),
              AdaptiveGrid(
                children: [
                  Metric(S.principal, currency(first.principal)),
                  Metric(S.interest, currency(first.interest)),
                ],
              ),
              const SizedBox(height: 16),
              const InfoNote(S.breakdownBody),
            ],
          ),
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle(S.schedule),
              const InfoNote(S.scheduleBody),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  showCheckboxColumn: false,
                  columns: [
                    S.month,
                    S.opening,
                    S.emi,
                    S.interest,
                    S.principal,
                    S.closing,
                  ].map((s) => DataColumn(label: Text(s))).toList(),
                  rows: plan.rows
                      .skip(page * 12)
                      .take(12)
                      .map(
                        (r) => DataRow(
                          selected: r.month == selected + 1,
                          onSelectChanged: (_) =>
                              setState(() => selected = r.month - 1),
                          cells: [
                            S.monthNumber(r.month),
                            currency(r.opening),
                            currency(r.emi),
                            currency(r.interest),
                            currency(r.principal),
                            currency(r.closing),
                          ].map((s) => DataCell(Text(s))).toList(),
                        ),
                      )
                      .toList(),
                ),
              ),
              Wrap(
                spacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  TextButton(
                    onPressed: page == 0 ? null : () => setState(() => page--),
                    child: Text(S.previous),
                  ),
                  Text('${page + 1} / ${(plan.months / 12).ceil()}'),
                  TextButton(
                    onPressed: (page + 1) * 12 >= plan.months
                        ? null
                        : () => setState(() => page++),
                    child: Text(S.next),
                  ),
                ],
              ),
              Text(
                '${S.selectedMonth}: ${row.month}',
                style: AppTextStyles.responsive(context, AppTextStyles.title),
              ),
              const SizedBox(height: 12),
              BreakdownBar(principal: row.principal, interest: row.interest),
              const SizedBox(height: 12),
              Text(
                '${S.principal}: ${currency(row.principal)} · ${S.interest}: ${currency(row.interest)}',
              ),
            ],
          ),
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle(S.history),
              const InfoNote(S.sample),
              for (final payment in mockPayments(l.nextDue, first.emi))
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.check_circle_outline),
                  title: Text(displayDate(payment.date)),
                  subtitle: Text(payment.late ? S.delayed : S.paid),
                  trailing: Text(currency(payment.amount)),
                ),
            ],
          ),
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle(S.rateHistory),
              const InfoNote(S.sample),
              for (final item in mockInterestRates)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.timeline),
                  title: Text(displayDate(item.$1)),
                  trailing: Text('${item.$2 / 100}%'),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
