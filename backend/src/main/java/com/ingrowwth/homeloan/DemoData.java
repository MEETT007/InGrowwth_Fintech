package com.ingrowwth.homeloan;

import java.math.*;
import java.time.LocalDate;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Profile;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

@Component
@Profile("local")
class DemoData implements CommandLineRunner {
  final Users users;
  final Loans loans;
  final PasswordEncoder encoder;
  final RepaymentEngine engine;
  final String password;

  DemoData(
      Users u,
      Loans l,
      PasswordEncoder e,
      RepaymentEngine r,
      @Value("${app.demo-password}") String p) {
    users = u;
    loans = l;
    encoder = e;
    engine = r;
    password = p;
  }

  @Override
  @Transactional
  public void run(String... args) {
    if (users.count() > 0) return;
    User borrower = user("borrower@demo.ingrowwth", "Aarav Shah", "BORROWER");
    user("officer@demo.ingrowwth", "Priya Mehta", "OFFICER");
    user("second@demo.ingrowwth", "Neha Desai", "BORROWER");
    Loan l = base(borrower, "PURCHASE");
    l.stage = "ACTIVE";
    l.sanctionedAmount = l.requestedAmount;
    l.disbursed = l.requestedAmount;
    l.sanctionAccepted = true;
    l.creditChecked = l.legalChecked = l.valuationChecked = true;
    var p =
        new RepaymentEngine.PlanInput(
            l.requestedAmount,
            l.annualRate,
            240,
            BigDecimal.ZERO,
            BigDecimal.ZERO,
            BigDecimal.ZERO,
            0,
            "TENURE",
            0,
            l.annualRate,
            "EMI",
            BigDecimal.ZERO,
            "2024-11-05");
    var s = engine.schedule(p);
    l.outstanding = s.rows().get(23).closing();
    l.paidPrincipal = l.requestedAmount.subtract(l.outstanding);
    l.paidInterest =
        s.rows().subList(0, 24).stream()
            .map(RepaymentEngine.Row::interest)
            .reduce(BigDecimal.ZERO, BigDecimal::add);
    l.emi = s.emi();
    l.remainingMonths = 216;
    l.dueDate = LocalDate.now().plusMonths(1).withDayOfMonth(5).toString();
    loans.save(l);
    Loan construction = base(borrower, "CONSTRUCTION");
    construction.stage = "DISBURSEMENT";
    construction.sanctionedAmount = construction.requestedAmount;
    construction.disbursed = new BigDecimal("1500000");
    construction.outstanding = construction.disbursed;
    construction.sanctionAccepted = true;
    construction.creditChecked = construction.legalChecked = construction.valuationChecked = true;
    construction.propertyAddress = "Sample construction site, Ahmedabad";
    loans.save(construction);
  }

  User user(String email, String name, String role) {
    User u = new User();
    u.email = email;
    u.displayName = name;
    u.role = role;
    u.passwordHash = encoder.encode(password);
    return users.save(u);
  }

  Loan base(User u, String purpose) {
    Loan l = new Loan();
    l.borrowerId = u.id;
    l.applicantName = u.displayName;
    l.email = u.email;
    l.city = "Ahmedabad";
    l.employment = "SALARIED";
    l.purpose = purpose;
    l.propertyAddress = "Sample apartment, Ahmedabad";
    l.income = new BigDecimal("125000");
    l.coIncome = BigDecimal.ZERO;
    l.obligations = new BigDecimal("10000");
    l.propertyValue = new BigDecimal("6500000");
    l.requestedAmount = new BigDecimal("4500000");
    l.annualRate = new BigDecimal("8.5");
    l.tenureMonths = 240;
    return l;
  }
}
