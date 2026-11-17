# SAPS case desk: what the backend owner needs to provide

The screens are finished and run on demo data (`lib/services/saps/saps_mock_backend.dart`).
To connect the real backend, write two classes and swap them in `lib/main_saps.dart` (the two lines marked `BACKEND`).
No screen code changes.

## 1. `SapsAuthService` (lib/services/saps/saps_auth_service.dart)
| Method | What it must do |
|---|---|
| `signIn(email, password)` | Sign in. If the account is NOT an officer, sign out and return `notAuthorised`. Return `needsCode` if a verification code is still required, otherwise `ok`. |
| `verifyCode(code)` | True if the 6-digit code is right. |
| `isFullyAuthorised()` | True only for a restored session that is an officer and finished any code step. |
| `profile()` | Officer name and station for the header. |
| `signOut()` | Sign out. |
| `signedOut` (stream) | Emit when the officer is signed out for any reason. |

## 2. `SapsCaseService` (lib/services/saps/saps_case_service.dart)
| Member | What it must do |
|---|---|
| `cases` | Put the full list of cases here whenever anything changes. |
| `connected`, `lastUpdated`, `loadError` | Header status. |
| `announceNewSos(case)` | Call once when a NEW active SOS appears after the first load (banner and sound). |
| `start()` / `stop()` / `refresh()` | Load, subscribe to live changes, clean up. |
| `setStatus(case, status, reason)` | Change status and record who did it and why. |
| `logOpened(case)` | Record that an officer opened a case. |
| `audit(case)` | Who did what, newest first. |

## 3. The case shape (`SapsCase.fromMap` reads these keys)
`id, kind ('sos'|'report'), title, description, area, lat, lng, status, created_at, reporter_name, reporter_phone, battery`

Statuses: reports `pending, verified, resolved, rejected`. SOS `active, responding, resolved, false_alarm, cancelled`.
Anonymous reports must send `reporter_name` and `reporter_phone` as null.

## Rules
- Only officers may read cases. Enforce this in the database, not in the app.
- Officers must not edit or delete the audit log.
- A Supabase starting point is in `supabase/handoff/` (SQL and `supabase_backend.dart.txt`). It assumes table names that may differ from yours.
