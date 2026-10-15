# TRD: CashFlow

**Version:** 2.0 (14 Oct 2026) · **Status:** Approved by owner (14 Oct 2026) · **Companion to:** `doc/PRD.md` v2.0 (requirement IDs such as FR-E4 refer to it) · **Audience:** the owner, AI coding agents, any developer.

> **Hinglish:** Ye document batata hai ki app **kaise** banegi: kaunsi technology, kaunse packages, data kahan aur kaise save hoga, sync, security, reminders, payment, testing. PRD batata hai "kya banana hai", TRD batata hai "kaise banana hai".

**Sources merged:** TRD v1.0 (`D:\caseFlow\docs\TRD.md`), `docs/CashFlow_Master_Brief.md`, `docs/DESIGN_DECISIONS.md`, PRD v2.0, and the current repo (T00 done).

**Rules**
- **[Changed]** / **[New]** / **[Removed]** mark differences from TRD v1.0.
- **[Verify]** = must be checked against the current official docs before coding that part. Never guess.
- **[Approval]** = a package or service that the owner must approve before it is added (CLAUDE.md: ask before adding any package).
- If this TRD and the PRD disagree, stop and ask the owner.

---

## 1. Architecture overview

> **Hinglish:** App pehle phone ke database mein likhti aur padhti hai (isliye offline chalti hai). Peeche se sync engine cloud (Supabase) se data bhejta aur laata hai. Reminders, device approval aur payment check server par chalte hain.

```
Flutter app (Android first, iOS in Release 2)
 ├─ UI layer: screens + shared widget library (Riverpod state, go_router navigation)
 ├─ Domain: calculation engine (money, EMI, totals), use cases
 ├─ Data: repositories
 │    ├─ Local DB: Drift (SQLite, encrypted)   ← UI reads only from here
 │    └─ Sync engine (outbox up, cursor down)  ←→  Supabase (Postgres + Auth + RLS)
 ├─ Device services: secure storage, app lock (PIN + fingerprint), local notifications,
 │    contacts, file export, billing
 └─ Firebase: FCM (push), Analytics + Crashlytics (no personal data)

Supabase server side
 ├─ Postgres: tables, RLS policies, triggers, RPC functions (atomic actions)
 ├─ Edge Functions: devices, email codes, reminders, purchase verification, account deletion
 └─ pg_cron (daily ~08:00 IST) → Edge Function → FCM → phone
```

**Principles**
1. **Local first.** The UI reads only from Drift; the network never blocks a screen (FR-S1).
2. **Cloud is the source of truth** after sync (FR-S3).
3. **The server enforces rules** (approved device, Premium, repayment limit); the app only mirrors them.
4. **One pattern everywhere:** every synced table has the same sync columns, RLS and indexes.
5. **Money is integer paise**, everywhere, always.
6. **Privacy by default:** no personal data in logs, analytics, crash reports or notifications (when hidden).

## 2. Current repo state (14 Oct 2026)

> **Hinglish:** Is naye project mein abhi sirf T00 (Flutter ka dhancha) bana hai. Owner ka faisla: **fresh start**. Purane project (`D:\caseFlow`) ka koi code, migration ya widget dobara use nahi hoga.

| Item | State |
|---|---|
| Flutter / Dart | **3.44.7 / 3.12.2** at `C:\flutter`, pinned in CI. **Owner decision (15 Oct 2026): stay on 3.44.7, no upgrade for now** (latest stable 3.47.7 exists). Upgrade only if the owner asks later |
| Project | `app/`, package id `com.pranjalpaghadal.cashflow` (dev: `.dev`) |
| Flavors | `dev` ("CashFlow Dev") and `prod` ("CashFlow"); entry points `lib/main_dev.dart`, `lib/main_prod.dart`, shared `bootstrap.dart`, `FlavorConfig` |
| Android | minSdk 24, target 36; `INTERNET` permission in the main manifest (release too); no backup: `allowBackup="false"`, `fullBackupContent="false"` (Android ≤ 11) and `dataExtractionRules` excluding all domains from cloud backup and device transfer (Android 12+, `res/xml/data_extraction_rules.xml`) |
| Folders | `lib/app`, `core/{config,theme,utils}`, `data/{local,remote,repositories}`, `features/*`, `l10n`, `shared/widgets` |
| CI | `.github/workflows/ci.yml` (pub get, analyze, test) |
| Packages | none added yet (all need owner approval) |
| Design | HTML mockups `design/screens/01–28`, logo `design/logo/` |
| Old project | `D:\caseFlow` is **not reused** (Q1, Q2). Its PRD/TRD v1.0 were only text sources for these documents. All migrations, SQL tests, theme and widgets are written fresh |

