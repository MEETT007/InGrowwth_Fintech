import '../models/repayment_plan_model.dart';

/// All monetary operations use integer paise. Rates use integer basis points.
/// Half-up monthly rounding is illustrative and is not a universal lender rule.
class EmiCalculatorService {
  int interest(int balance, int rateBps) =>
      (balance * rateBps + 60000) ~/ 120000;
  void validate(int principal, int rateBps, int months) {
    if (principal < 0 ||
        principal > 100000000000 ||
        rateBps < 0 ||
        rateBps > 3000 ||
        months < 1 ||
        months > 360) {
      throw const FormatException();
    }
  }

  int emi(int principal, int rateBps, int months) {
    validate(principal, rateBps, months);
    if (principal == 0) return 0;
    // Binary search the smallest paise payment that amortizes in the tenure.
    var low = 0, high = principal + interest(principal, rateBps);
    while (low < high) {
      final payment = (low + high) ~/ 2;
      var balance = principal;
      for (var m = 0; m < months && balance > 0; m++) {
        balance += interest(balance, rateBps) - payment;
        if (balance > principal * 2) break;
      }
      if (balance <= 0) {
        high = payment;
      } else {
        low = payment + 1;
      }
    }
    return low;
  }

  RepaymentPlan schedule({
    required int principal,
    required int rateBps,
    required int months,
    int? payment,
    int monthlyExtra = 0,
    int lump = 0,
    int lumpMonth = 1,
    AdjustmentPolicy policy = AdjustmentPolicy.tenure,
    int resetMonth = 0,
    int? futureRateBps,
    bool extrasUntilReset = false,
  }) {
    validate(principal, rateBps, months);
    if (monthlyExtra < 0 ||
        lump < 0 ||
        lumpMonth < 1 ||
        lumpMonth > months ||
        resetMonth < 0 ||
        resetMonth > months ||
        (futureRateBps != null &&
            (futureRateBps < 0 || futureRateBps > 3000))) {
      throw const FormatException();
    }
    var balance = principal,
        rate = rateBps,
        due = payment ?? emi(principal, rateBps, months);
    final rows = <RepaymentRow>[];
    for (var m = 1; balance > 0 && m <= 1200; m++) {
      if (m == resetMonth) {
        rate = futureRateBps ?? rate;
        if (policy == AdjustmentPolicy.emi) {
          due = emi(balance, rate, (months - m + 1).clamp(1, 360));
        }
      }
      final cost = interest(balance, rate);
      if (due <= cost) throw StateError('nonAmortizing');
      final actual = due.clamp(0, balance + cost);
      final capital = actual - cost;
      final extra =
          ((extrasUntilReset && resetMonth > 0 && m >= resetMonth
                      ? 0
                      : monthlyExtra) +
                  (m == lumpMonth ? lump : 0))
              .clamp(0, balance - capital);
      final closing = balance - capital - extra;
      rows.add(RepaymentRow(m, balance, actual, cost, capital, extra, closing));
      balance = closing;
      if (extra > 0 &&
          policy == AdjustmentPolicy.emi &&
          balance > 0 &&
          (!extrasUntilReset || m < resetMonth)) {
        due = emi(balance, rate, (months - m).clamp(1, 360));
      }
    }
    if (balance > 0) throw StateError('modellingLimit');
    return RepaymentPlan(List.unmodifiable(rows));
  }
}
