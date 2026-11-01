# InGrowwth Home Finance

A working home-loan portfolio product with a Java banking service, a Next.js borrower/officer workspace, a Flutter Android/iOS companion, and persistent relational data. This is the deeper implementation requested after the first hosted prototype.

## What works

- Borrower registration and sign-in; separate officer accounts; server-side ownership checks, password hashing, session cookies and CSRF protection.
- Draft application → submission → document verification → credit review → legal and valuation reviews → manual sanction → applicant acceptance → staged disbursement → repayment → closure.
- Private document upload/download, applicant clarifications, review rationales, optimistic revision checks, and an application event history.
- Live server-sent updates scoped to the borrower and lending officers.
- Sandbox EMI, construction pre-EMI, and principal-prepayment requests. Officer confirmation changes the ledger; cancellation, idempotency, payment-cycle checks and transaction locks protect against duplicate/stale posting.
- Interest/principal breakdowns, monthly and annual extras, one-time prepayments, tenure versus EMI reduction, rate-reset scenarios, refinancing fees and break-even analysis, budget headroom and a user-selected cash reserve.
- Full monthly repayment schedules with CSV export. Closure tasks separately track the certificate, original documents and release of security.
- Flutter companion: shared sign-in and loan data, live refresh, applicant responses, payment requests, and a repayment comparison. Account creation, application entry and protected document upload remain in the web workspace.

## Local preview

For the employee PAN Fetch flow backed by **SQLite**, run `./scripts/start-employee.ps1` on Windows. See [SQLite setup, architecture, and client demonstration](docs/SQLITE-PAN-SETUP.md) for database configuration, preloaded PANs, Flutter connection, and inspection steps. This uses the standalone employee Java entry point; the borrower preview below uses its separate database configuration.

Run `./scripts/start-local.sh` from this project. It discovers the workspace-local Java 21 and Maven runtimes where available, or uses Java 21/Maven from your environment. Node 22+ and `npm` are required. The first Maven/npm run needs network access.

Open **http://127.0.0.1:3001**. The Java service runs on **http://127.0.0.1:8080**.

Local demo accounts only:

| Role | Email | Password |
|---|---|---|
| Borrower | borrower@demo.ingrowwth | DemoHome!2026 |
| Lending officer | officer@demo.ingrowwth | DemoHome!2026 |
| Separate borrower | second@demo.ingrowwth | DemoHome!2026 |

The `local` profile seeds these accounts once in an empty database. `DEMO_PASSWORD` can override the password before first startup. H2 stores local data at `backend/.data/homefinance.mv.db`; private files live in `backend/.data/documents`. Both survive application restarts. Never use local credentials for a public environment.

For Flutter, from `mobile/`, run `flutter pub get` then `flutter run --dart-define=API_URL=http://127.0.0.1:8080` on the iOS simulator. Android emulator uses `http://10.0.2.2:8080`. A physical device needs an accessible HTTPS API. The local Java profile binds to loopback. Android permits local HTTP only in its debug manifest; release expects HTTPS. Session credentials remain in memory and require sign-in after reopening.

Flutter includes the generated Swift iOS runner. A separate SwiftUI app is not included. iOS/Android release builds require their platform SDKs.

## PostgreSQL and HTTPS deployment

`compose.yml` supplies PostgreSQL 17, Java 21, Next.js, persistent database/document volumes, and a Caddy HTTPS gateway. Copy `.env.example` to `.env`, replace the database password and public hostname, configure the domain to your host, and run `docker compose up --build -d`. Only the gateway exposes public ports. This deployment template has not been executed here because Docker is unavailable.

The `prod` profile does not seed demo users. Provision the first officer once through the explicit bootstrap profile:

```sh
# Set OFFICER_EMAIL and OFFICER_PASSWORD in your shell/secret manager first.
docker compose run --rm -e SPRING_PROFILES_ACTIVE=prod,bootstrap \
  -e OFFICER_EMAIL -e OFFICER_PASSWORD backend
```

The bootstrap process exits after creating a new officer and refuses to elevate an existing borrower. Keep `bootstrap` out of the normal service profile. Borrowers use public registration. Point Flutter's `API_URL` to the same HTTPS hostname as the web app.

The original `chatgpt.site` prototype remains a separate deployment. Its runtime cannot run this Java service. This application needs a Java/container-capable host; no new public deployment has been made.

## Verification

```sh
cd backend && mvn test
cd ../web && npm run typecheck && npm run build
cd ../mobile && flutter analyze && flutter test
cd .. && python3 tests/loan_journey.py
TEST_API_URL=http://127.0.0.1:3001 python3 tests/loan_journey.py
```

The integration test creates a separate test borrower and completes a loan, including uploaded test documents, manual reviews, staged disbursement, pre-EMI, EMI, duplicate requests, cancellation, prepayment and closure. It intentionally persists that test case in the local sandbox. `TEST_API_URL` selects direct Java or the web gateway.

## Portfolio scope and integration boundaries

Payments and disbursements are explicitly marked **sandbox** throughout the interfaces. No money moves. Credit-bureau, identity verification, property legal review, valuation, signed KFS/agreements and payment-network integrations are represented by manual records, not connected bank services. The repayment engine uses monthly reducing-balance interest and stated posting assumptions; it does not calculate lender-specific daily interest, taxes, insurance, arrears, penalties or loan APR. Confirmed payments are immutable and are not an accounting general ledger. Session state currently runs on a single application instance.

This code is a functioning portfolio sandbox, not a licensed lender or a production banking system. Public rollout needs the actual lender integrations, operating controls, recovery procedures, and deployment/security review.

UI direction uses the user's [UI UX Pro Max skill](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill), with the generated banking design system and workspace override. Guidance references [RBI floating-rate reset FAQ](https://www.rbi.org.in/commonman/Upload/English/FAQs/PDFs/FAQRFIR10012025.pdf), [RBI home-loan guidance](https://rbi.org.in/CommonPerson/english/scripts/FAQs.aspx?Id=701), and HDFC Bank's process/disbursement resources linked in the app. Lending policy and fees are not inferred or hardcoded as legal entitlement.