**Repo layout**

```
app/                 Flutter app
supabase/migrations  SQL migrations (only way to change the schema)
supabase/functions   Edge Functions (TypeScript, Deno)
supabase/tests       SQL tests for RLS and triggers
doc/                 PRD.md, TRD.md (this file)
docs/                Master brief, DESIGN_DECISIONS.md, PROGRESS.md
design/              HTML mockups and logo (visual reference only)
ui/                  old Stitch designs (reference only)
env/                 local secrets and dart-define files (never read by AI, never committed)
```

## 3. Technology stack

> **Hinglish:** Neeche har cheez ka naam aur kaam likha hai. Koi bhi package jodne se pehle owner se poochna hai. Versions coding ke waqt latest stable dekh kar pin karne hain.

### 3.1 App packages

| Purpose | Package | Notes |
|---|---|---|
| State management | `flutter_riverpod` (+ `riverpod_annotation`, `riverpod_generator` dev) | Decided [Approval] |
| Navigation | `go_router` | Decided; deep links from notifications [Approval] |
| Local database | `drift` + `drift_flutter`, `drift_dev` + `build_runner` (dev) | [Approval]. **Encryption: see 11.1 [Verify]** |
| Cloud SDK | `supabase_flutter` | Auth, Postgres, RPC, Functions [Approval] |
| Google login | `google_sign_in` | Native token → `signInWithIdToken` [Approval] |
| Secure storage | `flutter_secure_storage` | Android Keystore backed; DB key, PIN hash [Approval] |
| Fingerprint | `local_auth` | Strong biometric only (11.3) [Approval] |
| PIN hashing | a maintained pure-Dart crypto package with Argon2id or PBKDF2 (for example `cryptography`) | [Approval] [Verify] |
| Push | `firebase_core`, `firebase_messaging` | [Approval] |
| Local notifications | `flutter_local_notifications` (+ `timezone`) | [Approval] |
| Analytics / crashes | `firebase_analytics`, `firebase_crashlytics` | Opt-out toggle; no PII [Approval] |
| Billing | `in_app_purchase` | Server verification [Approval] |
| Contacts | `flutter_contacts` | Read on device only [Approval] |
| Localization | Flutter `gen-l10n` (ARB) + `intl` | `en_IN` number format |
| Charts | `fl_chart` | Donut, bars [Approval] |
| PDF / CSV | `pdf`, `csv` | Generated on the device [Approval] |
| Save / share file | a package that saves to Downloads (MediaStore) and `share_plus` | [Approval] [Verify] Android 10+ scoped storage |
| Connectivity | `connectivity_plus` | Offline bar (FR-S8) [Approval] |
| Device name | `device_info_plus` | "Redmi Note 12 · Android 13" in device approval [Approval] |
| UI preferences | `shared_preferences` | Language, theme, reduce glass: **not** in the wiped DB [Approval] |
| Haptics, animation | Flutter SDK only (`HapticFeedback`, implicit/explicit animations) | No extra package |
| Squircle corners | Flutter SDK `RoundedSuperellipseBorder` | [Verify] available in 3.44 |
| Fonts | Inter (400/500/600/700), Noto Sans Devanagari and Noto Sans Gujarati (400/600), bundled in assets | No runtime font download |
| Ads (later) | `google_mobile_ads` behind `ads_enabled` | Not in Release 1 [Approval] |

**Rule:** do not add any other package without asking the owner. Pin exact versions in `pubspec.yaml` and commit `pubspec.lock`.

### 3.2 Server and services

| Purpose | Choice | Notes |
|---|---|---|
| Backend | **Supabase**, region **Mumbai (ap-south-1)** (H1) | Two projects: `dev` and `prod`. AI agents use **dev only** |
| Database | Postgres + RLS + triggers + RPC functions | Schema only through migration files |
| Server code | Supabase Edge Functions (TypeScript / Deno) | Use service role only inside functions |
| Scheduler | `pg_cron` + `pg_net` | Daily jobs (reminders, subscription check, cleanup) |
| Push | Firebase Cloud Messaging HTTP v1 | Service account only in Supabase secrets |
| Email codes | SMTP from a dedicated Gmail (app password) for now | Spam risk accepted; domain sender before wide launch |
| Billing check | Google Play Developer API | Service account in Supabase secrets |
| Backup | GitHub Actions weekly `pg_dump` (H3) | **Encrypted** before storing (section 13.4) |
| Source control / CI | Private GitHub repo + GitHub Actions | Analyze, tests, migration checks |

