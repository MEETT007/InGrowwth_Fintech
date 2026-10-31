import 'package:flutter_test/flutter_test.dart';
import 'package:home_finance/services/emi_calculator_service.dart';
import 'package:home_finance/services/emi_protection_service.dart';
import 'package:home_finance/services/charge_analyzer_service.dart';
import 'package:home_finance/models/repayment_plan_model.dart';
import 'package:home_finance/data/repositories/auth_repository.dart';
import 'package:home_finance/core/utils/currency_formatter.dart';

void main() {
  final engine = EmiCalculatorService();
  test('integer paise EMI matches reference and principal is conserved', () {
    final emi = engine.emi(300000000, 700, 240);
    expect(emi / 100, closeTo(23258.97, .02));
    final p = engine.schedule(principal: 300000000, rateBps: 700, months: 240);
    expect(p.months, 240);
    expect(p.rows.last.closing, 0);
    expect(p.rows.fold<int>(0, (s, r) => s + r.principal + r.extra), 300000000);
  });
  test('zero rate and capped prepayment', () {
    expect(engine.emi(12000000, 0, 12), 1000000);
    final p = engine.schedule(
      principal: 12000000,
      rateBps: 0,
      months: 12,
      monthlyExtra: 20000000,
    );
    expect(p.months, 1);
    expect(p.extras, 11000000);
  });
  test(
    'two prepayment policies reduce cost with different payment outcomes',
    () {
      RepaymentPlan plan(AdjustmentPolicy policy) => engine.schedule(
        principal: 300000000,
        rateBps: 700,
        months: 240,
        monthlyExtra: 200000,
        policy: policy,
      );
      final a = plan(AdjustmentPolicy.tenure), b = plan(AdjustmentPolicy.emi);
      expect(a.months, lessThan(240));
      expect(b.rows[1].emi, lessThan(a.rows[1].emi));
      expect(a.interest, lessThan(b.interest));
    },
  );
  test('rate reset and reserve comparisons are coherent', () {
    final result = EmiProtectionService().compare(
      balance: 300000000,
      rate: 700,
      months: 240,
      currentEmi: engine.emi(300000000, 700, 240),
      futureRate: 900,
      resetMonth: 13,
      extra: 200000,
      policy: AdjustmentPolicy.emi,
    );
    expect(
      result.futureEmi(result.prepay),
      lessThan(result.futureEmi(result.baseline)),
    );
    expect(
      result.atReset(result.prepay),
      lessThan(result.atReset(result.baseline)),
    );
    expect(result.reserveCash, 2400000);
    expect(result.reserve.interest, result.baseline.interest);
  });
  test('target search meets target and one paise less does not', () {
    final service = EmiProtectionService(),
        emi = engine.emi(300000000, 700, 240);
    final x = service.targetContribution(
      balance: 300000000,
      rate: 700,
      months: 240,
      currentEmi: emi,
      futureRate: 900,
      resetMonth: 13,
      target: emi,
      policy: AdjustmentPolicy.emi,
    )!;
    int future(int value) {
      final r = service.compare(
        balance: 300000000,
        rate: 700,
        months: 240,
        currentEmi: emi,
        futureRate: 900,
        resetMonth: 13,
        extra: value,
        policy: AdjustmentPolicy.emi,
      );
      return r.futureEmi(r.prepay);
    }

    expect(x, greaterThan(0));
    expect(future(x), lessThanOrEqualTo(emi));
    expect(future(x - 1), greaterThan(emi));
  });
  test('invalid and non-amortizing scenarios are rejected', () {
    expect(() => engine.emi(-1, 700, 240), throwsFormatException);
    expect(
      () => engine.schedule(
        principal: 300000000,
        rateBps: 700,
        months: 240,
        payment: 1,
      ),
      throwsStateError,
    );
  });
  test('known and unknown charges stay distinct', () {
    final s = ChargeAnalyzerService();
    final r = s.calculate(
      overdue: 2000000,
      days: 10,
      returnFee: 50000,
      penal: 20000,
      taxBps: 1800,
      overdueRateBps: 1200,
    );
    expect(r.tax, 12600);
    expect(r.interest, 6575);
    expect(r.subtotal, 89175);
    final unknown = s.calculate(overdue: 2000000, days: 10);
    expect(unknown.tax, isNull);
    expect(unknown.interest, isNull);
    expect(unknown.subtotal, 0);
  });
  test('local auth isolates special number and rejects wrong OTP', () {
    final a = AuthRepository();
    expect(a.verify('8200229099', '123456')!.isSpecial, isTrue);
    expect(a.verify('9876543210', '123456')!.isSpecial, isFalse);
    expect(a.verify('9876543210', '000000'), isNull);
    expect(a.validMobile('123'), isFalse);
  });
  test('Indian currency formatting preserves paise', () {
    expect(currency(300000000), '₹30,00,000');
    expect(currency(12345, decimals: true), '₹123.45');
  });
}
