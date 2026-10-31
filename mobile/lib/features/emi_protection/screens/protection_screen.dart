import '../../../core/widgets/app_dropdown.dart';
import 'package:flutter/material.dart';
import '../../../models/loan_model.dart';
import '../../../models/repayment_plan_model.dart';
import '../../../core/constants/demo_config.dart';
import '../../../core/strings/app_strings.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../services/emi_calculator_service.dart';
import '../../../services/emi_protection_service.dart';

class ProtectionScreen extends StatefulWidget {
  const ProtectionScreen({super.key, required this.loan});
  final LoanModel loan;
  @override
  State<ProtectionScreen> createState() => _ProtectionScreenState();
}

class _ProtectionScreenState extends State<ProtectionScreen> {
  late final TextEditingController balance,
      rate,
      months,
      emi,
      future,
      extra,
      target;
  late DateTime reset;
  final service = EmiProtectionService();
  AdjustmentPolicy policy = AdjustmentPolicy.emi;
  ProtectionResult? result;
  String? error, targetMessage;
  bool dirty = true;
  @override
  void initState() {
    super.initState();
    final l = widget.loan;
    balance = TextEditingController(text: '${l.balance ~/ 100}');
    rate = TextEditingController(text: '${l.rateBps / 100}');
    months = TextEditingController(text: '${l.months}');
    emi = TextEditingController(
      text: (EmiCalculatorService().emi(l.balance, l.rateBps, l.months) / 100)
          .toStringAsFixed(2),
    );
    future = TextEditingController(text: '9');
    extra = TextEditingController(text: '2000');
    target = TextEditingController(text: emi.text);
    reset = monthAfter(l.nextDue, 12);
  }

  @override
  void dispose() {
    for (final c in [balance, rate, months, emi, future, extra, target]) {
      c.dispose();
    }
    super.dispose();
  }

  void changed() => setState(() {
    dirty = true;
    targetMessage = null;
  });
  ({
    int balance,
    int rate,
    int months,
    int emi,
    int future,
    int extra,
    int reset,
  })
  read() {
    final b = parseMoney(balance.text),
        r = parseMoney(rate.text),
        n = int.tryParse(months.text),
        e = parseMoney(emi.text),
        f = parseMoney(future.text),
        x = parseMoney(extra.text);
    if (b == null ||
        b < 100000 ||
        r == null ||
        n == null ||
        e == null ||
        f == null ||
        x == null) {
      throw const FormatException();
    }
    final first = widget.loan.nextDue;
    final resetMonth =
        (reset.year - first.year) * 12 + reset.month - first.month + 1;
    if (resetMonth < 2 || resetMonth > n) throw ArgumentError(S.resetInvalid);
    return (
      balance: b,
      rate: r,
      months: n,
      emi: e,
      future: f,
      extra: x,
      reset: resetMonth,
    );
  }

  void calculate({bool findTarget = false}) {
    try {
      final p = read();
      final next = service.compare(
        balance: p.balance,
        rate: p.rate,
        months: p.months,
        currentEmi: p.emi,
        futureRate: p.future,
        resetMonth: p.reset,
        extra: p.extra,
        policy: policy,
      );
      String? message;
      if (findTarget) {
        final limit = parseMoney(target.text);
        if (limit == null) throw const FormatException();
        final contribution = service.targetContribution(
          balance: p.balance,
          rate: p.rate,
          months: p.months,
          currentEmi: p.emi,
          futureRate: p.future,
          resetMonth: p.reset,
          target: limit,
          policy: policy,
        );
        message = contribution == null
            ? S.targetImpossible
            : contribution == 0
            ? S.targetAlready
            : '${S.required}: ${currency(contribution, decimals: true)}';
      }
      setState(() {
        result = next;
        error = null;
        dirty = false;
        targetMessage = message;
      });
    } on FormatException {
      setState(() => error = S.invalid);
    } on ArgumentError catch (e) {
      setState(() => error = e.message.toString());
    } on StateError {
      setState(() => error = S.noAmortization);
    }
  }

