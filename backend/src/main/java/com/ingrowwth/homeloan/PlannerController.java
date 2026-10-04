package com.ingrowwth.homeloan;

import java.math.*;
import java.util.*;
import org.springframework.web.bind.annotation.*;

@RestController
class PlannerController {
  final RepaymentEngine engine;

  PlannerController(RepaymentEngine e) {
    engine = e;
  }

  @PostMapping("/api/planner")
  Object plan(@RequestBody RepaymentEngine.PlanInput p) {
    return engine.compare(p);
  }

  record Refinance(
      BigDecimal principal,
      BigDecimal currentRate,
      BigDecimal newRate,
      int months,
      BigDecimal fees) {}

  @PostMapping("/api/refinance")
  Object refinance(@RequestBody Refinance p) {
    if (p.principal == null
        || p.principal.signum() <= 0
        || p.months < 1
        || p.months > 360
        || p.fees == null
        || p.fees.signum() < 0)
      throw new IllegalArgumentException("Please enter valid balance, tenure and fees.");
    RepaymentEngine.checkRate(p.currentRate);
    RepaymentEngine.checkRate(p.newRate);
    var old = engine.emi(p.principal, p.currentRate, p.months);
    var next = engine.emi(p.principal, p.newRate, p.months);
    var saving = old.subtract(next);
    Map<String, Object> result = new LinkedHashMap<>();
    result.put("currentEmi", old);
    result.put("newEmi", next);
    result.put("monthlySaving", saving);
    result.put("fees", p.fees);
    result.put("netSaving", saving.multiply(BigDecimal.valueOf(p.months)).subtract(p.fees));
    result.put(
        "breakEvenMonths",
        saving.signum() > 0 ? p.fees.divide(saving, 0, RoundingMode.CEILING).intValue() : null);
    result.put(
        "assumption",
        "Same remaining tenure and constant rates; include processing, legal, valuation and"
            + " applicable closure costs in fees.");
    return result;
  }
}