## 4. Environments, config and secrets

- Flutter flavors `dev` / `prod` (done in T00). Config via `--dart-define-from-file=env/<flavor>.json` (Supabase URL and **anon** key only). `env/` is in `.gitignore`; AI agents never read it.
- **Never in the app or repo:** Supabase service-role key, FCM service account, Play API service account, SMTP password, backup encryption key. They live only in Supabase secrets or GitHub Actions secrets.
- Schema changes only through `supabase/migrations/NNNN_name.sql` in git, never by clicking in the dashboard.
- `prod` is touched only by the owner.

## 5. Data conventions

| Topic | Rule |
|---|---|
| Money | Integer **paise**: `bigint` in Postgres, `int` in Drift. Never `double` for stored money. Display with `NumberFormat.currency(locale: 'en_IN', symbol: '₹')` (₹1,20,000) |
| Interest rate | Basis points (12% = 1200) |
| IDs | UUID v4 generated on the device |
| Instants | `timestamptz`, UTC |
| Due dates | `date` (ISO `YYYY-MM-DD`, no time zone) so "15th" never shifts |
| Months, "today" | Computed from the IST local date (`Asia/Kolkata`) |
| Sync columns | `id`, `user_id`, `created_at`, `updated_at` (server trigger), `deleted_at`; local-only `is_synced` |
| Deletes | Soft delete only; hard purge is a later maintenance job (and on account deletion) |
| Enums | Text with check constraints (`kind`, `status`, `payment_mode`, `online_method`, `direction`, `bill_type`) |
| Payment | `payment_mode` = `cash` / `online`; `online_method` = `upi` / `card` / `bank` (default `upi`) |

**EMI integer math:** use `double` only inside the formula, round the EMI to whole paise once, and make the last installment the remainder so totals match exactly (reference: ₹7,996.39 × 11 + ₹7,996.40).

## 6. Data model

> **Hinglish:** Cloud aur phone dono mein same tables. Naye faislon ki wajah se kuch tables badli hain: recurring income hata, bills mein "har N mahine", udhar mein due-popup ka status.

### 6.1 Tables (cloud and phone)

| Table | Key columns | Change in v2.0 |
|---|---|---|
| `profiles` | name, language, opening_cash, opening_online, default_reminder, hide_amounts, analytics_opt_in, onboarding_done | — |
| `categories` | kind (income/expense), name, icon, color, is_default, last_used_at | [Changed] `icon`, `color`, `last_used_at` for the picker (F5) |
| `people` | name, phone_normalized (E.164), contact_cache_id (local only) | — |
| `transactions` | kind (income/expense), amount, title, category_id, occurred_at, payment_mode, online_method, note, source (manual/emi/bill/repayment), source_id | [Changed] `source`, `source_id` link EMI/bill payments |
| `debts` | person_id, direction (lent/borrowed), amount, occurred_at, payment_mode, online_method, note, due_date (Premium), reminder_days (Premium), status (open/partial/settled), extra_from_debt_id | [Changed] payment required (G1); `extra_from_debt_id` marks a debt created from an overpayment (G7) |
| `debt_payments` | debt_id, amount, occurred_at, payment_mode, online_method, note | Amount ≤ remaining (trigger, G8) |
| `debt_extensions` | debt_id, old_due_date, new_due_date | (G10) |
| `emis` | name, icon, lender, item_price, down_payment, loan_amount, rate_bp, months, emi_amount, first_due_date, status (active/closed) | [Changed] `first_due_date` replaces deduction day + start date |
| `emi_installments` | emi_id, seq, due_date, amount, interest_part, principal_part, status (due/paid), paid_at, transaction_id | [Changed] interest/principal parts (FR-E10) |
| `bills` | bill_type, name (provider), customer_id, every_months (1/2/3/6/12), next_due_date, usual_amount, reminder_days, paused | [Changed] (I3, FR-B3): replaces monthly/yearly, amount_varies, expected_amount |
| `bill_payments` | bill_id, due_date, amount, paid_at, transaction_id | Last 3 rows give the suggestion chips |
| `budgets` | monthly_limit, alert_enabled | One row per user |
| `budget_category_limits` | category_id, limit, alert_enabled | (FR-BG4) |
| `devices` | name, os_version, fcm_token, status (pending/approved/removed/blocked), session_id, approved_at, last_seen | [Changed] `blocked`, `os_version` |
| `device_requests` | device_id, purpose (approve_login / remove_device), target_device_id, code_hash, code_expires_at, attempts, expires_at, method (device/email), result | [Changed] `purpose` + `target_device_id` for lost-phone removal (J4, J5) |
| `subscriptions` | product_id, base_plan (monthly/yearly), status, intro_used, expires_at, purchase_token | [Changed] base plan (Q1) |
| `app_settings` | key, value (for example `ads_enabled`) | — |
| `notification_log` | user_id, item_kind, item_id, due_date, lead_days, sent_at | Unique key prevents duplicates |
| `recurring_income`, `income_receipts` | — | **[Removed]** (I1) |

