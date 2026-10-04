package com.ingrowwth.homeloan;

import java.math.*;
import java.time.LocalDate;
import java.util.*;
import org.springframework.stereotype.Service;

@Service
public class RepaymentEngine {
  public record PlanInput(
      BigDecimal principal,
      BigDecimal annualRate,
      int months,
      BigDecimal extraMonthly,
      BigDecimal annualExtra,
      BigDecimal oneTime,
      int oneTimeMonth,
      String prepayMode,
      int resetMonth,
      BigDecimal resetRate,
      String resetMode,
      BigDecimal fees,
      String startDate) {}

  public record Row(
      int month,
      String date,
      BigDecimal opening,
      BigDecimal rate,
      BigDecimal emi,
      BigDecimal interest,
      BigDecimal principal,
      BigDecimal extra,
      BigDecimal closing) {}

  public record Schedule(
      BigDecimal emi,
      BigDecimal interest,
      BigDecimal principalPaid,
      BigDecimal totalPaid,
      int months,
      String payoffDate,
      List<Row> rows,
      List<String> warnings) {}

  public record Comparison(
      Schedule baseline,
      Schedule planned,
      BigDecimal interestSaved,
      int monthsSaved,
      BigDecimal netSavings,
      BigDecimal fees,
      List<String> assumptions) {}

  static final BigDecimal ZERO = new BigDecimal("0.00");

  static BigDecimal money(BigDecimal n) {
    return n.setScale(2, RoundingMode.HALF_UP);
  }

  static BigDecimal nz(BigDecimal n) {
    return n == null ? ZERO : n;
  }

  public BigDecimal emi(BigDecimal p, BigDecimal rate, int months) {
    if (months <= 0) throw new IllegalArgumentException("Tenure must be positive.");
    if (rate.signum() == 0) return p.divide(BigDecimal.valueOf(months), 2, RoundingMode.HALF_UP);
    double r = rate.doubleValue() / 1200;
    double f = Math.pow(1 + r, months);
    return money(BigDecimal.valueOf(p.doubleValue() * r * f / (f - 1)));
  }

  public Comparison compare(PlanInput p) {
    validate(p);
    PlanInput plain =
        new PlanInput(
            p.principal,
            p.annualRate,
            p.months,
            ZERO,
            ZERO,
            ZERO,
            0,
            "TENURE",
            p.resetMonth,
            p.resetRate,
            p.resetMode,
            ZERO,
            p.startDate);
    Schedule baseline = schedule(plain);
    Schedule planned = schedule(p);
    if (!baseline.warnings.isEmpty() || !planned.warnings.isEmpty())
      throw new IllegalArgumentException(
          !planned.warnings.isEmpty() ? planned.warnings.getFirst() : baseline.warnings.getFirst());
    BigDecimal saved = baseline.interest.subtract(planned.interest);
    return new Comparison(
        baseline,
        planned,
        money(saved),
        baseline.months - planned.months,
        money(saved.subtract(nz(p.fees))),
        money(nz(p.fees)),
        List.of(
            "Monthly reducing balance; monthly interest and payment amounts rounded to paise.",
            "Extra principal is applied after the scheduled monthly instalment. Annual extras occur"
                + " every 12 months.",
            "Rates stay constant except the explicit reset scenario. Future rates are not"
                + " predicted.",
            "Fees are an upfront scenario cost; lender quotes and actual dates can change the"
                + " result."));
  }

