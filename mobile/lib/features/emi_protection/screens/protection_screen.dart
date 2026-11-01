import 'package:get/get.dart';
import '../controllers/protection_controller.dart';
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
import '../../../services/emi_protection_service.dart';

class ProtectionScreen extends StatefulWidget {
  const ProtectionScreen({super.key, required this.loan});
  final LoanModel loan;
  @override
  State<ProtectionScreen> createState() => _ProtectionScreenState();
}

class _ProtectionScreenState extends State<ProtectionScreen> {
  late final ProtectionController controller;
  @override
  void initState() {
    super.initState();
    controller = ProtectionController(widget.loan)..onStart.call();
  }

  @override
  void dispose() {
    controller.onDelete();
    super.dispose();
  }

  TextEditingController get balance => controller.balance;
  TextEditingController get rate => controller.rate;
  TextEditingController get months => controller.months;
  TextEditingController get emi => controller.emi;
  TextEditingController get future => controller.future;
  TextEditingController get extra => controller.extra;
  TextEditingController get target => controller.target;
  DateTime get reset => controller.reset;
  set reset(DateTime value) => controller.reset = value;
  AdjustmentPolicy get policy => controller.policy;
  set policy(AdjustmentPolicy value) => controller.policy = value;
  ProtectionResult? get result => controller.result;
  String? get error => controller.error;
  String? get targetMessage => controller.targetMessage;
  set targetMessage(String? value) => controller.targetMessage = value;
  bool get dirty => controller.dirty;
  void changed() => controller.changed();
  void calculate({bool findTarget = false}) =>
      controller.calculate(findTarget: findTarget);
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
            'Remaining tenure at rate reset',
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
  Widget build(BuildContext context) => GetBuilder<ProtectionController>(
    init: controller,
    global: false,
    autoRemove: false,
    builder: (_) => buildContent(context),
  );

  Widget buildContent(BuildContext context) => PageBody(
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
                  controller.change(() => reset = picked);
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
              onChanged: () => controller.change(() => targetMessage = null),
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