**Phone-only tables (Drift):** `SyncOutbox`, `SyncCursors`, `PlanCache`, `AppFlags` (first-run hints, last payment method, recent searches, budget-alert sent flags). No foreign keys locally (parents may arrive after children).

**Not in the user database:** UI preferences (language, theme, reduce glass) in `shared_preferences`, so they work before login and survive logout (they contain no user data).

### 6.2 Indexes (minimum)

`(user_id, updated_at, id)` on every synced table; `(user_id, occurred_at)` on transactions and debts; `(user_id, due_date)` on debts, installments and bills (`next_due_date`); `(user_id, status)` on devices; search index on transactions and people (6.4).

### 6.3 Atomic actions (Postgres RPC functions, one transaction each)

| Function | Does | PRD |
|---|---|---|
| `mark_installment_paid(installment_id, txn)` | Creates the EMI expense + marks the installment paid + closes the EMI after the last one | FR-E7, FR-E11 |
| `unmark_installment_paid(installment_id)` | Reverses the above (soft-deletes the expense) | FR-E11 |
| `pay_bill(bill_id, due_date, amount, payment)` | Creates the Bills expense + `bill_payments` row + moves `next_due_date` by `every_months` | FR-B4 |
| `record_repayment(debt_id, amount, payment)` | Inserts a repayment capped at the remaining amount + updates status; returns the extra | FR-D3 |
| `add_extra_as_debt(from_debt_id, amount, direction)` | Creates the opposite-direction debt for the extra (only after "Yes") | G7 |
| `extend_due_date(debt_id, new_date)` | Updates due date + inserts `debt_extensions` | FR-D4 |

Every function above must first check that its target row exists and belongs to the caller, so no orphan expense is ever left.

### 6.4 Search (FR-C3)

Local only (works offline). Preferred: SQLite **FTS5** virtual table over transaction title, note, category name, and people name/phone; amount search by parsing digits. **[Verify]** that FTS5 is available in the encrypted SQLite build; fallback is indexed `LIKE` on a normalized lower-case column.

## 7. Calculation engine

All totals are Drift SQL aggregates (indexed), never Dart loops over all rows.

| Name | Formula |
|---|---|
| Monthly Net | Income − Expense − Lent + Borrowed + Repayments received − Repayments paid |
| Contact Net | (Lent − repayments received) − (Borrowed − repayments paid); positive = they owe the user |
| Balance end of month | Opening cash + online + all Monthly Net up to that month |
| Cash / online balance | Same formula filtered by `payment_mode` |
| Bill suggestions | Last 3 `bill_payments.amount` for the bill, newest first |
| Budget | Spent = expenses in month (udhar excluded); colour < 80% green, 80–99% orange, ≥ 100% red; per day = (limit − spent) ÷ days left |
| EMI | EMI = P·r·(1+r)^n / ((1+r)^n − 1), r = rate ÷ 12 ÷ 100; r = 0 → P ÷ n. Months from EMI: n = −ln(1 − P·r/EMI) / ln(1+r), rounded up, smaller last installment; EMI ≤ P·r → "not possible"; cap 600 months |
| Installment dates | Day 29/30/31 clamped to the month's last day |

Udhar is excluded from income, expense, charts and budgets unless "Include udhar" is on (Charts only).

## 8. Sync engine (FR-S1 to FR-S9)

**Write path**
1. Write the row to Drift **and** an outbox row (`op`, `table`, `row_id`, `batch_id`, `attempts`, `not_before`) in one Drift transaction.
2. UI updates from Drift streams immediately.
3. A background worker uploads the outbox in order.

