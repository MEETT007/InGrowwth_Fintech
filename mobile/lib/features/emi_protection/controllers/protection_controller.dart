import '../../../core/controllers/screen_controller.dart';
import 'package:flutter/material.dart';
import '../../../models/loan_model.dart';
import '../../../models/repayment_plan_model.dart';
import '../../../core/strings/app_strings.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../services/emi_calculator_service.dart';
import '../../../services/emi_protection_service.dart';

class ProtectionController extends ScreenController {
  ProtectionController(this.loan);
  final LoanModel loan;

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
  void onInit() {
    super.onInit();
    final l = loan;
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
  void onClose() {
    for (final c in [balance, rate, months, emi, future, extra, target]) {
      c.dispose();
    }
    super.onClose();
  }

  void changed() => change(() {
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
    final first = loan.nextDue;
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
            : 'Approximately ${currency(contribution, decimals: true)} extra per month until reset date: ${displayDate(reset)}';
      }
      change(() {
        result = next;
        error = null;
        dirty = false;
        targetMessage = message;
      });
    } on FormatException {
      change(() => error = S.invalid);
    } on ArgumentError catch (e) {
      change(() => error = e.message.toString());
    } on StateError {
      change(() => error = S.noAmortization);
    }
  }
}
