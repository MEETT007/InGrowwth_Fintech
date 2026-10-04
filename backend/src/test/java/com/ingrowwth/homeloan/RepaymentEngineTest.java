package com.ingrowwth.homeloan;

import static org.junit.jupiter.api.Assertions.*;

import java.math.BigDecimal;
import org.junit.jupiter.api.Test;

class RepaymentEngineTest {
  final RepaymentEngine e = new RepaymentEngine();

  BigDecimal b(String v) {
    return new BigDecimal(v);
  }

  RepaymentEngine.PlanInput plan(String mode, String extra, String lump) {
    return new RepaymentEngine.PlanInput(
        b("4500000"),
        b("8.5"),
        240,
        b(extra),
        b("0"),
        b(lump),
        12,
        mode,
        0,
        b("8.5"),
        "EMI",
        b("0"),
        "2026-11-05");
  }

  @Test
  void publishedFormulaAndZeroRate() {
    assertEquals(b("8884.88"), e.emi(b("100000"), b("12"), 12));
    assertEquals(b("10000.00"), e.emi(b("120000"), b("0"), 12));
  }

  @Test
  void scheduleConservesPrincipal() {
    var s = e.schedule(plan("TENURE", "0", "0"));
    assertEquals(b("4500000.00"), s.principalPaid());
    assertEquals(b("0.00"), s.rows().getLast().closing());
    assertEquals(s.totalPaid(), s.principalPaid().add(s.interest()));
    assertTrue(
        s.rows().stream()
            .allMatch(
                r ->
                    r.opening().subtract(r.principal()).subtract(r.extra()).compareTo(r.closing())
                        == 0));
  }

  @Test
  void recurringExtraShortensTenureAndReducesInterest() {
    var p = e.compare(plan("TENURE", "5000", "100000"));
    assertTrue(p.monthsSaved() > 0);
    assertTrue(p.interestSaved().signum() > 0);
    assertEquals(p.baseline().emi(), p.planned().emi());
  }

  @Test
  void emiReductionKeepsOriginalMaturity() {
    var p = e.compare(plan("EMI", "0", "100000"));
    assertTrue(p.interestSaved().signum() > 0);
    assertTrue(p.planned().rows().get(12).emi().compareTo(p.baseline().emi()) < 0);
    assertTrue(p.monthsSaved() <= 1);
  }

  @Test
  void excessivePrepaymentIsCappedAtBalance() {
    var s = e.schedule(plan("TENURE", "99999999", "0"));
    assertEquals(1, s.months());
    assertEquals(b("4500000.00"), s.principalPaid());
    assertEquals(b("0.00"), s.rows().getFirst().closing());
  }

  @Test
  void invalidInputRejected() {
    assertThrows(
        IllegalArgumentException.class,
        () ->
            e.compare(
                new RepaymentEngine.PlanInput(
                    b("100"),
                    b("8"),
                    0,
                    b("0"),
                    b("0"),
                    b("0"),
                    0,
                    "TENURE",
                    0,
                    b("8"),
                    "EMI",
                    b("0"),
                    "2026-11-05")));
  }

  @Test
  void rateResetChangesEmiAndDisclosesNonAmortisation() {
    var input =
        new RepaymentEngine.PlanInput(
            b("4500000"),
            b("8.5"),
            240,
            b("0"),
            b("0"),
            b("0"),
            0,
            "TENURE",
            12,
            b("9.5"),
            "EMI",
            b("0"),
            "2026-11-05");
    var s = e.schedule(input);
    assertTrue(s.rows().get(11).emi().compareTo(s.rows().get(10).emi()) > 0);
    var danger =
        new RepaymentEngine.PlanInput(
            b("4500000"),
            b("8.5"),
            240,
            b("0"),
            b("0"),
            b("0"),
            0,
            "TENURE",
            12,
            b("30"),
            "TENURE",
            b("0"),
            "2026-11-05");
    assertFalse(e.schedule(danger).warnings().isEmpty());
  }
}
