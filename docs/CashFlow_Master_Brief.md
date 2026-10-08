# CashFlow: Master Project Brief

**Version 1.0 · written 8 Oct 2026 · purpose:** one document that explains the whole project (what, why, how, current status, rules) so that any AI or person can understand it without other context. If this brief and a detailed document disagree, the detailed document wins (see section 0).

---

## 0. How to use this brief

**Reader instructions (for an AI):**
1. Read this brief fully first. Then read the detailed documents named below for the task at hand.
2. Build or advise **only** what these documents say. If something is unclear or two documents disagree, stop and ask the owner. Do not guess silently.
3. Never claim something works unless it was run. Report failures plainly.
4. The owner does not read code. Explain results in plain language (Hinglish or simple English), and give a short list of taps he can try on a real phone.

**Document map (detailed sources of truth):**

| File | Content |
|---|---|
| `docs/PRD.md` | Product requirements (Final v1.0). Requirement IDs such as FR-E4 |
| `docs/TRD.md` | Technical requirements (Final v1.0) |
| `supabase/migrations/0001_init.sql` (+ `0002…` proposal) | Cloud database schema, security rules, triggers, functions |
| `app/lib/data/local/tables.dart` | Phone database tables (Drift) |
| `AGENTS.md` | Rules for the AI coding agent (Antigravity) |
| `docs/TASK_PLAN.md` | Tasks T00 to T27 with acceptance criteria and tests |
| `docs/START_HERE.md` | Owner setup checklist |
| `docs/PROGRESS.md` | Running progress log written by the agent |
| `ui/` | Google Stitch design references (visual reference only) |

---

## 1. The project in one page

- **Name:** CashFlow. **What:** a mobile personal-finance app for India.
- **What the user can do:** record income and expenses; track money **lent** to and **borrowed** from people (per person, like Google Pay history, with due dates and partial repayments); track **EMIs** (loan installments) and **bills**; get **reminders** for due dates; see **charts**, set a **monthly budget**, **export** PDF/CSV reports; protect the app with a **PIN and fingerprint/face**; log in on a new phone and get all data back automatically, after approving the new device from the old one.
- **Platforms:** Android first (minimum Android 7, API 24). iOS later (Release 2). One Flutter codebase.
- **Languages:** English, Hindi, Gujarati. **Currency:** INR only (₹), Indian digit grouping (₹1,20,000).
- **Business model:** free plan plus a subscription (₹1 for the first 3 months, then ₹20/month or ₹200/year). Ads later for free users only.
- **Core promise:** never miss a due date; know exactly where money came from and where it went; works offline; private.

**Owner and constraints**
- Owner: Pranjal, a Flutter developer in India, working **solo**, acting as the **product owner** who directs an AI coding agent. He reviews **results on a real phone** (Realme, Android 13/14), not code.
- Budget: about **₹2,000 in total** for AI tooling, no repeat payment possible. Free tiers everywhere (Supabase Free, Firebase Spark).
- AI agent: **Antigravity**. Designs: **Google Stitch**. Planning and review: Claude.
- The Google Play Console account used to publish belongs to the owner's brother: ownership and payouts must be agreed in writing.

---

## 2. Basics in simple words (frontend, backend, server, database)

Think of a restaurant.
- **Frontend (Flutter app)** = the dining hall and menu. What the customer sees and taps.
- **Server** = the kitchen staff: a computer that is always on and connected to the internet, and does work when asked.
- **Database** = the storeroom and register: where information is stored safely and permanently.
- **Backend** = kitchen + storeroom together (server + database + login + rules).
- **API** = the waiter who carries requests between the hall and the kitchen.

**Why a backend is needed in CashFlow**
1. **Data must survive the phone.** A lost or changed phone must not lose records. The cloud database keeps a copy.
2. **Privacy and rules.** The server decides who may see which data (a user sees only their own, only from an approved device).
3. **Work that must happen when the phone is off.** Sending reminders on the due date needs a server and a scheduler.
4. **Trust.** Whether someone really paid for Premium must be checked by a server, not by the phone, or anyone could fake it.

