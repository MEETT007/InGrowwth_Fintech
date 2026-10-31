# Employee portal: SQLite local demo

The employee portal reads every profile from `backend/.data/employee-demo.sqlite`. No SQLite installation or database server is needed: Maven supplies the embedded SQLite JDBC driver.

The dedicated EmployeePortal server starts with SQLite only: H2, JPA and Flyway auto-configuration are disabled for this entry point. The existing HomeFinance server and borrower modules remain available separately with their original database settings. The Flutter borrower journey is local and is unchanged. The old H2 file is preserved; it is never opened by EmployeePortal.

## Run each day

PowerShell terminal 1:

```powershell
cd 'C:\Ingrowwth Innovations\InGrowwth_Fintech\backend'
$env:JAVA_HOME = 'C:\Program Files\Java\jdk-21'
.\Start-EmployeePortal.ps1
```

Wait for `Started EmployeePortal`. Keep this terminal open. Stop any previous backend before starting another.

PowerShell terminal 2:

```powershell
cd 'C:\Ingrowwth Innovations\InGrowwth_Fintech\mobile'
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8080
```

Android emulator: use `flutter devices` to find its ID, then `flutter run -d YOUR_EMULATOR_ID --dart-define=API_BASE_URL=http://10.0.2.2:8080`. Local HTTP is enabled for Android debug builds. Physical phones require an accessible backend address and network configuration; the default server binds only to this computer.

## Demo

Employee mobile: **8200229099**. OTP: **123456**.

| Fictional customer | PAN | ID | Simulated score |
| --- | --- | --- | --- |
| Saurav Kumar Patel | QWERT1234L | CUS-1001 | 782 |
| Priya Sharma | PLMNO5678K | CUS-1002 | 715 |
| Rahul Mehta | ZXCVB9012M | CUS-1003 | 642 |

Search each PAN on the same page. Rahul deliberately has no home-loan record. Try ZZZZZ9999Z for not found or `123` for invalid input. Other valid mobile numbers keep the borrower journey.

Data and scores are entirely fictional. No government verification or credit bureau service is used. Static OTP authentication is for this local demonstration only. Employee APIs are active only in the local profile. Tokens expire after 30 minutes or backend restart; sign out and sign in again.

## Show stored data

Run in another PowerShell terminal; SQLite can be viewed while the backend runs:

```powershell
cd 'C:\Ingrowwth Innovations\InGrowwth_Fintech\backend'
$env:JAVA_HOME = 'C:\Program Files\Java\jdk-21'
.\Show-DemoCustomers.ps1
```

This reads the real SQLite database in read-only mode and shows IDs, fictional names, cities and simulated scores. For all fields, open `.data/employee-demo.sqlite` with a SQLite database viewer and inspect the six tables. Profile sections are stored as JSON columns linked by customer ID; PAN has its own unique indexed column and loans have a customer foreign key. The seed JSON is an initialization source, not an API response source.

## Database initialization and reset

The repository creates six tables from `src/main/resources/employee/schema.sql` and inserts the three profiles from `src/main/resources/employee/customers.json` inside a transaction. Primary keys, PAN uniqueness, foreign keys and the loan customer index enforce relationships. Foreign keys and a five-second busy timeout are enabled on every connection. Restarting skips existing customer IDs, so edits to saved profiles persist and seeds do not duplicate.

Schema creation uses additive `CREATE TABLE IF NOT EXISTS` statements. Future schema changes require an explicit migration; editing seed JSON does not update existing profiles.

To reset just this fictional employee database, stop the backend and any SQLite viewers, then **rename** `backend/.data/employee-demo.sqlite` to a timestamped backup. Start the backend to create a fresh file with the three seeds. Keep the backup until you have verified the new file. Never reset or delete `homefinance.mv.db` for employee data. The database path can be overridden with `--app.employee-database=PATH`.

## Show API calls and logs

Chrome: F12 -> Network -> Fetch/XHR -> search `pan-lookup` -> fetch a PAN -> inspect Headers, Payload and Response. Only show synthetic records. Network inspection exposes the demo request and token, so do not share raw captures as public logs.

The real flow is Flutter -> Spring Boot -> SQLite repository -> response DTO -> Flutter cards. No Flutter-side customer mapping exists. All searches independently query SQLite. Logs include request ID, HTTP method/path/status, masked PAN, validation result, SQLite SELECT, found/not found, customer ID and measured duration. Full PAN, contact details, profile responses and tokens are excluded. Match X-Request-ID with the requestId response field and backend logs.

Endpoints:

- POST /api/employee/demo-session — obtains a demo employee token.
- POST /api/employee/customers/pan-lookup — normalized exact PAN lookup.
- GET /api/employee/customers — limited ID/name list, employee token required.
- GET /api/employee/customers/{customerId} — complete profile, employee token required.
- GET /api/health — backend and SQLite connectivity status, no database path/credentials.

Status: 200 success, 400 invalid input, 401 missing/expired employee token, 404 absent profile, 500 database failure, 503 unhealthy database. Chrome calls use CORS for localhost origins. Debug Flutter logs show URL/status/duration; local backend logs show database activity.

## Checks

From backend: `..\.local\tools\apache-maven-3.9.11\bin\mvn.cmd "-Dmaven.repo.local=../.local/m2" test`.
From mobile: `flutter analyze` and `flutter test`.

Stop both servers with Ctrl+C when finished. No `web/` or deployment files are changed for this feature.

Direct equivalent of the startup script (from backend):

```powershell
..\.local\tools\apache-maven-3.9.11\bin\mvn.cmd "-Dmaven.repo.local=../.local/m2" "-Dapp.main-class=com.ingrowwth.homeloan.EmployeePortal" spring-boot:run
```

The original backend remains available with the same command without `-Dapp.main-class`. Run only one server on port 8080. The employee startup script uses the local demo profile from application.yml; do not run this demo authentication for real customer data.

## Verified in this workspace (31 October 2026)

- 11 backend tests passed, including SQLite persistence, restart/idempotent initialization, all three profiles, exact normalized lookup, invalid/not-found responses, authorization, list/detail endpoints, health, PAN uniqueness and foreign-key relationships.
- 32 Flutter tests passed; the optional live integration test is skipped in the normal suite.
- The live Flutter service test was run separately against EmployeePortal and passed for all three profiles over actual HTTP.
- Flutter analysis: no issues.
- Chrome web build and Android debug APK build succeeded.
- SQLite read-only viewer displayed exactly three stored customers while the server was running.
- Standalone startup was checked: no H2/Hikari, Hibernate or Flyway initialization.
- Phone and desktop rendering were checked through Flutter widget tests. Manual Chrome interactions and Android emulator/device runtime were not verified in this update.
- Verification server was stopped after testing. Existing borrower data and web/ were preserved.

To repeat the optional live Flutter test while the employee backend runs on 8080:

```powershell
cd 'C:\Ingrowwth Innovations\InGrowwth_Fintech\mobile'
flutter test test/employee_live_test.dart --dart-define=RUN_EMPLOYEE_LIVE=true --dart-define=API_BASE_URL=http://127.0.0.1:8080
```
