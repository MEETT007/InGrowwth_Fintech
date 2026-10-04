# InGrowwth Home Finance

## Product purpose

Help Indian households understand a home loan, navigate application and document reviews, track disbursement, and compare repayment options over the life of the loan. Lending staff receive a separate review workspace. The first local release is a working sandbox with synthetic records and manual external verification.

## Application lifecycle

DRAFT → SUBMITTED → DOCUMENT_REVIEW → CREDIT_REVIEW → PROPERTY_REVIEW → SANCTIONED → DISBURSEMENT → ACTIVE → CLOSED.

Borrowers submit their own applications and respond to queries. Officers verify documents and record reasoned manual decisions. Co-applicant information, purchase/construction purpose, property address, income, obligations, requested credit and own contribution are captured. Under-construction loans permit multiple tranches within sanctioned principal, with pre-EMI on disbursed principal. Full amortisation begins only when the officer marks full disbursement.

## Repayment lifecycle

Installments are generated from disbursed principal and annual rate; sandbox payment confirmation is recorded by an officer with an idempotency key and reference. Pending borrower requests do not reduce outstanding principal. A principal prepayment applies only after confirmation. Borrowers compare reducing the EMI versus shortening tenure, recurring additional principal payments, annual lump sums, rate-reset stress and refinance break-even. Simulations disclose fees and assumptions and never imply guaranteed savings.

## Roles and boundaries

Borrower owns applications; officer can review applications. All API access enforces role/ownership on the server. Registration always creates BORROWER. Local-only demo seeding creates sample borrowers and an officer; production does not seed identities. Sandbox disbursements, payment confirmations, credit and property reviews represent manual workflow entries, not external bank transfers, identity checks, credit-bureau queries or title certification.

## Research

- RBI floating-rate EMI FAQ (10 January 2025): https://www.rbi.org.in/commonman/Upload/English/FAQs/PDFs/FAQRFIR10012025.pdf
- RBI home-loan consumer guidance: https://rbi.org.in/CommonPerson/english/scripts/FAQs.aspx?Id=701
- HDFC home-loan process: https://homeloans.hdfc.bank.in/housing-loans/home-loans/home-loan-process
- HDFC staged disbursement guide: https://homeloans.hdfc.bank.in/blog/home-finance/disbursement-home-loan

Regulatory guidance informs education and disclosure, not a claim of compliance certification. Specific lender terms govern actual fees, reset options and servicing procedures.
