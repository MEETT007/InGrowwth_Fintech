import '../../../core/controllers/screen_controller.dart';
import 'package:flutter/material.dart';
import '../../../models/loan_model.dart';
import '../../../models/repayment_plan_model.dart';
import '../../../core/strings/app_strings.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../services/emi_calculator_service.dart';

class RepaymentController extends ScreenController {
  RepaymentController(this.loan);
  final LoanModel loan;

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
  void onClose() {
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
    super.onClose();
  }

  void changed() => change(() => dirty = true);
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
      final engine = EmiCalculatorService();
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
      change(() {
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
      change(() => error = S.invalid);
    } on StateError {
      change(() => error = S.noAmortization);
    }
  }
}
