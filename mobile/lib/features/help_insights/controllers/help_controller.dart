import '../../../core/controllers/screen_controller.dart';
import 'package:flutter/material.dart';
import '../../../models/loan_model.dart';
import '../../../core/strings/app_strings.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../services/charge_analyzer_service.dart';
import '../../../services/emi_calculator_service.dart';

class ChargeAnalyzerController extends ScreenController {
  ChargeAnalyzerController(this.loan);
  final LoanModel loan;

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
  void onInit() {
    super.onInit();
    final l = loan;
    emi = TextEditingController(
      text: (EmiCalculatorService().emi(l.balance, l.rateBps, l.months) / 100)
          .toStringAsFixed(2),
    );
    overdue = TextEditingController(text: emi.text);
    lender.text = l.lender;
    product.text = l.nickname;
  }

  @override
  void onClose() {
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
    super.onClose();
  }

  void changed() => change(() => dirty = true);
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
      change(() {
        result = next;
        enteredOverdue = o;
        dirty = false;
        error = null;
      });
    } on FormatException {
      change(() => error = S.invalid);
    }
  }
}
