package com.ingrowwth.homeloan;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "app_users")
class User {
  @Id public String id = UUID.randomUUID().toString();
  public String email;
  public String displayName;
  @JsonIgnore public String passwordHash;
  public String role;
}

@Entity
@Table(name = "loans")
class Loan {
  @Id public String id = UUID.randomUUID().toString();
  public String borrowerId,
      applicantName,
      email,
      city,
      employment,
      purpose,
      propertyAddress,
      coApplicant;
  public BigDecimal income,
      coIncome,
      obligations,
      propertyValue,
      requestedAmount,
      sanctionedAmount = BigDecimal.ZERO,
      annualRate,
      disbursed = BigDecimal.ZERO,
      outstanding = BigDecimal.ZERO,
      emi = BigDecimal.ZERO,
      paidInterest = BigDecimal.ZERO,
      paidPrincipal = BigDecimal.ZERO;
  public int tenureMonths, remainingMonths;
  public String stage = "DRAFT";
  public boolean creditChecked,
      legalChecked,
      valuationChecked,
      sanctionAccepted,
      closureCertificate,
      originalsReturned,
      securityReleased;
  public String dueDate;
  public String updatedAt = Instant.now().toString();
  public String createdAt = Instant.now().toString();
  @Version public Long revision = 0L;
}

@Entity
@Table(name = "loan_documents")
class LoanDocument {
  @Id public String id = UUID.randomUUID().toString();
  public String loanId, kind, filename, contentType;
  @JsonIgnore public String storageKey;
  public boolean verified;
  public String uploadedAt = Instant.now().toString();
}

@Entity
@Table(name = "loan_events")
class LoanEvent {
  @Id public String id = UUID.randomUUID().toString();
  public String loanId, actorId, message;
  public String createdAt = Instant.now().toString();
}

@Entity
@Table(name = "loan_queries")
class LoanQuery {
  @Id public String id = UUID.randomUUID().toString();
  public String loanId, question, response;
  public boolean resolved;
}

@Entity
@Table(name = "loan_payments")
class LoanPayment {
  @Id public String id = UUID.randomUUID().toString();
  public String loanId;
  public BigDecimal amount, requestedAmount;
  public String dueDate;
  public String kind, mode, status = "PENDING", reference, idempotencyKey;
  public String createdAt = Instant.now().toString(), confirmedAt;
}
