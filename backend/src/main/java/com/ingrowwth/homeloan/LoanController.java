package com.ingrowwth.homeloan;

import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import java.math.*;
import java.nio.file.*;
import java.util.*;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.security.core.Authentication;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

@RestController
@RequestMapping("/api")
class LoanController {
  final LoanService service;
  final Path storage;

  LoanController(LoanService s, @Value("${app.documents}") String directory) {
    service = s;
    storage = Path.of(directory).toAbsolutePath().normalize();
  }

  record Application(
      @NotBlank @Size(min = 2, max = 100) String applicantName,
      @Email @NotBlank @Size(max = 254) String email,
      @NotBlank @Size(max = 100) String city,
      @Pattern(regexp = "SALARIED|SELF_EMPLOYED") @NotNull String employment,
      @Pattern(regexp = "PURCHASE|CONSTRUCTION") @NotNull String purpose,
      @NotBlank @Size(max = 500) String propertyAddress,
      @Size(max = 100) String coApplicant,
      @NotNull @DecimalMin("1") @DecimalMax("10000000") BigDecimal income,
      @NotNull @DecimalMin("0") @DecimalMax("10000000") BigDecimal coIncome,
      @NotNull @DecimalMin("0") @DecimalMax("10000000") BigDecimal obligations,
      @NotNull @DecimalMin("10000") @DecimalMax("1000000000") BigDecimal propertyValue,
      @NotNull @DecimalMin("10000") @DecimalMax("1000000000") BigDecimal requestedAmount,
      @NotNull @DecimalMin("0") @DecimalMax("30") BigDecimal annualRate,
      @Min(12) @Max(360) int tenureMonths) {}

  record Action(
      @NotBlank String action,
      long revision,
      @Size(max = 1000) String note,
      String targetId,
      BigDecimal amount) {}

  record PaymentRequest(
      @NotNull @DecimalMin("0.01") @DecimalMax("1000000000") @Digits(integer = 10, fraction = 2)
          BigDecimal amount,
      @NotNull @Pattern(regexp = "EMI|PRE_EMI|PREPAYMENT") String kind,
      @NotNull @Pattern(regexp = "TENURE|EMI") String mode,
      @NotBlank @Size(min = 8, max = 100) String idempotencyKey) {}

  record Confirmation(@NotBlank @Size(min = 4, max = 100) String reference) {}

  @GetMapping("/loans")
  Object list(Authentication a) {
    User u = service.user(a);
    return u.role.equals("OFFICER")
        ? service.loanRepo().findAllByOrderByCreatedAtDesc()
        : service.loanRepo().findByBorrowerIdOrderByCreatedAtDesc(u.id);
  }

  @GetMapping("/loans/{id}")
  Object detail(@PathVariable String id, Authentication a) {
    return service.detail(service.access(id, service.user(a), false));
  }

  @PostMapping("/loans")
  @Transactional
  Object create(@Valid @RequestBody Application p, Authentication a) {
    User u = service.user(a);
    if (!u.role.equals("BORROWER"))
      throw new IllegalArgumentException("An applicant account is required to create a loan.");
    if (p.requestedAmount.compareTo(p.propertyValue) > 0)
      throw new IllegalArgumentException("Requested loan cannot exceed the property value.");
    if (p.coIncome.signum() > 0 && (p.coApplicant == null || p.coApplicant.isBlank()))
      throw new IllegalArgumentException(
          "A co-applicant name is required when co-applicant income is included.");
    Loan l = new Loan();
    l.borrowerId = u.id;
    l.applicantName = p.applicantName;
    l.email = p.email;
    l.city = p.city;
    l.employment = p.employment;
    l.purpose = p.purpose;
    l.propertyAddress = p.propertyAddress;
    l.coApplicant = p.coApplicant;
    l.income = p.income;
    l.coIncome = p.coIncome;
    l.obligations = p.obligations;
    l.propertyValue = p.propertyValue;
    l.requestedAmount = p.requestedAmount;
    l.annualRate = p.annualRate;
    l.tenureMonths = p.tenureMonths;
    service.loanRepo().save(l);
    service.event(l, u, "Draft application created by applicant.");
    return service.detail(l);
  }

  @PostMapping("/loans/{id}/actions")
  Object action(@PathVariable String id, @Valid @RequestBody Action p, Authentication a) {
    return service.action(id, service.user(a), p);
  }

  @PostMapping("/loans/{id}/payments")
  Object payment(@PathVariable String id, @Valid @RequestBody PaymentRequest p, Authentication a) {
    return service.requestPayment(id, service.user(a), p);
  }

