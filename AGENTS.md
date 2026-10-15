# AGENTS.md: CashFlow rules for the AI coding agent (Claude Code)

> **Hinglish:** Ye file AI agent (Claude Code) ke liye **pakke niyam** hai. Har session mein apne aap load hoti hai (`CLAUDE.md` isko `@AGENTS.md` se jodti hai). In niyamon ko todna mana hai. Koi niyam kisi task se takraye to agent ruk kar owner se poochega.

**Owner:** Pranjal Paghadal · **Version:** 1.0 (15 Oct 2026) · **Applies to:** every session and every task in this repo.

These rules are **mandatory**. "MUST" and "NEVER" have no exceptions. If a rule blocks the task, **stop and ask the owner**; never work around a rule, and never decide on your own that a rule does not apply.

---

## 0. The project in 5 lines

- **CashFlow:** an Android-first (iOS later) Flutter app for India: income, expenses, udhar (lent/borrowed per person), EMIs, bills, reminders, budget, charts, export, search.
- Stack: Flutter + Riverpod + go_router, Drift (encrypted SQLite) on the phone, Supabase (Mumbai) in the cloud, FCM for push, Google Play Billing.
- **Fresh start:** nothing is reused from the old project `D:\caseFlow` (no code, migrations, tests, theme or widgets).
- The owner is a product owner who **does not read code**. He reviews results on a real phone (Realme, Android 13/14) and in screenshots.
- Free plan + Premium (₹1 for 3 months, then ₹20/month or ₹200/year).

## 1. Sources of truth (read before acting)

| File | What it decides |
|---|---|
| `TASK.md` | **Read first, every session.** Where we are: done, running, owner testing, next, todo |
| `doc/PRD.md` (v2.0, approved) | **What** to build. Requirement IDs (FR-E4, FR-D3…). Build only what is listed |
| `doc/TRD.md` (v2.0, approved) | **How** to build it: stack, packages, data model, sync, security, reminders, billing, testing |
| `docs/DESIGN_DECISIONS.md` | Every owner decision from the design review (A1–K5). Overrides the old brief |
| `design/screens/*.html`, `design/screens/dark/*.html` | Visual reference for each screen (light and dark). Behaviour comes from the PRD |
| `design/logo/` | Logo files |
| `docs/PROGRESS.md` | Running log, updated by you after every task |
| `docs/CashFlow_Master_Brief.md` | Background only. Read it only when overall context is needed. Where it disagrees with the PRD/TRD/DESIGN_DECISIONS, those win |

**Order of authority:** owner's message in chat → `doc/PRD.md` → `doc/TRD.md` → `docs/DESIGN_DECISIONS.md` → mockups → brief.
If two sources disagree, or a requirement is unclear, **stop and ask**. Never guess silently.

## 2. How every task runs

0. **Read `TASK.md` first** to know the current task and status. Keep it updated at every status change (rules at the end of `TASK.md`).
1. **Read** the task block the owner gives and **only** the PRD/TRD sections it names (plus `DESIGN_DECISIONS.md` items it touches).
2. **Plan first.** Write a short plan (what files, what tests, any package or [Verify] item). If the task says **"PLAN ONLY first"**, use plan mode and **wait for approval before changing any file**.
3. **One task per session.** Do not start the next task, and do not "also fix" unrelated things. Note them in the report instead.
4. **Branch (owner rule):** the GitHub repo `CashFlow` has two branches: **`main`** (only owner-verified, working code) and **`experiment`** (all new work). Always work on `experiment`, never directly on `main`.
5. **Build** only what the task and the named requirement IDs say.
6. **Test:** write the tests the task needs; run `flutter analyze` and `flutter test` (and SQL tests for database work). Fix failures before reporting.
7. **Verify on device when the task needs it** (build the `dev` flavor APK). If you could not run something, say so plainly.
8. **Update `TASK.md`** (status) **and `docs/PROGRESS.md`** (detail: date, task, what changed, files, tests and results, deviations, open items).
9. **Report** in plain Hinglish (short, no code): what was built, what passed, what failed, what is pending, and a **"How to check on your phone"** list of taps.
10. **Stop** and wait. The owner tests the feature on the phone.
11. **Commit / push only after the owner verifies.** When the owner says the feature works, **ask**: "Ye code commit aur push kar doon?" Only on a clear yes: commit on `experiment` and push `experiment`. Then ask separately: "Ise `main` mein bhi merge kar doon?" Merge to `main` and push `main` only on a second clear yes.

## 3. Never do (hard stops)

**Scope**
- NEVER add a feature, screen, setting, field, text or animation that is not in the PRD/TRD/DESIGN_DECISIONS. If something seems missing, ask.
- NEVER build anything on the design ignore list (PRD 6.20).
- NEVER add a package, plugin, SDK, service or GitHub Action without the owner's explicit yes in chat. Name it, say why, and wait.

**Files and git**
- NEVER read `env/`, `.env*`, keystores, `key.properties` or any secret. NEVER print, log or commit a secret.
- NEVER touch `rules/`, `caseFloww/`, `ui/` (reference only) or any file you did not create, unless the task names it.
- NEVER edit `CLAUDE.md` or this `AGENTS.md`, and never run `/init`, unless the owner asks.
- NEVER run `git reset --hard`, `git push --force` / `-f`, `git branch -D`, `rm -rf`, history rewrites, or any command that deletes data. Ask first for anything destructive.
- NEVER commit, push or merge before the owner has tested and said yes to that exact step (section 2, step 11). NEVER push untested or failing code to `main`.
- NEVER edit generated files (`*.g.dart`, `*.freezed.dart`) by hand; re-run `build_runner`.
- NEVER copy code from the old project `D:\caseFlow` (fresh start).