**Upload**
- `upsert` by `id` (idempotent retries). Rows of one action share a `batch_id` and go in **one RPC call** (6.3).
- Backoff: 5 s, 30 s, 2 min … capped at 15 min. Auth error → stop and ask to log in. Validation error → "needs attention" list. `device_removed` error → **wipe** (section 10.4).
- **[New] Undo window (FR-H4, FR-E11):** a delete or mark-paid sets `not_before = now + 5 s` in the outbox. Undo within 5 s removes the outbox row and restores locally, so nothing reaches the server.

**Download**
- Per-table cursor `(updated_at, id)`, pages of 500, ordered by the pair. Empty cursor on a new device = full download (FR-S3).
- Each page applied in one Drift transaction; rows with `deleted_at` are deleted locally.
- Pull on app open, on return to foreground, after a successful upload, and on a data-less "sync" push.
- Parents uploaded before children; children whose parent is missing locally wait.

**Conflicts (FR-S6):** the server sets `updated_at = now()` on every write, so the last write to **reach the server** wins. Accepted for personal finance.

**Offline UI (FR-S8):** `connectivity_plus` + outbox count drive the grey bar "Offline · N changes saved on phone"; unsynced rows show a clock icon; after a successful sync a green toast.

## 9. Authentication and account (FR-A1 to FR-A5)

- **Google:** `google_sign_in` → ID token → `supabase.auth.signInWithIdToken`.
- **Email:** sign up with password; verify with a **6-digit OTP** that the user types and confirms with a Verify button (C3). **[Verify]** Supabase email OTP vs confirmation link settings.
- Session by `supabase_flutter` (auto refresh, tokens in secure storage).
- **Logout (FR-A2, J6) [Changed]:** in this order:
  1. Best effort: tell the server to clear this device's FCM token.
  2. `supabase.auth.signOut()`.
  3. Cancel all scheduled local notifications; delete the FCM token on the phone.
  4. Close and **delete the Drift database files** (including `-wal`, `-shm`) and any cache/temp/export-preview folders inside app storage.
  5. Delete **all** secure-storage keys (DB key, PIN hash, fingerprint flag, counters).
  6. Clear `AppFlags`; keep only UI preferences in `shared_preferences`.
  7. A test checks the app storage is empty of user data afterwards (NFR-14).
- **Delete account (FR-A3, J1) [Changed]:** online only. Typed "Delete" (case-insensitive) + PIN or fingerprint → Edge Function `delete_account` (verifies JWT and approved device) → deletes the auth user; all rows use `on delete cascade`; reminders stop; then the phone runs the logout wipe. Backups age out as described in 13.4.

## 10. Devices, approval and lost phone (FR-V1 to FR-V8)

> **Hinglish:** Naya phone tab tak kuch nahi dekh sakta jab tak purana phone "Yes" na bole ya email code na daala jaye. Server khud check karta hai. Kho gaye phone ko email code se sign out kiya ja sakta hai; wo jab internet se judega to apna data mita dega.

### 10.1 Login approval
1. After login the app calls Edge Function `register_device` (name and Android version from `device_info_plus`). No approved device on the account → approve at once (FR-V1). Otherwise `pending`.
2. Pending → FCM data message to every approved device. Tap → app unlock → popup "Was this you?" → `respond_device_request(yes/no)`. No → device `blocked`, session revoked.
3. No other phone → `send_email_code(purpose=approve_login)`: random 6-digit code, only its **hash** stored, 15-minute expiry, 5 attempts, sent by SMTP; `verify_email_code` approves.
4. Requests expire after 10 minutes (cleanup cron marks them `expired`).

### 10.2 Server enforcement (FR-V2, FR-V7)
SQL function `is_approved_session()` checks that the session id in the caller's JWT belongs to an `approved` row in `devices`; every RLS policy on user tables calls it, so a pending or removed device gets empty results. **[Verify]** that the `session_id` claim exists in the Supabase JWT for the SDK in use; otherwise use a custom claim from an auth hook.

### 10.3 Remove a device / lost phone [New] (J4, J5)
- Any removal needs an email code: `send_email_code(purpose=remove_device, target_device_id)` → `verify_email_code` → `remove_device` sets status `removed` and revokes that session through the admin API.
- After an email-code login, the app shows "Lost your old phone?" with the other approved devices (FR-V8).