  @PostMapping("/loans/{id}/payments/{paymentId}/confirm")
  Object confirm(
      @PathVariable String id,
      @PathVariable String paymentId,
      @Valid @RequestBody Confirmation p,
      Authentication a) {
    return service.confirm(id, paymentId, service.user(a), p.reference);
  }

  @PostMapping("/loans/{id}/payments/{paymentId}/cancel")
  Object cancel(@PathVariable String id, @PathVariable String paymentId, Authentication a) {
    return service.cancelPayment(id, paymentId, service.user(a));
  }

  @GetMapping(value = "/events", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
  SseEmitter events(Authentication a) {
    User u = service.user(a);
    return service.updates().connect(u.role.equals("OFFICER") ? "OFFICER" : u.id);
  }

  @PostMapping("/loans/{id}/documents")
  @Transactional
  Object upload(
      @PathVariable String id,
      @RequestParam String kind,
      @RequestParam long revision,
      @RequestParam MultipartFile file,
      Authentication a)
      throws Exception {
    User u = service.user(a);
    Loan l = service.access(id, u, true);
    service.borrower(l, u);
    service.revision(l, revision);
    if (!List.of("DRAFT", "SUBMITTED", "DOCUMENT_REVIEW", "CREDIT_REVIEW", "PROPERTY_REVIEW")
        .contains(l.stage))
      throw new IllegalArgumentException("Document uploads are closed after sanction.");
    if (!LoanService.DOCS.contains(kind) || file.isEmpty() || file.getSize() > 5 * 1024 * 1024)
      throw new IllegalArgumentException(
          "Choose a required document category and a non-empty file under 5 MB.");
    byte[] bytes = file.getBytes();
    String type;
    if (bytes.length >= 5
        && new String(bytes, 0, 5, java.nio.charset.StandardCharsets.US_ASCII).equals("%PDF-"))
      type = "application/pdf";
    else if (bytes.length >= 8
        && Arrays.equals(
            Arrays.copyOf(bytes, 8), new byte[] {(byte) 137, 80, 78, 71, 13, 10, 26, 10}))
      type = "image/png";
    else if (bytes.length >= 3
        && bytes[0] == (byte) 255
        && bytes[1] == (byte) 216
        && bytes[2] == (byte) 255) type = "image/jpeg";
    else throw new IllegalArgumentException("Only PDF, PNG and JPEG documents are supported.");
    LoanDocument d = new LoanDocument();
    d.loanId = id;
    d.kind = kind;
    d.filename =
        Objects.requireNonNullElse(file.getOriginalFilename(), "document")
            .replaceAll("[\\r\\n\\\"\\\\/]", "_");
    if (d.filename.length() > 150) d.filename = d.filename.substring(0, 150);
    d.contentType = type;
    d.storageKey = UUID.randomUUID().toString();
    Files.createDirectories(storage);
    Path target = storage.resolve(d.storageKey);
    Files.write(target, bytes, StandardOpenOption.CREATE_NEW);
    org.springframework.transaction.support.TransactionSynchronizationManager
        .registerSynchronization(
            new org.springframework.transaction.support.TransactionSynchronization() {
              public void afterCompletion(int status) {
                if (status != STATUS_COMMITTED)
                  try {
                    Files.deleteIfExists(target);
                  } catch (Exception ignored) {
                  }
              }
            });
    service.documentRepo().save(d);
    service.event(l, u, kind + " uploaded for officer verification.");
    service.loanRepo().saveAndFlush(l);
    return service.detail(l);
  }

  @GetMapping("/loans/{id}/documents/{documentId}")
  ResponseEntity<byte[]> download(
      @PathVariable String id, @PathVariable String documentId, Authentication a) throws Exception {
    service.access(id, service.user(a), false);
    LoanDocument d =
        service
            .documentRepo()
            .findById(documentId)
            .filter(x -> x.loanId.equals(id))
            .orElseThrow(() -> new IllegalArgumentException("Document not found."));
    return ResponseEntity.ok()
        .contentType(MediaType.parseMediaType(d.contentType))
        .header(
            "Content-Disposition",
            ContentDisposition.attachment()
                .filename(d.filename, java.nio.charset.StandardCharsets.UTF_8)
                .build()
                .toString())
        .header("Cache-Control", "private, no-store")
        .header("X-Content-Type-Options", "nosniff")
        .body(Files.readAllBytes(storage.resolve(d.storageKey)));
  }
}
