import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/loan_model.dart';
import '../../../core/strings/app_strings.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../services/charge_analyzer_service.dart';
import '../../../services/emi_calculator_service.dart';

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
  late final TextEditingController emi, overdue;
  final days = TextEditingController(text: '10'),
      lender = TextEditingController(),
      product = TextEditingController(),
      returned = TextEditingController(),
      penal = TextEditingController(),
      tax = TextEditingController(),
      rate = TextEditingController(),
      reason = TextEditingController(),
      draft = TextEditingController();
  ChargeEstimate? result;
  String? error;
  bool contractual = false, dirty = true;
  int enteredOverdue = 0;
  @override
  void initState() {
    super.initState();
    final l = widget.loan;
    emi = TextEditingController(
      text: (EmiCalculatorService().emi(l.balance, l.rateBps, l.months) / 100)
          .toStringAsFixed(2),
    );
    overdue = TextEditingController(text: emi.text);
    lender.text = l.lender;
    product.text = l.nickname;
  }

  @override
  void dispose() {
    for (final c in [
      emi,
      overdue,
      days,
      lender,
      product,
      returned,
      penal,
      tax,
      rate,
      reason,
      draft,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void changed() => setState(() => dirty = true);
  void calculate() {
    try {
      final o = parseMoney(overdue.text),
          e = parseMoney(emi.text),
          d = int.tryParse(days.text);
      int? optional(TextEditingController c) {
        if (c.text.trim().isEmpty) return null;
        final v = parseMoney(c.text);
        if (v == null) throw const FormatException();
        return v;
      }

      if (o == null || e == null || e <= 0 || d == null) {
        throw const FormatException();
      }
      final next = ChargeAnalyzerService().calculate(
        overdue: o,
        days: d,
        returnFee: optional(returned),
        penal: optional(penal),
        taxBps: optional(tax),
        overdueRateBps: optional(rate),
      );
      setState(() {
        result = next;
        enteredOverdue = o;
        dirty = false;
        error = null;
      });
    } on FormatException {
      setState(() => error = S.invalid);
    }
  }

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
  Widget build(BuildContext context) => AppCard(
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
          onChanged: (v) => setState(() {
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
              setState(() => error = S.reasonError);
              return;
            }
            setState(() {
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
