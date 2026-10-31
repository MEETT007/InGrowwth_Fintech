import '../models/repayment_plan_model.dart';
import 'emi_calculator_service.dart';

class ProtectionResult {
  const ProtectionResult(
    this.baseline,
    this.prepay,
    this.reserve,
    this.resetMonth,
    this.reserveCash,
  );
  final RepaymentPlan baseline, prepay, reserve;
  final int resetMonth, reserveCash;
  int atReset(RepaymentPlan p) =>
      p.rows.length < resetMonth ? 0 : p.rows[resetMonth - 1].opening;
  int futureEmi(RepaymentPlan p) =>
      p.rows.length < resetMonth ? 0 : p.rows[resetMonth - 1].emi;
}

class EmiProtectionService {
  final engine = EmiCalculatorService();
  ProtectionResult compare({
    required int balance,
    required int rate,
    required int months,
    required int currentEmi,
    required int futureRate,
    required int resetMonth,
    required int extra,
    required AdjustmentPolicy policy,
  }) {
    if (resetMonth < 2 || resetMonth > months || currentEmi <= 0) {
      throw const FormatException();
    }
    RepaymentPlan plan(int contribution) => engine.schedule(
      principal: balance,
      rateBps: rate,
      months: months,
      payment: currentEmi,
      monthlyExtra: contribution,
      policy: policy,
      resetMonth: resetMonth,
      futureRateBps: futureRate,
      extrasUntilReset: true,
    );
    final baseline = plan(0), prepaid = plan(extra);
    return ProtectionResult(
      baseline,
      prepaid,
      baseline,
      resetMonth,
      extra * (resetMonth - 1),
    );
  }

  int? targetContribution({
    required int balance,
    required int rate,
    required int months,
    required int currentEmi,
    required int futureRate,
    required int resetMonth,
    required int target,
    required AdjustmentPolicy policy,
  }) {
    bool meets(int extra) {
      try {
        final result = compare(
          balance: balance,
          rate: rate,
          months: months,
          currentEmi: currentEmi,
          futureRate: futureRate,
          resetMonth: resetMonth,
          extra: extra,
          policy: policy,
        );
        return result.futureEmi(result.prepay) <= target;
      } on StateError {
        return false;
      }
    }

    if (target <= 0) return null;
    if (meets(0)) return 0;
    if (!meets(balance)) return null;
    var low = 0, high = balance;
    while (low < high) {
      final mid = (low + high) ~/ 2;
      if (meets(mid)) {
        high = mid;
      } else {
        low = mid + 1;
      }
    }
    return low;
  }
}
