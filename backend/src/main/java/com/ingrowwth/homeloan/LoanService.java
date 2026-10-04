package com.ingrowwth.homeloan;

import java.math.*;
import java.time.*;
import java.util.*;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.*;
import org.springframework.web.server.ResponseStatusException;

@Service
class LoanService {
  final Users users;
  final Loans loans;
  final Documents documents;
  final Events events;
  final Queries queries;
  final Payments payments;
  final LiveUpdates live;
  final RepaymentEngine engine;
  static final List<String> DOCS =
      List.of("Identity proof", "Income proof", "Bank statements", "Property documents");

  LoanService(
      Users u,
      Loans l,
      Documents d,
      Events e,
      Queries q,
      Payments p,
      LiveUpdates n,
      RepaymentEngine r) {
    users = u;
    loans = l;
    documents = d;
    events = e;
    queries = q;
    payments = p;
    live = n;
    engine = r;
  }

  Loans loanRepo() {
    return loans;
  }

  Documents documentRepo() {
    return documents;
  }

  LiveUpdates updates() {
    return live;
  }

  User user(Authentication a) {
    return users
        .findByEmail(a.getName())
        .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED));
  }

  void officer(User u) {
    if (!u.role.equals("OFFICER"))
      throw new ResponseStatusException(
          HttpStatus.FORBIDDEN, "Only a lending officer can perform this action.");
  }

  Loan access(String id, User u, boolean lock) {
    Loan l =
        (lock ? loans.lock(id) : loans.findById(id))
            .orElseThrow(
                () ->
                    new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Loan application not found."));
    if (!u.role.equals("OFFICER") && !l.borrowerId.equals(u.id))
      throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Loan application not found.");
    return l;
  }

  void borrower(Loan l, User u) {
    if (!u.role.equals("BORROWER") || !l.borrowerId.equals(u.id))
      throw new ResponseStatusException(
          HttpStatus.FORBIDDEN, "Only the applicant can perform this action.");
  }

  void event(Loan l, User u, String text) {
    l.updatedAt = Instant.now().toString();
    LoanEvent e = new LoanEvent();
    e.loanId = l.id;
    e.actorId = u.id;
    e.message = text;
    events.save(e);
    if (TransactionSynchronizationManager.isSynchronizationActive())
      TransactionSynchronizationManager.registerSynchronization(
          new TransactionSynchronization() {
            public void afterCommit() {
              live.publish(l.borrowerId, l.id);
            }
          });
    else live.publish(l.borrowerId, l.id);
  }

  Map<String, Object> detail(Loan l) {
    return Map.of(
        "loan",
        l,
        "documents",
        documents.findByLoanId(l.id),
        "events",
        events.findByLoanIdOrderByCreatedAtDesc(l.id),
        "queries",
        queries.findByLoanId(l.id),
        "payments",
        payments.findByLoanIdOrderByCreatedAtDesc(l.id));
  }

  void revision(Loan l, long rev) {
    if (l.revision != rev)
      throw new ResponseStatusException(
          HttpStatus.CONFLICT, "This case changed. Refresh before saving.");
  }

  @Transactional
  Map<String, Object> action(String id, User u, LoanController.Action input) {
    Loan l = access(id, u, true);
    revision(l, input.revision());
    String action = input.action();
    String note = Objects.requireNonNullElse(input.note(), "").trim();
    switch (action) {
      case "SUBMIT" -> {
        borrower(l, u);
        if (!l.stage.equals("DRAFT"))
          throw new IllegalArgumentException("Only a draft can be submitted.");
        l.stage = "SUBMITTED";
        event(l, u, "Applicant submitted the application.");
      }
      case "ACCEPT_SANCTION" -> {
        borrower(l, u);
        if (!l.stage.equals("SANCTIONED"))
          throw new IllegalArgumentException("Sanction acceptance is not available at this stage.");
        l.sanctionAccepted = true;
        l.stage = "DISBURSEMENT";
        event(l, u, "Applicant accepted the recorded sanction terms.");
      }
      case "QUERY" -> {
        officer(u);
        if (l.stage.equals("CLOSED"))
          throw new IllegalArgumentException("Closed loans do not accept new review queries.");
        if (note.length() < 5 || note.length() > 1000)
          throw new IllegalArgumentException("Please enter a clarification of 5–1000 characters.");
        LoanQuery q = new LoanQuery();
        q.loanId = l.id;
        q.question = note;
        queries.save(q);
        event(l, u, "Officer requested clarification: " + note);
      }
      case "RESPOND" -> {
        borrower(l, u);
        if (note.length() < 5 || note.length() > 1000)
          throw new IllegalArgumentException("Please enter a response of 5–1000 characters.");
        LoanQuery q =
            queries
                .findById(input.targetId())
                .filter(x -> x.loanId.equals(id) && !x.resolved)
                .orElseThrow(() -> new IllegalArgumentException("Open clarification not found."));
        q.response = note;
        queries.save(q);
        event(l, u, "Applicant supplied a clarification response.");
      }
      case "RESOLVE_QUERY" -> {
        officer(u);
        LoanQuery q =
            queries
                .findById(input.targetId())
                .filter(x -> x.loanId.equals(id) && !x.resolved)
                .orElseThrow(() -> new IllegalArgumentException("Open clarification not found."));
        if (q.response == null)
          throw new IllegalArgumentException(
              "The applicant must respond before this query can be resolved.");
        q.resolved = true;
        queries.save(q);
        event(l, u, "Officer accepted the clarification response.");
      }
      case "VERIFY_DOCUMENT" -> {
        officer(u);
        if (List.of("SANCTIONED", "DISBURSEMENT", "ACTIVE", "CLOSED").contains(l.stage))
          throw new IllegalArgumentException("Document verification is closed after sanction.");
        LoanDocument d =
            documents
                .findById(input.targetId())
                .filter(x -> x.loanId.equals(id))
                .orElseThrow(() -> new IllegalArgumentException("Document not found."));
        d.verified = true;
        documents.save(d);
        event(l, u, "Officer verified " + d.kind + ".");
      }
      case "REVIEW" -> {
        officer(u);
        if (note.length() < 5 || note.length() > 1000)
          throw new IllegalArgumentException(
              "A review rationale of 5–1000 characters is required.");
        if ("CREDIT".equals(input.targetId()) && l.stage.equals("CREDIT_REVIEW"))
          l.creditChecked = true;
        else if ("LEGAL".equals(input.targetId()) && l.stage.equals("PROPERTY_REVIEW"))
          l.legalChecked = true;
        else if ("VALUATION".equals(input.targetId()) && l.stage.equals("PROPERTY_REVIEW"))
          l.valuationChecked = true;
        else
          throw new IllegalArgumentException("This review is not available at the current stage.");
        event(l, u, input.targetId() + " review recorded: " + note);
      }
      case "ADVANCE" -> {
        officer(u);
        if (queries.findByLoanId(id).stream().anyMatch(q -> !q.resolved))
          throw new IllegalArgumentException("Resolve all clarifications before advancing.");
        switch (l.stage) {
          case "SUBMITTED" -> l.stage = "DOCUMENT_REVIEW";
          case "DOCUMENT_REVIEW" -> {
            if (!DOCS.stream()
                .allMatch(
                    k ->
                        documents.findByLoanId(id).stream()
                            .anyMatch(d -> d.kind.equals(k) && d.verified)))
              throw new IllegalArgumentException(
                  "Verify every required document category before credit review.");
            l.stage = "CREDIT_REVIEW";
          }
          case "CREDIT_REVIEW" -> {
            if (!l.creditChecked)
              throw new IllegalArgumentException("Complete the credit review first.");
            l.stage = "PROPERTY_REVIEW";
          }
          default ->
              throw new IllegalArgumentException(
                  "Stage advancement is not available. Use sanction or disbursement actions.");
        }
        event(l, u, "Case moved to " + l.stage + ".");
      }
      case "SANCTION" -> {
        officer(u);
        if (!l.stage.equals("PROPERTY_REVIEW")
            || !l.creditChecked
            || !l.legalChecked
            || !l.valuationChecked)
          throw new IllegalArgumentException("Complete credit, legal and valuation reviews first.");
        if (queries.findByLoanId(id).stream().anyMatch(q -> !q.resolved))
          throw new IllegalArgumentException("Resolve all clarifications first.");
        if (note.length() < 5 || note.length() > 1000)
          throw new IllegalArgumentException("A sanction rationale is required.");
        l.sanctionedAmount = l.requestedAmount;
        l.stage = "SANCTIONED";
        event(l, u, "Manual sandbox sanction recorded: " + note);
      }
      case "CLOSURE_CHECK" -> {
        officer(u);
        if (!l.stage.equals("CLOSED"))
          throw new IllegalArgumentException("Closure tasks require a repaid loan.");
        switch (Objects.requireNonNullElse(input.targetId(), "")) {
          case "CERTIFICATE" -> l.closureCertificate = true;
          case "ORIGINALS" -> l.originalsReturned = true;
          case "SECURITY" -> l.securityReleased = true;
          default -> throw new IllegalArgumentException("Unknown closure task.");
        }
        event(l, u, "Closure task completed: " + input.targetId() + ".");
      }
      case "DISBURSE" -> {
        officer(u);
        if (!l.stage.equals("DISBURSEMENT") || !l.sanctionAccepted)
          throw new IllegalArgumentException("Applicant must accept sanction before disbursement.");
        BigDecimal amount = input.amount();
        if (amount == null
            || amount.signum() <= 0
            || amount.compareTo(l.sanctionedAmount.subtract(l.disbursed)) > 0)
          throw new IllegalArgumentException(
              "Tranche must be positive and within the undisbursed sanctioned amount.");
        if (note.length() < 4 || note.length() > 100)
          throw new IllegalArgumentException("A sandbox disbursement reference is required.");
        if (amount.scale() > 2)
          throw new IllegalArgumentException("Tranche amount can have at most two decimal places.");
        if (l.dueDate == null)
          l.dueDate = LocalDate.now().plusMonths(1).withDayOfMonth(5).toString();
        l.disbursed = l.disbursed.add(amount);
        l.outstanding = l.outstanding.add(amount);
        event(l, u, "Sandbox tranche of ₹" + amount + " recorded. Reference: " + note);
        if (l.disbursed.compareTo(l.sanctionedAmount) == 0) {
          l.stage = "ACTIVE";
          l.remainingMonths = l.tenureMonths;
          l.emi = engine.emi(l.outstanding, l.annualRate, l.remainingMonths);
          l.dueDate = LocalDate.now().plusMonths(1).withDayOfMonth(5).toString();
          event(l, u, "Full disbursement recorded; amortising repayment schedule started.");
        }
      }
      default -> throw new IllegalArgumentException("Unknown case action.");
    }
    loans.saveAndFlush(l);
    return detail(l);
  }

  @Transactional
  LoanPayment requestPayment(String id, User u, LoanController.PaymentRequest input) {
    Loan l = access(id, u, true);
    borrower(l, u);
    var existing = payments.findByLoanIdAndIdempotencyKey(id, input.idempotencyKey());
    if (existing.isPresent()) {
      LoanPayment p = existing.get();
      if (p.requestedAmount.compareTo(input.amount()) != 0
          || !p.kind.equals(input.kind())
          || !p.mode.equals(input.mode()))
        throw new ResponseStatusException(
            HttpStatus.CONFLICT,
            "This request key was already used with different payment details.");
      return p;
    }
    if (!(l.stage.equals("ACTIVE") && !input.kind().equals("PRE_EMI"))
        && !(l.stage.equals("DISBURSEMENT")
            && l.disbursed.signum() > 0
            && input.kind().equals("PRE_EMI")))
      throw new IllegalArgumentException(
          "Choose EMI or prepayment for an active loan, or pre-EMI for a partially disbursed"
              + " loan.");
    if (l.dueDate == null && input.kind().equals("PRE_EMI"))
      l.dueDate = LocalDate.now().plusMonths(1).withDayOfMonth(5).toString();
    if (!input.kind().equals("PREPAYMENT")
        && payments.findByLoanIdOrderByCreatedAtDesc(id).stream()
            .anyMatch(p -> p.kind.equals(input.kind()) && p.status.equals("PENDING")))
      throw new IllegalArgumentException(
          "A request for this payment cycle is already pending. Confirm or cancel it first.");
    if (input.kind().equals("PRE_EMI")
        && input
                .amount()
                .compareTo(
                    RepaymentEngine.money(
                        l.outstanding
                            .multiply(l.annualRate)
                            .divide(new BigDecimal("1200"), 12, RoundingMode.HALF_UP)))
            != 0)
      throw new IllegalArgumentException(
          "Pre-EMI must match estimated monthly interest on the disbursed balance.");
    if (input.kind().equals("EMI") && input.amount().compareTo(l.emi) != 0)
      throw new IllegalArgumentException("EMI request amount must match the current EMI.");
    if (input.kind().equals("PREPAYMENT") && input.amount().compareTo(l.outstanding) > 0)
      throw new IllegalArgumentException("Prepayment cannot exceed outstanding principal.");
    LoanPayment p = new LoanPayment();
    p.loanId = id;
    p.amount = input.amount();
    p.requestedAmount = input.amount();
    p.dueDate = input.kind().equals("PREPAYMENT") ? null : l.dueDate;
    p.kind = input.kind();
    p.mode = input.mode();
    p.idempotencyKey = input.idempotencyKey();
    payments.save(p);
    event(
        l,
        u,
        "Applicant requested "
            + p.kind
            + " of ₹"
            + p.amount
            + ". Awaiting officer confirmation; no money moved.");
    return p;
  }

  @Transactional
  Map<String, Object> cancelPayment(String id, String paymentId, User u) {
    Loan l = access(id, u, true);
    LoanPayment p =
        payments
            .findById(paymentId)
            .filter(x -> x.loanId.equals(id))
            .orElseThrow(() -> new IllegalArgumentException("Payment request not found."));
    if (!p.status.equals("PENDING"))
      throw new IllegalArgumentException("Only pending requests can be cancelled.");
    p.status = "CANCELLED";
    payments.save(p);
    event(l, u, "Pending sandbox payment request cancelled.");
    loans.saveAndFlush(l);
    return detail(l);
  }

  @Transactional
  Map<String, Object> confirm(String id, String paymentId, User u, String reference) {
    officer(u);
    Loan l = access(id, u, true);
    LoanPayment p =
        payments
            .findById(paymentId)
            .filter(x -> x.loanId.equals(id))
            .orElseThrow(() -> new IllegalArgumentException("Payment request not found."));
    if (p.status.equals("CONFIRMED")) return detail(l);
    if (!p.status.equals("PENDING"))
      throw new IllegalArgumentException("Only pending requests can be confirmed.");
    if (!(l.stage.equals("ACTIVE") && !p.kind.equals("PRE_EMI"))
        && !(l.stage.equals("DISBURSEMENT") && p.kind.equals("PRE_EMI")))
      throw new IllegalArgumentException(
          "The payment type does not match the current loan stage. Cancel and submit a revised"
              + " request.");
    if (!p.kind.equals("PREPAYMENT") && !Objects.equals(p.dueDate, l.dueDate))
      throw new IllegalArgumentException(
          "The payment cycle changed. Cancel and submit a revised request.");
    if (reference == null || reference.trim().length() < 4 || reference.length() > 100)
      throw new IllegalArgumentException("A sandbox payment reference is required.");
    if (p.kind.equals("PRE_EMI")) {
      BigDecimal interest =
          RepaymentEngine.money(
              l.outstanding
                  .multiply(l.annualRate)
                  .divide(new BigDecimal("1200"), 12, RoundingMode.HALF_UP));
      if (p.amount.compareTo(interest) != 0)
        throw new IllegalArgumentException(
            "Disbursed balance changed. Cancel and submit the revised pre-EMI.");
      l.paidInterest = l.paidInterest.add(interest);
      l.dueDate = LocalDate.parse(l.dueDate).plusMonths(1).toString();
    } else if (p.kind.equals("EMI")) {
      if (p.amount.compareTo(l.emi) != 0)
        throw new IllegalArgumentException("The EMI changed. Cancel and submit a revised request.");
      BigDecimal interest =
          RepaymentEngine.money(
              l.outstanding
                  .multiply(l.annualRate)
                  .divide(new BigDecimal("1200"), 12, RoundingMode.HALF_UP));
      if (p.amount.compareTo(interest) <= 0)
        throw new IllegalArgumentException("EMI does not cover monthly interest.");
      BigDecimal principal = p.amount.subtract(interest).min(l.outstanding);
      l.outstanding = l.outstanding.subtract(principal);
      l.paidPrincipal = l.paidPrincipal.add(principal);
      l.paidInterest = l.paidInterest.add(interest);
      p.amount = principal.add(interest);
      l.remainingMonths = Math.max(0, l.remainingMonths - 1);
      l.dueDate = LocalDate.parse(l.dueDate).plusMonths(1).toString();
    } else {
      if (p.amount.compareTo(l.outstanding) > 0)
        throw new IllegalArgumentException(
            "Payment now exceeds outstanding principal. Submit a revised request.");
      l.outstanding = l.outstanding.subtract(p.amount);
      l.paidPrincipal = l.paidPrincipal.add(p.amount);
      if (l.outstanding.signum() > 0) {
        if (p.mode.equals("EMI"))
          l.emi = engine.emi(l.outstanding, l.annualRate, Math.max(1, l.remainingMonths));
        else {
          double r = l.annualRate.doubleValue() / 1200;
          double months =
              r == 0
                  ? l.outstanding.doubleValue() / l.emi.doubleValue()
                  : -Math.log(1 - l.outstanding.doubleValue() * r / l.emi.doubleValue())
                      / Math.log(1 + r);
          l.remainingMonths = (int) Math.ceil(months);
        }
      }
    }
    if (l.outstanding.signum() == 0) {
      l.stage = "CLOSED";
      l.remainingMonths = 0;
      l.emi = BigDecimal.ZERO;
      event(
          l,
          u,
          "Loan principal repaid. Obtain the lender's closure certificate and return of property"
              + " documents.");
    }
    p.status = "CONFIRMED";
    p.reference = reference;
    p.confirmedAt = Instant.now().toString();
    payments.save(p);
    event(
        l,
        u,
        "Sandbox payment confirmed: "
            + p.kind
            + " ₹"
            + p.amount
            + "; reference "
            + reference
            + ".");
    loans.saveAndFlush(l);
    return detail(l);
  }
}