### 10.4 Remote wipe on reconnect [New]
When a removed or blocked phone next calls the server, the session is invalid or `is_approved_session()` fails; Edge Functions and the sync worker return a distinct `device_removed` error. The app then runs the full **logout wipe** (section 9) and shows the welcome screen. Until it reconnects its data stays encrypted (11.1) behind the PIN.

## 11. Security on the phone

### 11.1 Encrypted database [Verify]
- Drift database encrypted with **SQLite3 Multiple Ciphers** (or SQLCipher). Current Drift docs (drift 2.32+, sqlite3 3.x) enable encryption through **build hooks / `hooks` options in `pubspec.yaml`**; the old `sqlcipher_flutter_libs` and `sqlite3_flutter_libs` packages must **not** be added. Follow the docs at the time of the task.
- Random 256-bit key on first run, stored in `flutter_secure_storage` (Android Keystore).
- Android backup off for the app (done in T00).
- **Proof on the real phone:** the DB file does not start with "SQLite format 3"; opening with a wrong key fails.

### 11.2 PIN (FR-L1, FR-L2, FR-L7–L9)
- 4 digits; Argon2id or PBKDF2 with a random salt; store `salt`, `hash`, `failed_attempts`, `locked_until` in secure storage.
- 5 failures → 30 s, doubling after more failures; counters persist across restarts.
- Forgot PIN: sign in again, set a new PIN; the device stays approved.

### 11.3 Fingerprint only [Changed] (C5, FR-L3)
- `local_auth`: offer only if the device supports **strong** biometrics and a **fingerprint** is available; `authenticate(biometricOnly: true)`; store only a boolean.
- Sensor present but no finger enrolled → "Set up fingerprint first" (open system settings or skip). No sensor → skip the screen.
- **[Verify]** how `getAvailableBiometrics()` reports fingerprint vs strong class on Android 13/14 (Realme), so face unlock is never used.

### 11.4 Lock behaviour
- `WidgetsBindingObserver` stores when the app went to background; on resume compare with "Lock after" (immediately / 1 min default / 5 min).
- `FLAG_SECURE` hides the app in recents (FR-L10). **[Verify]** that it does not block the in-app export preview.
- Rooted devices are out of scope.

## 12. Notifications and reminders (FR-R1 to FR-R6)

**Server path:** `pg_cron` daily ~08:00 IST → Edge Function `send_reminders`:
1. Finds items due today or at lead time (3/7 days) for users with an active plan: udhar with due dates, EMI installments, bills (skips `paused`).
2. Skips anything in `notification_log` (unique `user_id, item_kind, item_id, due_date, lead_days`).
3. Builds text in `profiles.language` (en/hi/gu templates); if `hide_amounts`, no amounts ("Open CashFlow to see details").
4. Sends FCM HTTP v1 high-priority messages.

**Local path:** after every sync the app schedules local notifications for upcoming items (backup when the push fails).

**No duplicates:** both paths display with the same **deterministic id** = hash(kind + item id + due date + lead days); a repeat replaces instead of adding.

**Android:** notification permission (Android 13+); reschedule after reboot; **[Verify]** exact-alarm rules on Android 14 (`SCHEDULE_EXACT_ALARM` needs user permission; prefer inexact alarms around 9 AM unless exactness is needed); in-app help "Reminders not coming?" for battery and auto-start settings (Realme).

**Due popups on app open (after unlock):** query Drift for due items with status pending and show one popup at a time: EMI "Paid or not?" (FR-E6), bill "Did you pay this bill?" (FR-B2), udhar "Did you get it? / Did you pay it back?" (FR-D11, Premium). "Not yet" stores a local "ask again after" = tomorrow.

**Budget alerts (FR-BG2):** computed **on the device** after each expense save; at 80% and 100% fire a local notification once per month per limit (`AppFlags`).

**Keep-alive:** the daily cron also prevents the free-plan inactivity pause. **[Verify]** current Supabase free-plan rules.

## 13. Subscription, plan enforcement and backups

### 13.1 Billing (FR-P1 to FR-P9)
- Play Console: one subscription product `premium` with base plans **monthly (₹20)** and **yearly (₹200)**, each with an intro offer **₹1 for 3 months**, once per account (Q1). **[Verify]** India minimum prices; fallback ₹10 intro or a free trial.
- Purchase with `in_app_purchase` → send the token to Edge Function `verify_purchase` → Google Play Developer API → write `subscriptions`.
- Daily cron re-checks active subscriptions (no real-time notifications in Release 1).
- Restore purchases (FR-P6); reminder 3 days before the first full charge (FR-P4, local + server).

