import 'package:flutter/material.dart';
import '../../../models/loan_model.dart';
import '../../../models/repayment_plan_model.dart';
import '../../../core/strings/app_strings.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../services/emi_calculator_service.dart';

class RepaymentScreen extends StatefulWidget {
  const RepaymentScreen({super.key, required this.loan});
  final LoanModel loan;
  @override
  State<RepaymentScreen> createState() => _RepaymentScreenState();
}

class _RepaymentScreenState extends State<RepaymentScreen> {
  final extra = TextEditingController(text: '2000'),
      lump = TextEditingController(text: '50000'),
      lumpMonth = TextEditingController(text: '12'),
      increase = TextEditingController(text: '0'),
      income = TextEditingController(text: '100000'),
      expenses = TextEditingController(text: '45000'),
      reserve = TextEditingController(text: '300000');
  RepaymentPlan? base, shorter, lower;
  String? error;
  bool dirty = true;
  int commitment = 0, headroom = 0, appliedLump = 0;
  double reserveMonths = 0;
  @override
  void dispose() {
    for (final c in [
      extra,
      lump,
      lumpMonth,
      increase,
      income,
      expenses,
      reserve,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void changed() => setState(() => dirty = true);
  void calculate() {
    try {
      final x = parseMoney(extra.text),
          l = parseMoney(lump.text),
          m = int.tryParse(lumpMonth.text),
          v = parseMoney(increase.text),
          i = parseMoney(income.text),
          e = parseMoney(expenses.text),
          r = parseMoney(reserve.text);
      if ([x, l, m, v, i, e, r].any((v) => v == null) || e == 0) {
        throw const FormatException();
      }
      final loan = widget.loan, engine = EmiCalculatorService();
      final emi = engine.emi(loan.balance, loan.rateBps, loan.months);
      final b = engine.schedule(
        principal: loan.balance,
        rateBps: loan.rateBps,
        months: loan.months,
      );
      RepaymentPlan plan(AdjustmentPolicy policy) => engine.schedule(
        principal: loan.balance,
        rateBps: loan.rateBps,
        months: loan.months,
        payment: emi + v!,
        monthlyExtra: x!,
        lump: l!,
        lumpMonth: m!,
        policy: policy,
      );
      final a = plan(AdjustmentPolicy.tenure), c = plan(AdjustmentPolicy.emi);
      setState(() {
        base = b;
        shorter = a;
        lower = c;
        commitment = emi + v! + x!;
        appliedLump = l!;
        headroom = i! - e!;
        reserveMonths = r! / e;
        dirty = false;
        error = null;
      });
    } on FormatException {
      setState(() => error = S.invalid);
    } on StateError {
      setState(() => error = S.noAmortization);
    }
  }

  Widget comparison(String title, RepaymentPlan p) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(title),
        Metric(
          S.savings,
          currency(base!.interest - p.interest),
          positive: true,
        ),
        const SizedBox(height: 20),
        Metric(S.totalInterest, currency(p.interest)),
        const SizedBox(height: 20),
        Metric(S.monthsSaved, '${base!.months - p.months}'),
        const SizedBox(height: 20),
        Metric(
          S.debtFree,
          displayDate(monthAfter(widget.loan.nextDue, p.months - 1)),
        ),
        const SizedBox(height: 20),
        Metric(S.laterEmi, currency(p.rows.length > 1 ? p.rows[1].emi : 0)),
      ],
    ),
  );
  @override
  Widget build(BuildContext context) => PageBody(
    title: S.repayHeading,
    subtitle: S.repaySubtitle,
    children: [
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdaptiveGrid(
              minWidth: 280,
              children: [
                NumberField(S.monthlyExtra, extra, onChanged: changed),
                NumberField(S.lump, lump, onChanged: changed),
                NumberField(
                  S.lumpMonth,
                  lumpMonth,
                  onChanged: changed,
                  integer: true,
                ),
                NumberField(S.increase, increase, onChanged: changed),
                NumberField(S.income, income, onChanged: changed),
                NumberField(S.expenses, expenses, onChanged: changed),
                NumberField(S.emergency, reserve, onChanged: changed),
              ],
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: calculate, child: const Text(S.calculate)),
            if (error != null) InfoNote(error!, error: true),
          ],
        ),
      ),
      if (base != null) ...[
        if (dirty) const InfoNote(S.stale),
        AdaptiveGrid(
          minWidth: 320,
          children: [
            comparison(S.strategyTenure, shorter!),
            comparison(S.strategyEmi, lower!),
          ],
        ),
        AppCard(
          highlight: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle(S.affordability),
              Metric(S.commitment, currency(commitment)),
              const SizedBox(height: 16),
              InfoNote(
                commitment <= headroom ? S.affordable : S.notAffordable,
                error: commitment > headroom,
              ),
              const SizedBox(height: 12),
              InfoNote(
                '${S.reserveNote} ${reserveMonths.toStringAsFixed(1)} ${S.reserveSuffix}',
              ),
              InfoNote('${S.lump}: ${currency(appliedLump)}'),
            ],
          ),
        ),
      ],
      const AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionTitle(S.assumptions),
            InfoNote(S.repaymentAssumptions),
          ],
        ),
      ),
    ],
  );
}
