package com.ingrowwth.homeloan;

import jakarta.persistence.LockModeType;
import java.util.*;
import org.springframework.data.jpa.repository.*;

interface Users extends JpaRepository<User, String> {
  Optional<User> findByEmail(String email);
}

interface Loans extends JpaRepository<Loan, String> {
  List<Loan> findByBorrowerIdOrderByCreatedAtDesc(String id);

  List<Loan> findAllByOrderByCreatedAtDesc();

  @Lock(LockModeType.PESSIMISTIC_WRITE)
  @Query("select l from Loan l where l.id = :id")
  Optional<Loan> lock(String id);
}

interface Documents extends JpaRepository<LoanDocument, String> {
  List<LoanDocument> findByLoanId(String id);
}

interface Events extends JpaRepository<LoanEvent, String> {
  List<LoanEvent> findByLoanIdOrderByCreatedAtDesc(String id);
}

interface Queries extends JpaRepository<LoanQuery, String> {
  List<LoanQuery> findByLoanId(String id);
}

interface Payments extends JpaRepository<LoanPayment, String> {
  List<LoanPayment> findByLoanIdOrderByCreatedAtDesc(String id);

  Optional<LoanPayment> findByLoanIdAndIdempotencyKey(String id, String key);
}