  public void validate(PlanInput p) {
    if (p == null
        || p.principal == null
        || p.principal.compareTo(new BigDecimal("1000")) < 0
        || p.principal.compareTo(new BigDecimal("1000000000")) > 0)
      throw new IllegalArgumentException("Principal must be between ₹1,000 and ₹100 crore.");
    if (p.months < 1 || p.months > 360)
      throw new IllegalArgumentException("Tenure must be 1–360 months.");
    checkRate(p.annualRate);
    for (BigDecimal amount :
        List.of(nz(p.extraMonthly), nz(p.annualExtra), nz(p.oneTime), nz(p.fees)))
      if (amount.signum() < 0 || amount.compareTo(new BigDecimal("1000000000")) > 0)
        throw new IllegalArgumentException(
            "Additional payments and fees must be non-negative and within the supported limit.");
    if (p.oneTimeMonth < 0
        || p.oneTimeMonth > p.months
        || p.resetMonth < 0
        || p.resetMonth > p.months)
      throw new IllegalArgumentException("Scenario months must fall within the original tenure.");
    if (nz(p.oneTime).signum() > 0 && p.oneTimeMonth < 1)
      throw new IllegalArgumentException("Choose a month for the one-time payment.");
    if (p.resetMonth > 0) checkRate(p.resetRate);
    if (!List.of("TENURE", "EMI").contains(p.prepayMode))
      throw new IllegalArgumentException("Choose TENURE or EMI for prepayment.");
    if (!List.of("TENURE", "EMI").contains(p.resetMode))
      throw new IllegalArgumentException("Choose TENURE or EMI for the rate reset.");
    try {
      LocalDate.parse(p.startDate);
    } catch (Exception e) {
      throw new IllegalArgumentException("A valid first-payment date is required.");
    }
  }

  static void checkRate(BigDecimal r) {
    if (r == null || r.signum() < 0 || r.compareTo(new BigDecimal("30")) > 0)
      throw new IllegalArgumentException("Annual rate must be between 0% and 30%.");
  }

  public Schedule schedule(PlanInput p) {
    validate(p);
    BigDecimal balance = money(p.principal),
        rate = p.annualRate,
        payment = emi(balance, rate, p.months),
        initial = payment,
        totalInterest = ZERO,
        totalPrincipal = ZERO,
        totalPaid = ZERO;
    List<Row> rows = new ArrayList<>();
    List<String> warnings = new ArrayList<>();
    LocalDate date = LocalDate.parse(p.startDate);
    int m = 0;
    while (balance.signum() > 0 && m < 1200) {
      m++;
      if (m == p.resetMonth) {
        rate = p.resetRate;
        if ("EMI".equals(p.resetMode)) payment = emi(balance, rate, Math.max(1, p.months - m + 1));
      }
      BigDecimal interest =
          money(balance.multiply(rate).divide(new BigDecimal("1200"), 12, RoundingMode.HALF_UP));
      BigDecimal due = payment.min(balance.add(interest));
      if (due.compareTo(interest) <= 0) {
        warnings.add(
            "The scheduled EMI does not cover interest after the rate reset. Increase the EMI or"
                + " revise the loan terms.");
        break;
      }
      BigDecimal principal = due.subtract(interest);
      BigDecimal extra =
          nz(p.extraMonthly)
              .add(m % 12 == 0 ? nz(p.annualExtra) : ZERO)
              .add(m == p.oneTimeMonth ? nz(p.oneTime) : ZERO)
              .min(balance.subtract(principal));
      BigDecimal closing = money(balance.subtract(principal).subtract(extra));
      rows.add(
          new Row(
              m,
              date.plusMonths(m - 1).toString(),
              balance,
              rate,
              money(due),
              interest,
              money(principal),
              money(extra),
              closing));
      totalInterest = totalInterest.add(interest);
      totalPrincipal = totalPrincipal.add(principal).add(extra);
      totalPaid = totalPaid.add(due).add(extra);
      balance = closing;
      if (extra.signum() > 0 && "EMI".equals(p.prepayMode) && balance.signum() > 0)
        payment = emi(balance, rate, Math.max(1, p.months - m));
    }
    if (balance.signum() > 0 && warnings.isEmpty())
      warnings.add(
          "The loan does not close within the 100-year modelling limit. Revise the scenario.");
    int count = rows.size();
    return new Schedule(
        initial,
        money(totalInterest),
        money(totalPrincipal),
        money(totalPaid),
        count,
        balance.signum() == 0 && count > 0 ? rows.getLast().date : null,
        List.copyOf(rows),
        List.copyOf(warnings));
  }
}
