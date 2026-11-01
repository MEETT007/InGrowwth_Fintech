import 'package:get/get.dart';
import '../controllers/repayment_controller.dart';
import 'package:flutter/material.dart';
import '../../../models/loan_model.dart';
import '../../../models/repayment_plan_model.dart';
import '../../../core/strings/app_strings.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_widgets.dart';

class RepaymentScreen extends StatefulWidget {
  const RepaymentScreen({super.key, required this.loan});
  final LoanModel loan;
  @override
  State<RepaymentScreen> createState() => _RepaymentScreenState();
}

class _RepaymentScreenState extends State<RepaymentScreen> {
  late final RepaymentController controller;
  @override
  void initState() {
    super.initState();
    controller = RepaymentController(widget.loan)..onStart.call();
  }

  @override
  void dispose() {
    controller.onDelete();
    super.dispose();
  }

  TextEditingController get extra => controller.extra;
  TextEditingController get lump => controller.lump;
  TextEditingController get lumpMonth => controller.lumpMonth;
  TextEditingController get increase => controller.increase;
  TextEditingController get income => controller.income;
  TextEditingController get expenses => controller.expenses;
  TextEditingController get reserve => controller.reserve;
  RepaymentPlan? get base => controller.base;
  RepaymentPlan? get shorter => controller.shorter;
  RepaymentPlan? get lower => controller.lower;
  String? get error => controller.error;
  bool get dirty => controller.dirty;
  int get commitment => controller.commitment;
  int get headroom => controller.headroom;
  int get appliedLump => controller.appliedLump;
  double get reserveMonths => controller.reserveMonths;
  void changed() => controller.changed();
  void calculate() => controller.calculate();
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
  Widget build(BuildContext context) => GetBuilder<RepaymentController>(
    init: controller,
    global: false,
    autoRemove: false,
    builder: (_) => buildContent(context),
  );

  Widget buildContent(BuildContext context) => PageBody(
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