**Example: user saves an expense of ₹2,450.** The app saves it in the phone's own encrypted database (instant, works offline) → later sends it over the internet → the server checks "is this the real user on an approved device?" → writes it to the cloud database → on a new phone, after login and approval, the server sends it back.

**CashFlow's parts:** Flutter = app UI. Drift (encrypted SQLite) = phone database. Supabase = backend as a service (Postgres database + login + security rules + server functions + scheduler). Edge Functions = small server programs (reminders, device approval, purchase check). Firebase Cloud Messaging (FCM) = the postman that delivers push notifications.

---

## 3. Users, goals, non-goals

**Users:** everyday people in India who lend and borrow informally, pay EMIs and yearly premiums, use UPI, and want reminders. They may prefer English, Hindi or Gujarati.

**Goals:** (G1) one place for all money in, out and owed; (G2) never miss a due date; (G3) fast, offline-first, automatic restore on a new device; (G4) safe: new logins need approval; (G5) sustainable through subscriptions.

**Non-goals (this release):** bank linking, SMS parsing or any automatic transaction import; automatic bill fetch from utilities (it needs a regulated bill-payment network partnership); shared ledgers or payment requests to other people; multiple currencies; web or desktop apps; receipt photo uploads; interest on personal loans; end-to-end encryption of cloud data.

---

## 4. Plans, pricing and the paywall

| Plan | Price | Access | Ads |
|---|---|---|---|
| Intro (once per Google account) | ₹1 for the first 3 months | Everything | No |
| Paid | ₹20/month or ₹200/year (yearly is 17% cheaper) | Everything | No |
| Free | ₹0 | Income, expense, categories, lend/borrow **without reminders** with per-person history, sync, device approval, app lock | Light ads, switched on later |

- **Paid-only:** reminders (lend/borrow, EMI, bills, recurring income), EMI, Bills, Recurring income, Budget, Charts, PDF/CSV export, transaction search. (The category search inside the add-entry form stays free.)
- Free users see EMI/Bills and Charts as **locked tabs** with a **Subscribe** button at the bottom.
- When a plan ends: the user becomes Free, **keeps all data**, reminders stop, paid screens become read-only.
- Billing uses **Google Play Billing** (Apple In-App Purchase in Release 2). Purchases are verified on the server; a **daily check** keeps status fresh. The store takes about 15% on subscriptions (verify the exact rate).
- Before purchase the app clearly shows "₹1 for 3 months, then ₹20/month" and reminds the user a few days before the first full charge.
- **To check in Play Console:** that the ₹1 intro price and ₹20 base price meet India's minimum price rules. Fallback: ₹10 or ₹20 intro, or a free trial.
- **Ads:** launch without ads. A remote switch `ads_enabled` (table `app_settings`) turns them on later, for free users only, never on add/edit screens, reminder popups, login or device approval, and never sharing financial data with ad SDKs.

---

## 5. Features in detail

### 5.1 First run and login
Welcome screen with language chip → login with **Google** or **email + password** (email must be verified) → create a **4-digit PIN** (twice) → optional fingerprint/face → **opening balance** (cash and online, may be 0; skippable) → **contacts permission** explainer → Home. The first device on an account is trusted automatically. Logout wipes local data and keys. Delete account removes all cloud data.

### 5.2 Home
Header: avatar (Google photo or first letter), name, **month picker**; all data on the screen follows the selected month. Summary card: big number = **Balance at the end of the month** (opening balance plus all monthly nets up to that month), four colour tiles (Income green, Expense red, Lent blue, Borrowed pink), and a row **Net this month**. Filter chips **All / Expense / Income** (selected chip takes its own colour). Section "Transactions" with count, grouped by day. Each card: icon tile, title, "date • category • payment method", note, amount (+green/−red), time. Floating **+** button opens a glass sheet with **Income** and **Expense**. The list shows only income and expense, not loans.