### 13.2 Plan enforcement (server)
- SQL helper `has_active_plan(user_id)`.
- **RLS:** reads always allowed for the owner. Writes need a plan on `emis`, `emi_installments`, `bills`, `bill_payments`, `budgets`, `budget_category_limits`, and on `debts.due_date` / `debts.reminder_days` / `debt_extensions` [Changed] (G3). After a plan ends data stays readable, read-only.
- The app mirrors the plan from `PlanCache` to show locks and the paywall sheet.

### 13.3 Ads (later)
`app_settings.ads_enabled` read at startup; ads only for users without a plan, never on add/edit, popups, login, approval or paywall.

### 13.4 Backups [New] (H3)
- Supabase Free has no daily backups: a GitHub Actions workflow runs a weekly `pg_dump` of **prod**, **encrypts** it (for example with `age` and a key kept only in GitHub secrets), and stores it in a private location; keep the last 4 (so deleted accounts disappear within about a month at most; target 7 days when moving to Supabase Pro daily backups). **[Verify]** retention wording in the privacy policy.
- Move to Supabase Pro (daily backups, no pause) when real users depend on reminders.

## 14. UI implementation

> **Hinglish:** Pehle ek widget library (cards, buttons, glass bar, sheets, number pad) banegi aur ek gallery screen mein approve hogi, phir screens. HTML mockups sirf dekhne ke liye hain.

- **Theme tokens** from PRD FR-U1 in `core/theme` (`ColorScheme` + `ThemeExtension` for meaning colours: income, expense, lent, borrowed, due-soon, premium). Dark theme = proper black + glass (PRD FR-U10): one token table, two `ThemeData`s; a `GlassSurface` widget paints frosted glass in dark and a solid card in light or when glass is reduced. Dark tokens: `design/screens/dark/00_dark_tokens.html`.
- **Widget library** (`shared/widgets`) before screens: squircle card (`RoundedSuperellipseBorder`), amount text (never wraps, tabular figures, scales down), glass nav pill (`BackdropFilter` only here and the language bar), solid bottom sheet, solid number pad, chips, segmented control, toggle, compact snackbar (54 px, over sheets), swipe-to-reveal row (Edit/Delete, 60% threshold, confirm sheet), popup dialog, empty state, offline bar, Premium lock card, paywall sheet. A dev-only gallery screen shows all of them.
- **Glass fallback:** one blur layer at a time; "Reduce glass effects" or low-end detection → solid surfaces.
- **Animations:** short springs (≤ 350 ms), only transforms and opacity, `RepaintBoundary` on animated parts; respect `MediaQuery.disableAnimations`. Target ~60 fps on a mid-range phone.
- **Layout:** `SafeArea` and `MediaQuery.paddingOf` for notches and nav bars; works at 2.0× text scale; tap targets ≥ 48 dp.
- **Navigation (go_router):** `StatefulShellRoute` for the 4 tabs (Home, Contacts, Charts, EMI & Bills); Settings, Search, Budget, Export, Devices, Paywall as pushed routes; notification taps deep-link to the item and its popup.
- Mockups in `design/screens/` are a visual reference only; follow the PRD for behaviour.

## 15. Localization

- ARB files `app_en.arb`, `app_hi.arb`, `app_gu.arb`; no hardcoded strings; ICU plurals.
- Language picker lists 13 languages; only en/hi/gu are selectable, the others show "Coming soon" (C2).
- Money and digits always `en_IN` grouping with ₹ in all languages. "EMI" stays Latin script.
- Server texts (notifications, emails, PDF report) use `profiles.language`.

## 16. Export (FR-C2)

- Built on the device: `pdf` (summary, chart image, entries table; Noto fonts for Hindi/Gujarati) and `csv` (UTF-8 with BOM so Excel shows ₹ and Indian scripts).
- Saved to **Downloads** via MediaStore (Android 10+) [Verify]; Share via the system share sheet. The app never uploads the file.

## 17. Analytics and logging

- Firebase Analytics events only for screens and actions (for example `entry_added` with kind, never amount); Crashlytics with no custom keys containing personal data. Toggle "Share anonymous usage" turns both off.
- App logs: no amounts, names, phone numbers, notes, tokens or codes, in debug or release.

## 18. Error handling

- Repositories return typed results: success, offline, validation error, auth error, device_removed, plan_required.
- `plan_required` → paywall sheet (FR-P7). `device_removed` → wipe (10.4).
- Every network call has a timeout and the retry policy of section 8.
- Save buttons are never disabled; validation shows red borders and messages (F4).

