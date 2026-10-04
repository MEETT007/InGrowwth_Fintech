# Verification record

- One-time officer bootstrap succeeds on an isolated temporary database and exits without seeding demo identities.
- Java 21 / Spring Boot 3.5.16 service starts and validates both Flyway migrations against the persistent local H2 database.
- Seven repayment tests pass: EMI formula, zero-rate payments, principal conservation, capped prepayment, tenure/EMI alternatives, invalid inputs, and floating-rate reset behaviour.
- The final local HTTP loan journey passes 122 checks through Java and 122 through the Next.js gateway, including actual SSE delivery to the borrower/officer and exclusion of a separate borrower.
- Persistence check passes after a real Java restart: loan balance, closure flags, history, payment records, document metadata and private file content are retained.
- Next.js 16.3.4 production compilation and TypeScript checks pass.
- Flutter 3.47.6 static analysis passes. Five tests pass: 375 × 812 interaction and stale-result disclosure, light/dark contrast, and 812 × 375 landscape with 200% text scaling and reduced motion in both themes. The actual Dart API client also passes session/CSRF, login, owned case reads, planner and logout against Java.
- Browser visual inspection could not run: Codex browser access reported that the admin-enforced policy could not be verified. No alternate browser automation was used to bypass it.
- PostgreSQL Docker deployment is configured but unexecuted; Docker is not installed.
- Android/iOS source scaffolds exist; release builds unverified. The iOS simulator SDK is absent. A separate SwiftUI front end is not built.