**Backend**
- NEVER use the **prod** Supabase project, production keys, the Play Console or any billing account. Work on **dev** only.
- NEVER change the database by clicking in the dashboard. Only new migration files in `supabase/migrations/`; NEVER edit a migration that was already applied.
- NEVER disable or loosen Row Level Security (or any server check) to make something work. Fix the real cause.
- NEVER put the service-role key, FCM/Play service accounts, SMTP password or backup keys in the app or repo. They live only in Supabase / GitHub secrets.

**Honesty**
- NEVER claim something works unless you ran it. NEVER hide a failing test or skip a step silently.
- NEVER guess a vendor API, package version or platform rule. Every **[Verify]** item in the TRD must be checked against the current official docs before coding it, and the result noted in `docs/PROGRESS.md`.

## 4. Data and money rules

- **Money is integer paise** (`int` in Dart, `bigint` in Postgres). NEVER `double` for stored money. Display with `NumberFormat.currency(locale: 'en_IN', symbol: '₹')` (₹1,20,000). Amounts NEVER wrap or truncate.
- Interest rates in basis points (12% = 1200).
- IDs: UUID v4 made on the device. Instants: UTC `timestamptz`. Due dates: ISO `YYYY-MM-DD`. Months and "today": India time (IST).
- Every synced table has `id, user_id, created_at, updated_at (server-set), deleted_at`; **soft delete only**.
- The UI reads **only from Drift**. Writes go to Drift + outbox first, then sync. NEVER call Supabase directly from a screen.
- Linked actions (mark EMI paid, pay bill, repayment, extra-as-debt, extend due date) go through the **atomic RPC functions** in TRD 6.3.
- Totals follow PRD section 8 exactly, as SQL aggregates (not Dart loops). Udhar is never income or expense.
- A repayment row never exceeds the remaining amount; an overpayment extra is always a separate new debt (G8).
- Tests must use the reference numbers in PRD section 8 (EMI ₹7,996.39 for ₹90,000 / 12% / 12 months, Monthly Net 13,500, etc.).

## 5. Security and privacy rules

- Every user table: RLS + approved-device session; Premium tables (and udhar due date / reminders) also need an active plan for writes. The server decides; the app only mirrors.
- Phone database encrypted (TRD 11.1); key only in secure storage; Android backup stays off.
- PIN: salted slow hash, wrong-attempt delay; **fingerprint only** (no face) as in TRD 11.3. The app never sees biometric data.
- **Logout and remote wipe** delete **all** user data on the phone (TRD section 9). Add a test that proves it.
- NEVER log or send to analytics/crash reports: amounts, names, phone numbers, notes, tokens, codes. Not even in debug logs.
- Contacts are read on the phone; only a contact used in an entry is saved to the cloud.
- Email codes and PIN have attempt limits; codes stored only as hashes.

## 6. UI rules

- Follow the mockups in `design/screens/` (light) and `design/screens/dark/` (dark) for look; the PRD for behaviour.
- **Build the shared widget library first** (TRD 14) and show it on a dev-only gallery screen for approval **before** building screens. Every screen uses these widgets.
- Colours, fonts and corners only from the theme tokens (PRD FR-U1, dark FR-U10). NEVER hardcode a colour or size inside a screen.
- Light: glass only on the bottom nav pill and the language bottom bar; sheets, popups, number pads solid white. Dark: proper black + glass cards; sheets, popups, number pads, menus solid. "Reduce glass effects" falls back to solid.
- Save buttons are NEVER disabled; show a red border + message instead (F4).
- All user text from ARB files (en, hi, gu). NEVER hardcode a user-facing string. Long Hindi/Gujarati must not break layouts. "EMI" stays in Latin script.
- Works at 2.0× text, tap targets ≥ 48 dp, smooth on low-end phones (TRD 14).
- Settings is opened from the Home avatar (not a tab). Bottom bar has 4 tabs.

## 7. Code rules

- Structure (already created in T00): `lib/app`, `core/{config,theme,utils}`, `data/{local,remote,repositories}`, `features/<feature>/`, `l10n`, `shared/widgets`. Each feature: screen(s), Riverpod controller, repository.
- Flavors `dev` / `prod` with `lib/main_dev.dart` and `lib/main_prod.dart`; config via `--dart-define-from-file`.
- Match the style of surrounding code; small focused files; no dead code; no commented-out code.
- Pin exact package versions and commit `pubspec.lock`.
- Every bug fix gets a test that would have caught it.

## 8. When to stop and ask the owner

Stop and ask (in simple Hinglish, with your recommendation) when:
- a requirement is unclear, missing, or two documents disagree;
- the task needs a new package, service, permission, or a change to the PRD/TRD;
- a [Verify] check shows the TRD plan no longer works;
- a test keeps failing and the fix would change behaviour;
- anything destructive, outward-facing (publish, push, send) or costly is needed;
- you are about to touch a file you did not create.

## 9. Definition of done (all must be true)

- [ ] Only the requirement IDs in the task were built; nothing extra.
- [ ] Tests written and passing; `flutter analyze` clean; SQL tests pass for database work.
- [ ] No hardcoded strings or colours; en/hi/gu texts added.
- [ ] Works offline where the PRD says so; no amounts or names in logs.
- [ ] Light and dark both checked against the mockups (for UI tasks).
- [ ] [Verify] results written in `docs/PROGRESS.md`.
- [ ] `docs/PROGRESS.md` updated; plain-language report with "How to check on your phone" given.
- [ ] Owner tested it; commit/push to `experiment` and merge to `main` only after the owner's yes for each.

## 10. Changing these rules

Only the owner changes this file. If a rule seems wrong for a task, say so in the report and wait; never ignore it.
