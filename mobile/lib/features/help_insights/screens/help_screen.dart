import 'package:get/get.dart';
import '../controllers/help_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/loan_model.dart';
import '../../../core/strings/app_strings.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../services/charge_analyzer_service.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key, required this.loan});
  final LoanModel loan;
  @override
  Widget build(BuildContext context) => PageBody(
    title: S.helpTitle,
    subtitle: S.helpBody,
    children: [
      AppCard(
        highlight: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(S.scoreTitle),
            Text(
              '${(loan.principalPaid / loan.original * 100).round()} / 100',
              style: AppTextStyles.responsive(context, AppTextStyles.amount),
            ),
            const InfoNote(S.scoreNote),
            const SizedBox(height: 12),
            const InfoNote(S.scoreMethod),
          ],
        ),
      ),
      ChargeAnalyzer(loan: loan),
      AppCard(
        child: Column(
          children: [
            for (var i = 0; i < S.terms.length; i++)
              ExpansionTile(
                title: Text(S.terms[i]),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(S.answers[i]),
                  ),
                ],
              ),
          ],
        ),
      ),
    ],
  );
}

class ChargeAnalyzer extends StatefulWidget {
  const ChargeAnalyzer({super.key, required this.loan});
  final LoanModel loan;
  @override
  State<ChargeAnalyzer> createState() => _ChargeAnalyzerState();
}

class _ChargeAnalyzerState extends State<ChargeAnalyzer> {
  late final ChargeAnalyzerController controller;
  @override
  void initState() {
    super.initState();
    controller = ChargeAnalyzerController(widget.loan)..onStart.call();
  }

  @override
  void dispose() {
    controller.onDelete();
    super.dispose();
  }

  TextEditingController get emi => controller.emi;
  TextEditingController get overdue => controller.overdue;
  TextEditingController get days => controller.days;
  TextEditingController get lender => controller.lender;
  TextEditingController get product => controller.product;
  TextEditingController get returned => controller.returned;
  TextEditingController get penal => controller.penal;
  TextEditingController get tax => controller.tax;
  TextEditingController get rate => controller.rate;
  TextEditingController get reason => controller.reason;
  TextEditingController get draft => controller.draft;
  ChargeEstimate? get result => controller.result;
  String? get error => controller.error;
  set error(String? value) => controller.error = value;
  bool get contractual => controller.contractual;
  set contractual(bool value) => controller.contractual = value;
  bool get dirty => controller.dirty;
  set dirty(bool value) => controller.dirty = value;
  int get enteredOverdue => controller.enteredOverdue;
  void changed() => controller.changed();
  void calculate() => controller.calculate();
  Widget item(String name, int? value) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(name),
    subtitle: Text(
      value == null
          ? S.unknown
          : contractual
          ? S.contractual
          : S.illustrative,
    ),
    trailing: value == null ? null : Text(currency(value, decimals: true)),
  );
  @override
  Widget build(BuildContext context) => GetBuilder<ChargeAnalyzerController>(
    init: controller,
    global: false,
    autoRemove: false,
    builder: (_) => buildContent(context),
  );

  Widget buildContent(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(S.charges),
        const InfoNote(S.chargesBody),
        const SizedBox(height: 20),
        AdaptiveGrid(
          minWidth: 270,
          children: [
            NumberField(S.emiInput, emi, onChanged: changed),
            NumberField(S.overdue, overdue, onChanged: changed),
            NumberField(S.days, days, onChanged: changed, integer: true),
            TextField(
              controller: lender,
              onChanged: (_) => changed(),
              decoration: const InputDecoration(labelText: S.lender),
            ),
            TextField(
              controller: product,
              onChanged: (_) => changed(),
              decoration: const InputDecoration(labelText: S.product),
            ),
            NumberField(S.returnFee, returned, onChanged: changed),
            NumberField(S.penal, penal, onChanged: changed),
            NumberField(S.tax, tax, onChanged: changed),
            NumberField(S.overdueRate, rate, onChanged: changed),
          ],
        ),
        const SizedBox(height: 20),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(S.contractual),
          subtitle: Text(S.source),
          value: contractual,
          onChanged: (v) => controller.change(() {
            contractual = v;
            dirty = true;
          }),
        ),
        FilledButton(onPressed: calculate, child: Text(S.calculate)),
        if (error != null) InfoNote(error!, error: true),
        if (result != null) ...[
          const Divider(),
          if (dirty) const InfoNote(S.stale),
          const SectionTitle(S.chargeBreakdown),
          item(S.returnFee, result!.returnFee),
          item(S.penal, result!.penal),
          item(S.feeTax, result!.tax),
          item(S.overdueInterest, result!.interest),
          const Divider(),
          Metric(S.chargesTotal, currency(result!.subtotal, decimals: true)),
          const SizedBox(height: 16),
          Metric(
            S.amountToClear,
            currency(enteredOverdue + result!.subtotal, decimals: true),
          ),
        ],
        const SizedBox(height: 20),
        const InfoNote(S.chargeDisclaimer),
        const Divider(),
        const SectionTitle(S.waiver),
        TextField(
          controller: reason,
          maxLines: 3,
          maxLength: 1000,
          decoration: const InputDecoration(labelText: S.reason),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () {
            if (reason.text.trim().length < 5) {
              controller.change(() => error = S.reasonError);
              return;
            }
            controller.change(() {
              error = null;
              draft.text = S.waiverText(reason.text.trim());
            });
          },
          child: Text(S.draft),
        ),
        if (draft.text.isNotEmpty) ...[
          const SizedBox(height: 16),
          TextField(
            controller: draft,
            minLines: 6,
            maxLines: 14,
            decoration: const InputDecoration(labelText: S.request),
          ),
          TextButton.icon(
            icon: const Icon(Icons.copy_outlined),
            label: Text(S.copy),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: draft.text));
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text(S.copied)));
              }
            },
          ),
        ],
        const SizedBox(height: 12),
        const InfoNote(S.waiverNote),
      ],
    ),
  );
}