### 5.3 Add / edit income or expense
Fields: type switch (Expense red / Income green), amount, **title (optional; if empty the category is the title)**, **category** (picker with search; a new category typed once is **saved automatically** and found next time), date and time (default now), **payment mode** Cash or Online (Online may specify UPI, Card or Bank transfer), note. Defaults categories are provided in the user's language; income and expense categories are separate. Deleting asks confirmation in a glass sheet.

### 5.4 Contacts, people and udhar (lend/borrow)
Contacts tab, top to bottom: summary cards **To receive** (blue) and **To pay** (pink); the **5 most recent** people with activity; search; **all phone contacts** A–Z with a letter index. Tapping a contact opens **Person detail**: net card ("X owes you ₹3,000" or "You owe X"), buttons **Lent / Borrowed / Repayment**, history grouped by date, each loan with a progress bar ("₹2,000 of ₹5,000 repaid"), due-date tag and bell. A floating **+** opens a sheet with **Lent** and **Borrowed**. **Add Lent/Borrowed form:** person, amount, date, due date (optional), reminder chips 3 or 7 days before (**Premium**), payment mode, note.
- Partial repayments are separate records; status becomes open, partial or closed. A repayment can never exceed the remaining amount. The due date can be extended (history kept). No interest.
- **People:** permission is the normal contacts permission. Contacts are read **on the device**; only a contact **used in an entry** is saved to the cloud (name and normalized phone). Each person has the app's **own id**; the phone's contact id is only a local cache. The same number reuses the same person; a new phone matches people to its contacts by number.