## 19. Performance targets

- Screens open from Drift in under 1 s on a mid-range phone; lists use keyset paging.
- Totals by SQL aggregates; sync pages of 500 on a background isolate where possible; no heavy work on the UI thread.
- App start to lock screen under 2 s on the Realme test phone.

## 20. Testing

| Level | What |
|---|---|
| Unit | Money formatting (`en_IN`), IST month boundaries, EMI (12%/12 m → 7,996.39; EMI 8,500 → 12 months, last 2,112.98; 800 → not possible; 0% rate), day 29/30/31, bill next date (+N months), budget colours, PIN lockout, overpayment split |
| Widget | Amount never overflows, glass fallback, 48 dp targets, swipe thresholds, Save never disabled |
| Database (SQL) | RLS: cross-user (T-DB1), pending/removed device (T-DB2), plan writes incl. due date (T-DB3), repayment cap (T-DB4), `updated_at` trigger (T-DB5), atomic RPCs (T-DB6) |
| Sync | Two simulated devices, offline edits, deletes, same-timestamp rows, batch atomicity, undo window never uploads |
| Security | Logout leaves no user data (inspect app storage); wrong DB key fails; removed device wipes on reconnect |
| Integration | Login, first run, add data, new-device restore, approval by device and by email, lost-phone sign-out |
| Device (Realme, Android 13/14) | Battery saver, notifications, dark mode, 2.0× text, small screen, offline |
| Billing | Play test accounts: intro, monthly, yearly, renewal, cancel, restore, expiry |

CI (GitHub Actions): analyze, unit and widget tests on every push; migration lint; secrets scan. Releases go to the Play internal testing track first.

## 21. Owner answers (14 Oct 2026)

| # | Question | Answer |
|---|---|---|
| Q1 | Reuse the old project's Supabase work? | **No.** Fresh start: new migrations and SQL tests written from this TRD |
| Q2 | Reuse the old theme and widgets? | **No.** New widget library from the new design |
| Q3 | Upgrade Flutter to the newest stable? | First yes, then **changed on 15 Oct 2026: stay on 3.44.7** (pinned in CI). Revisit only if a needed package or Play rule requires it |

## 22. Traceability (PRD → TRD)

| PRD | TRD |
|---|---|
| FR-A (account, logout, delete) | 9 |
| FR-H, FR-O, FR-T (Home, entries) | 5, 6, 7, 14 |
| FR-D (udhar, overpayment, due popup) | 6.1, 6.3, 7, 12 |
| FR-E (EMI) | 6.1, 6.3, 7, 12 |
| FR-B (bills) | 6.1, 6.3, 7, 12 |
| FR-S (sync, offline) | 8 |
| FR-V (devices, lost phone) | 10 |
| FR-R (reminders) | 12 |
| FR-P, FR-X (billing, ads) | 13 |
| FR-L (app lock) | 11 |
| FR-BG, FR-C (budget, charts, export, search) | 6.4, 7, 12, 16 |
| FR-U (look and feel) | 14 |
| NFR | 11, 13.4, 17, 19, 20 |

## 23. Rules for AI coding agents

1. Read only the PRD/TRD sections named in the task; build only what they list. Follow the design ignore list (PRD 6.20).
2. Build and get approval for the widget library and gallery before screens.
3. Use the **dev** Supabase project only; schema changes only as migration files; never ask for production keys; never read `env/`.
4. Ask before adding any package or service; pin versions.
5. Money in integer paise; dates and sync columns per section 5; no secrets in the app.
6. Check every **[Verify]** item against current official docs before coding it, and note the result in `docs/PROGRESS.md`.
7. One task at a time; run the tests; report in plain language with "How to check on your phone"; never claim something works unless it was run.

---

### Change log

| Version | Date | Change |
|---|---|---|
| 1.0 | Oct 2026 | Final build baseline (old project) |
| 2.0 | 14 Oct 2026 | Owner answered Q1–Q3 (fresh start, no reuse, Flutter upgrade) and approved. Updated for PRD v2.0: current repo state; full package list with approvals; recurring income removed; new bills model (every N months, suggestions, pause); udhar due date as Premium in RLS; overpayment RPCs; installment interest parts; undo window in sync; full logout wipe; lost-phone removal with email code and remote wipe on reconnect; fingerprint only; monthly + yearly plans; encrypted weekly backups; search with FTS5; local budget alerts; UI implementation rules |