  Widget scenario(
    String title,
    RepaymentPlan plan, {
    bool reserve = false,
    bool highlight = false,
  }) {
    final r = result!;
    return AppCard(
      highlight: highlight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(title),
          Metric(S.futureEmi, currency(r.futureEmi(plan))),
          const Divider(),
          Metric(S.atReset, currency(r.atReset(plan))),
          const SizedBox(height: 16),
          Metric(
            S.remaining,
            S.monthsCount((plan.months - r.resetMonth + 1).clamp(0, 1200)),
          ),
          const SizedBox(height: 16),
          Metric(S.totalInterest, currency(plan.interest)),
          const SizedBox(height: 16),
          Metric(
            reserve ? S.reserve : S.additional,
            currency(reserve ? r.reserveCash : plan.extras),
          ),
          const SizedBox(height: 16),
          Metric(
            S.savings,
            currency(r.baseline.interest - plan.interest),
            positive: true,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => PageBody(
    title: S.protectionTitle,
    subtitle: S.protectionBody,
    children: [
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(S.inputs),
            AdaptiveGrid(
              minWidth: 280,
              children: [
                NumberField(S.principalInput, balance, onChanged: changed),
                NumberField(S.rateInput, rate, onChanged: changed),
                NumberField(
                  S.monthsInput,
                  months,
                  onChanged: changed,
                  integer: true,
                ),
                NumberField(S.emiInput, emi, onChanged: changed),
                NumberField(S.futureRate, future, onChanged: changed),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: DemoConfig.futureRates
                  .map(
                    (v) => ChoiceChip(
                      label: Text('$v%'),
                      selected: double.tryParse(future.text) == v,
                      onSelected: (_) {
                        future.text = '$v';
                        changed();
                      },
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              icon: const Icon(Icons.calendar_month_outlined),
              label: Text('${S.resetDate}: ${displayDate(reset)}'),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: reset,
                  firstDate: monthAfter(widget.loan.nextDue, 1),
                  lastDate: monthAfter(widget.loan.nextDue, 359),
                );
                if (picked != null && mounted) {
                  setState(() => reset = picked);
                  changed();
                }
              },
            ),
            const SizedBox(height: 20),
            AppDropdown<AdjustmentPolicy>(
              value: policy,
              label: S.policy,
              options: const {
                AdjustmentPolicy.emi: S.policyEmi,
                AdjustmentPolicy.tenure: S.policyTenure,
              },
              onChanged: (value) {
                policy = value;
                changed();
              },
            ),
            const SizedBox(height: 20),
            NumberField(S.extra, extra, onChanged: changed),
            Slider(
              value: (double.tryParse(extra.text) ?? 0).clamp(0, 10000),
              max: 10000,
              divisions: 100,
              label: currency(
                ((double.tryParse(extra.text) ?? 0) * 100).round(),
              ),
              onChanged: (v) {
                extra.text = v.round().toString();
                changed();
              },
            ),
            Wrap(
              spacing: 8,
              children: DemoConfig.contributions
                  .map(
                    (v) => ChoiceChip(
                      label: Text(currency(v * 100)),
                      selected: int.tryParse(extra.text) == v,
                      onSelected: (_) {
                        extra.text = '$v';
                        changed();
                      },
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => calculate(),
              icon: const Icon(Icons.shield_outlined),
              label: Text(S.calculate),
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: InfoNote(error!, error: true),
              ),
          ],
        ),
      ),
      if (result != null) ...[
        if (dirty) const InfoNote(S.stale),
        AdaptiveGrid(
          minWidth: 290,
          children: [
            scenario(S.scenarioBase, result!.baseline),
            scenario(S.scenarioExtra, result!.prepay, highlight: true),
            scenario(S.scenarioReserve, result!.reserve, reserve: true),
          ],
        ),
      ],
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(S.target),
            Text(S.targetBody),
            const SizedBox(height: 20),
            NumberField(
              S.targetEmi,
              target,
              onChanged: () => setState(() => targetMessage = null),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => calculate(findTarget: true),
              child: Text(S.targetButton),
            ),
            if (targetMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  targetMessage!,
                  style: AppTextStyles.responsive(context, AppTextStyles.title),
                ),
              ),
            const SizedBox(height: 12),
            const InfoNote(S.targetLimit),
          ],
        ),
      ),
      const AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [SectionTitle(S.assumptions), InfoNote(S.assumptionsBody)],
        ),
      ),
      AppCard(
        child: Column(
          children: [
            for (var i = 0; i < S.educationItems.length; i++)
              ExpansionTile(
                title: Text(S.educationItems[i]),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(S.educationAnswers[i]),
                  ),
                ],
              ),
          ],
        ),
      ),
    ],
  );
}