### 5.5 EMI (Premium)
Add EMI: name, item price or loan amount, down payment (optional), yearly interest rate (reducing balance), deduction day, start date. The user then enters **either months or the EMI amount**; the other is calculated and both stay editable. The app generates all installments (day 29/30/31 is clamped to the month's last day; the first installment falls on the start date; the last installment is adjusted so totals are exact). EMI list shows progress ("4 of 12 paid, 8 left, ₹63,971 remaining") and a due tag. EMI detail lists installments (paid, due with **Mark paid**, upcoming). On the due date a reminder arrives and, when the app opens, a glass popup asks **"Paid or not?"**; **Paid** creates the expense and reduces the remaining count in one atomic action; **Not yet** asks again next open. The EMI closes after the last installment.

### 5.6 Bills and recurring income (Premium)
**Bills:** title, provider and customer ID (stored for reference only), amount, monthly or yearly, due day (and month), reminder lead time. A bill can be **"amount changes every month"**: the app shows an expected amount (average of the last 3 paid) and asks the actual amount at the due popup. **Recurring income** (salary etc.): amount, day, reminder, "Received or not?" popup creating the income entry. These share the EMI & Bills tab through a switch **EMIs | Bills | Income**.

### 5.7 Charts, budget, export, search (Premium)
**Charts:** spending donut by category; income vs expense bars for 6 months; toggle "Include loans" (off by default). **Budget:** one monthly overall limit plus per-category limits; bars are green under 80%, orange from 80 to 99%, red at 100% or more; alerts at 80% and 100%. **Export:** PDF or CSV for a date range, choosing what to include (income/expenses, lent/borrowed, EMI/bills), saved on the phone and shareable. **Search** across transactions and people.

### 5.8 Reminders
Lead time (3 or 7 days before, plus the due day) chosen per item. Delivery through a **server push** (daily scheduler, plan check, no duplicates) and **local notifications**; both use the same deterministic id so a repeat replaces instead of duplicating. Tapping opens the item. A help screen explains Android battery and auto-start settings (important on Realme and similar phones). Setting: hide amounts in notifications.

### 5.9 App lock
4-digit PIN stored only as a **salted slow hash** in secure storage. Optional biometric using whatever the phone offers (fingerprint or face); if none, PIN only; the app never sees biometric data. Every open and return after the chosen time (immediately, 1 minute default, 5 minutes) asks biometric first, PIN second. Wrong PIN: 5 failures give a 30-second lock, longer afterwards, and survives app restarts. Forgot PIN: sign in again with the account and set a new PIN. Recents preview can be hidden.

### 5.10 Device approval (new login safety)
A login on a new device stays **pending** and sees **no data**. The trusted device gets a notification "New login from [device]. Was this you?" with **Yes / No** (opens the app, which must be unlocked first). If no old device is available the user can approve with a **6-digit email code** (one-time, 15 minutes, 5 attempts). Pending requests expire after 10 minutes. Settings lists devices and lets the user remove any (signs it out). Enforcement is **on the server**, not only in the app.

### 5.11 Settings
Profile and plan card (Free shows Subscribe; Premium shows renewal date and Manage), language, theme (system/light/dark), default reminder, hide amounts in notifications, app lock (type, lock-after time), devices, anonymous analytics toggle, "Reduce glass effects", logout, delete account, version.

---

## 6. Calculation rules (single source for all totals)

All money is **integer paise**. A month is chosen by the entry's own date in **India time (IST)**. **Loans are not income or expense.**

| Name | Formula |
|---|---|
| Total Income / Expense | Sum of income / expense entries dated in the month |
| Total Lent / Borrowed | Sum of new lent / borrowed entries dated in the month |
| **Monthly Net** | Income − Expense − Lent + Borrowed + Repayments received − Repayments paid |
| **Contact Net** (per person, all time) | (Lent − repayments received) − (Borrowed − repayments paid). Positive = the person owes the user |
| **Balance (end of month)** | Opening balance (cash + online) + all Monthly Net values up to that month |

Repayments received are **Loan In**; repayments paid are **Loan Out**. Both change cash/online balances and Money in/out totals but are excluded from income, expense, charts and budgets unless "Include loans" is on. Cash and online balances are shown separately. Bill expected amount = average of the last 3 paid amounts.

**EMI (reducing balance):** EMI = P·r·(1+r)^n / ((1+r)^n − 1), r = yearly rate ÷ 12 ÷ 100; zero rate: EMI = P ÷ n. Months from a chosen EMI: n = −ln(1 − P·r/EMI) / ln(1+r), rounded up, with a smaller last installment; if EMI ≤ monthly interest, return "not possible" (cap 600 months).

**Reference numbers (use in tests):** loan ₹90,000, 12% a year, 12 months → EMI **₹7,996.39** (799,639 paise), total interest about ₹5,957, remaining after 4 paid about ₹63,971. Monthly Net: income 45,000, expense 28,500, lent 5,000, borrowed 2,000 → **13,500**. Contact Net: lent 5,000, repaid 2,000 → **3,000 to receive**. (An earlier note that said ₹7,995 was wrong.)

---

## 7. Design and screens

**Style:** minimal, premium, light and calm; white, light sky blue, baby pink. Tokens: page `#FAFCFF`, header tint `#E6F4FE`, brand sky blue `#5AB7F1` (dark variant `#2B8FD6`), pink `#FBDCE8` / deep pink `#C2477A`, green `#1FA971`, red `#E5484D`, blue `#3B8EEA`, orange warning `#F59E2B`, text `#1F2A37`, muted `#6B7C8F`. Font **Inter** (Noto Sans Devanagari and Gujarati bundled for Hindi and Gujarati). Light and dark themes.
**Colour meaning:** income green, expense red, lent blue, borrowed pink. Net is green when positive, red when negative.
**Shapes:** smooth continuous (squircle, Apple-like) corners; nested corners concentric; layouts adapt to screen size, notches and system bars.
**Glass:** frosted "liquid glass" **only** on the floating bottom bar and bottom sheets/popups. Money amounts always sit on solid surfaces. A "Reduce glass effects" setting gives a solid fallback. Amounts must never wrap or truncate.
**Bottom bar:** Home, Contacts, Charts, EMI, Settings (locks on paid tabs for free users).

**Screens and status:** Home, Add Expense, Add Income, category picker, Contacts, Person detail and Add Lent were designed and approved or accepted (Contacts re-designed to the new layout). Designs for EMI (list, detail, add, popup), Bills, Recurring income, Charts, Budget, Export, locked tabs, Settings, Devices and approval, Paywall, login, PIN, opening balance, contacts explainer and empty/system states have prompts ready and awaiting approval.
**Design workflow:** the owner generates screens in Stitch from prompts, shares screenshots for review, then the agent builds them in Flutter from the shared widget library. **Stitch output is a visual reference only.**
**Design ignore list (never build):** profile icon at the top right of any screen; duplicate titles; status dots on avatars; call button on Person detail; "Initiation", "Completed", "UPI Ref" labels; footer texts like "Calculated and backed up"; "Surplus" badges; "Budget Health" cards; quick actions; SMS or bill-sync; split-bill; tips and promotions.

---

## 8. Architecture and technology

| Layer | Choice |
|---|---|
| App | Flutter (Dart), state with **Riverpod**, routing with **go_router**, flavors `dev` and `prod` |
| Phone database | **Drift** (SQLite) with **encryption** (see section 12 for the current package decision) |
| Cloud | **Supabase** (Postgres, Auth, Edge Functions, pg_cron), region **Mumbai** |
| Login | Google (native) and email + password |
| Push | Firebase Cloud Messaging; local alerts with flutter_local_notifications |
| Billing | Google Play Billing with server verification |
| Analytics | Firebase Analytics + Crashlytics (never amounts, names, notes; user toggle) |
| Charts/PDF/CSV | fl_chart, pdf, csv |
| Contacts | flutter_contacts |
| Ads (later) | google_mobile_ads behind `ads_enabled` |

**Principles:** local-first (the UI reads only from the phone database); cloud is the source of truth; the server enforces rules; one pattern for every table.

**Data conventions:** money in integer paise (never double); IDs are UUIDs made on the device; instants in UTC; due dates as ISO `YYYY-MM-DD`; every synced table has `id, user_id, created_at, updated_at (server-set), deleted_at`; **soft delete only**.

**Sync:** writes go to the phone database and an **outbox** first, then upload with retries (idempotent upserts; actions that must succeed together are sent as one database call, for example `mark_due_paid`). Downloads fetch rows changed after a **cursor (updated_at, id)** in pages of 500; a new device starts with an empty cursor so everything downloads automatically. Conflicts: the last write to reach the server wins (accepted trade-off). Soft deletes tell other devices about removals.

**Encryption and privacy:** phone data is encrypted (key kept in secure storage, Android backup disabled for these files). Cloud data uses TLS and provider encryption at rest and is **not** end-to-end encrypted in this release (server reminders and easy restore need readable data). Contacts stay on the phone unless used in an entry. Logs, crash reports and analytics never contain amounts, names, numbers or notes.

**Reminders pipeline:** daily scheduler (about 08:00 IST) → Edge Function → checks plan, de-duplicates through a log, builds text in the user's language → FCM. Same notification id on the phone avoids duplicates.

**Device approval pipeline:** `devices` table with session-bound status; a database function checks the caller's session belongs to an approved device before any user data is returned; Edge Functions register, approve, deny, expire, email-code and remove. (To verify: that the Supabase access token carries the `session_id` claim.)

**Email sender:** no domain yet. For now a dedicated Gmail account with an app password sends approval codes (some mail may land in spam); a domain-based sender is needed before wide launch.

---

## 9. Data model

**Cloud (Supabase):** `profiles` (name, language, opening cash/online, default reminder, hide-amounts, analytics opt-in), `categories`, `people`, `transactions` (kind, amount, title, category, `occurred_at`, payment mode and method, note, source), `debts` (person, direction, amount, date, due date, reminder days), `debt_extensions`, `debt_payments`, `emis` (name, item price, down payment, loan amount, rate in basis points, months, EMI amount, due day, start date), `emi_installments`, `bills`, `bill_payments`, `recurring_income`, `income_receipts`, `budgets` (one row per user), `budget_category_limits`, `devices`, `device_requests`, `subscriptions`, `app_settings`, `notification_log`.

**Security rules (RLS):** owner only and approved device only; clients never hard-delete; on paid tables writes also need an active plan (reads stay open); debts allow setting a reminder only with a plan; `devices`, `device_requests`, `subscriptions`, `notification_log` are written only by server functions. Triggers: server sets `updated_at`; repayment above the debt is rejected; an EMI closes when its last installment is paid; a new user gets a profile and subscription row. Function `mark_due_paid` creates the entry and marks the installment, bill payment or income receipt in one transaction. A migration `0002` (proposal, not yet applied) adds checks so a missing target row cannot leave an orphan entry.

**Phone (Drift):** the same tables plus local-only `SyncOutbox`, `SyncCursors`, `PlanCache`, `AppFlags`. No foreign keys locally (parents may arrive after children during sync). UI preferences (language, theme, reduce glass) must survive logout and be readable before login, so they should not live in the user-data database that logout wipes.

---

## 10. Security checklist (summary)

Row Level Security on every table with tests; approved-device enforcement on the server; plan checks on the server; no secrets in the app or repo (service-role key, FCM, Play API and SMTP secrets only in Supabase secrets); work only on the **dev** Supabase project; rate limits and attempt counters on email codes and PIN; encrypted phone database; no sensitive data in logs; dependencies pinned; the owner never shares database passwords or production keys with the AI agent.

---

## 11. How the project is built

**Workflow:** one task at a time from `docs/TASK_PLAN.md`; the agent reads its task and the named PRD/TRD parts, builds, writes and runs tests, then reports in plain language with a "How to check on your phone" list; the owner tries it, then says "approved, next task". One git branch per task (`task/T04` …), merged only by the owner after approval. The agent must not run `git reset --hard`, delete branches, rewrite history, force-push, or touch files it did not create (`rules/`, `caseFloww/`, `ui/`, `env/`). `docs/PROGRESS.md` is updated after every task.

**Tasks:** Phase 0 setup (T00 skeleton, T01 Supabase database, T02 theme and widget library, T03 localization and utilities); Phase 1 foundation (T04 encrypted local database, T05 login, T06 app lock, T07 sync engine, T08 first run); Phase 2 core money (T09 calculation engine, T10 Home, T11 add/edit entries); Phase 3 udhar (T12 contacts and people, T13 Contacts screen, T14 person detail and udhar); Phase 4 (T15 EMI create, T16 EMI list/detail/popup, T17 bills and recurring income); Phase 5 (T18 local reminders, T19 reminder server, T20 device approval); Phase 6 (T21 subscription, T22 charts and budget, T23 export and search, T24 settings); Phase 7 (T25 compliance and polish, T26 full test pass and Play testing, T27 ads switch).

**Testing:** unit tests for money, dates and EMI; widget tests for the widget library (amounts never overflow, glass fallback, tap targets of at least 48dp); SQL tests for security rules (T-DB1 to T-DB6); sync tests with two simulated devices; integration tests on the real phone for encryption; billing tests with Play test accounts; manual checks on the Realme (offline, battery saver, dark mode, big fonts, small screens, notifications). The agent's own audit is not enough: the owner's phone checks and screenshots are the real review.

**Tools and accounts:** Flutter, Android Studio, Git, VS Code, Antigravity, Node and Supabase CLI; private GitHub repo; Supabase dev project; Firebase (free Spark plan, no upgrade to paid); Google Cloud OAuth for Google sign-in; Stitch; a dedicated Gmail for approval emails (later); Play Console (later, the brother's account).

---

## 12. Current status (8 Oct 2026)

**Done**
- Planning documents: PRD, TRD, schema, AGENTS.md, task plan, start guide, design prompts.
- **T00:** Flutter project with `dev` and `prod` flavors (separate app ids and labels "CashFlow Dev" / "CashFlow"), folder structure, CI workflow file, tasks and test-scenario files.
- **T01:** Supabase dev project; migration and dev helper run; SQL tests T-DB1 to T-DB6 **passed** (isolation, approved-device rule, plan rule, repayment limit, `updated_at`, atomic paid action).
- **T02:** theme tokens and 15 shared widgets with a dev-only gallery; real font weights bundled (Inter 400/500/600/700, Noto Devanagari and Gujarati 400/600); continuous corners; glass with solid fallback.
- **T03:** localization (English, Hindi, Gujarati) with final translations for key terms (Hindi "उधार", Gujarati "ઉધાર", "EMI" kept in Latin script in all languages); money, date (IST) and EMI utilities with unit tests. About 46 tests pass; analyze is clean.
- **Package id** set to `com.pranjalpaghadal.cashflow` (dev: `.dev`), both flavors build.

**In progress / pending**
- Branch `task/T03-fixes` awaits the owner's merge into the main branch; then push to the private GitHub repo and confirm the **CI run is green** (it has never run).
- Migration `0002_mark_due_paid_validation.sql` is a proposal awaiting review; it has not been applied.
- Owner still to send screenshots of the gallery (light, dark, 2.0x text, Hindi) for review, and to move the old `rules/` and `caseFloww/` copies out of the repo.
- **T04 (encrypted local database)** plan was submitted and is under review. Key finding: the plan used the older `sqlcipher_flutter_libs` approach, but current Drift docs (drift 2.32.0 with sqlite3 3.x) say that package is no longer functional or needed and encryption is enabled through build hooks in `pubspec.yaml` (SQLite3 Multiple Ciphers or SQLCipher as a hook option). The plan must follow the current docs, must not add `sqlite3_flutter_libs` or `sqlcipher_flutter_libs`, and must prove encryption on the real phone (file does not start with "SQLite format 3", wrong key fails). Also: UI preferences must not be stored in the wiped database; no foreign keys locally; tests must include restart persistence and logout wipe.
- Remaining designs and screenshots (see section 7), Hindi/Gujarati wording review, logo, Play Console agreement, ₹1 intro price check.

---

## 13. Decision log

Fully online with a phone copy; automatic restore on a new device. Supabase over Firebase for data (SQL suits totals); FCM only for push. Last-write-wins conflicts. Device approval in-app with email-code fallback; no biometrics needed for approval. PIN 4 digits, biometric optional. Loans are not income or expense but move cash balance. Phone data encrypted; cloud data not end-to-end encrypted this release. Reminders, EMI, bills, income, budget, charts, export and search are paid; free users keep income, expense and lend/borrow. ₹1 for 3 months, then ₹20 or ₹200. Ads later, free users only. No bill auto-fetch now. Android first, iOS second. Riverpod and go_router. Antigravity builds; Stitch designs; one task at a time; the owner approves. Package id `com.pranjalpaghadal.cashflow`. Daily subscription check. Mumbai region. Minimum Android 7.

## 14. Risks and open items

Sync complexity (build and test first); reminder reliability on aggressive Android battery savers; the ₹1 to ₹20 price jump (clear disclosure and a pre-renewal reminder); three languages triple the text to review; encryption package choice (see T04); free Supabase project pausing after inactivity (the daily job keeps it active; upgrade when real users depend on it); Supabase and Firebase free-plan rules (verify); Play intro-price minimum; Play app ownership and payouts with the brother's account; owner reviews outputs rather than code, so automated tests, plain reports and phone checks are essential.

## 15. Glossary

**Paise:** 1/100 of a rupee (all money stored as integers). **EMI:** equal monthly installment of a loan. **Udhar:** informal lend/borrow. **RLS:** database rules deciding who can read or write which rows. **Soft delete:** marking a row deleted instead of removing it so other devices learn about it. **Outbox:** the phone's queue of changes waiting to upload. **Cursor:** the position of the last downloaded change. **Edge Function:** a small server program. **FCM:** push notification delivery service. **Flavor:** a build variant (dev or prod). **Squircle:** the smooth Apple-style rounded corner. **Premium:** the paid plan (including the ₹1 intro period).
