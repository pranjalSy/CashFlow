# CashFlow: Progress log

## 2026-10-08: Project setup (T00 skeleton)
- Created the Flutter app in `app/` (package `com.pranjalpaghadal.cashflow`, Android + iOS).
- Android flavors: `dev` (id `.dev`, label "CashFlow Dev") and `prod` (label "CashFlow"). Minimum Android 7 (API 24). Android backup disabled.
- Entry points: `lib/main_dev.dart`, `lib/main_prod.dart` (shared `bootstrap.dart`, `FlavorConfig`).
- Folder structure: `lib/app`, `core/{config,theme,utils}`, `data/{local,remote,repositories}`, `features/*`, `l10n`, `shared/widgets`.
- Repo root: `CLAUDE.md`, `.claude/settings.json`, `docs/`, `supabase/migrations/`, `ui/`, CI workflow, `.gitignore` (env/ and secrets excluded).
- No extra packages added yet (Riverpod, go_router, Drift etc. need owner approval).
- Checks: `flutter analyze` clean, 2 widget tests pass, dev and prod debug APKs build.

**Pending:** AGENTS.md, PRD, TRD, TASK_PLAN, START_HERE and SQL migration from the owner.

## 2026-10-13 to 14: Brand and UI design (new design, old `ui/` dropped)
- Logo final: "Rupee Track" (₹ + tick), all sizes and variants in `design/logo/` (brand sheet, PNG 1024/512/192/48).
- Screens designed and reviewed one by one (HTML mockups in `design/screens/`):
  01 Splash, 02 Login/Sign up, 03 Language, 04 Email sign in, 05 Verify email, 06 PIN, 07 Fingerprint (+07b cases), 08 Opening balance, 09 Contacts permission, 10 Home (+10b swipe and "+" menu demo), 11 Add expense/income, 12 Category picker, 13 Contacts tab, 14 Person detail (+14b udhar due popup), 15 Add lent/borrowed, 16 Charts, 17 EMI & Bills, 18 Add EMI, 19 EMI detail, 20 Add bill, 21 Budget, 22 Export, 23 Search, 24 Settings, 25 Devices + new login approval, 26 Paywall, 27 Delete account, 28 Empty/locked/offline states (21-28 awaiting owner review).
- All owner decisions that differ from the brief are in `docs/DESIGN_DECISIONS.md` (must be used when PRD/TRD are updated).
- No app code changed in this phase.

**Next:** design phase screens complete; remaining = owner review of 21-28 and pending decisions, then dark mode check.

## 2026-10-14: PRD v2.0
- New `doc/PRD.md` (v2.0, draft for owner approval): merges old PRD v1.0 (`D:\caseFlow\docs\PRD.md`), the master brief and all decisions in `docs/DESIGN_DECISIONS.md`. Requirement IDs kept; changes marked [Changed] / [New] / [Removed].
- Owner answered Q1-Q5 and approved PRD v2.0. Paywall (26) now shows Monthly ₹20 + Yearly ₹200.

**Next:** dark mode review of all screens.

## 2026-10-14: TRD v2.0
- New `doc/TRD.md` (v2.0, draft for owner approval): based on old TRD v1.0, updated for PRD v2.0 and the current repo (T00). Full package list (all need owner approval), data model changes, atomic RPCs, sync undo window, logout wipe, lost-phone remote wipe, fingerprint only, monthly + yearly billing, encrypted backups, testing plan.
- Owner answered Q1-Q3 and approved TRD v2.0: fresh start (nothing reused from `D:\caseFlow`), new widget library, Flutter upgrade as a separate task.

**Next:** dark mode review of all screens; then the Flutter upgrade task; then T01 (fresh Supabase schema).

## 2026-10-14: Dark mode (started)
- Owner compared 3 dark styles (`dark/30_black_demo.html`) and chose **Proper black + glass**. All 31 screens generated in that style from one token map (`design/screens/dark/index.html`, tokens `00_dark_tokens.html`). Screen 17 bills copy updated to the new bills flow. PRD FR-U10 and TRD section 14 updated.

**Next:** T01 (fresh Supabase schema).

## 2026-10-15: AGENTS.md
- New root `AGENTS.md` (v1.0): mandatory rules for the AI coding agent (Claude Code), loaded every session through `CLAUDE.md` (`@AGENTS.md`). Covers sources of truth, task workflow, hard stops (scope, files, git, backend, honesty), money/data, security, UI, code, when to ask, definition of done.

## 2026-10-15: GitHub setup (paused by owner)
- GitHub CLI 2.102.0 installed (`C:\Program Files\GitHub CLI\gh.exe`); login was started and then cancelled by the owner. Nothing uploaded, no remote added.
- Planned when resumed: public repo `CashFlow` (owner's GitHub account, possibly `pranjalSy`), branches `main` and `experiment`, first push = T00 + docs + designs. Rule already in `AGENTS.md`: work on `experiment`; ask before every commit/push and before merging to `main`.

## 2026-10-15: Flutter version decision
- Checked: current 3.44.7, latest stable 3.47.7. Owner decided to **stay on 3.44.7** (no upgrade, nothing downloaded or changed). TRD section 2 and Q3 updated.
- Known `flutter doctor` warnings (not fixed, separate task if needed): Android cmdline-tools missing, Android licences not accepted. Debug APKs still build.


## 2026-10-15: App setup check + small fixes
- Checked `app/`: analyze clean, 2/2 tests pass, dev and prod build; ids `com.pranjalpaghadal.cashflow(.dev)`, labels "CashFlow Dev" / "CashFlow", minSdk 24, target 36.
- Fixed (owner approved):
  1. `INTERNET` permission added to the main manifest (it was only in debug/profile, so a release build could not sync).
  2. Android 12+ backup/device-transfer: new `res/xml/data_extraction_rules.xml` excludes all app data; linked via `android:dataExtractionRules`. Verified against Android 12 behaviour-change docs (allowBackup=false alone does not stop device-to-device transfer).
  3. iOS display name `Cashflow` → `CashFlow`.
  4. Placeholder theme colours → brand indigo `#3B5BDB` and Marble `#F2F8FC`.
- Re-checked after fixes: analyze clean, tests pass, dev debug and **prod release** APK build; both APKs contain INTERNET, allowBackup=false, fullBackupContent=false, dataExtractionRules.
- Not done (later): release signing key (owner, before Play), Android cmdline-tools/licences warning.
- Not committed yet: waiting for the owner's phone test and yes.


## 2026-10-15: GitHub repo created
- GitHub CLI logged in as **pranjalSy** (owner's choice; the other account PranjalPatel45 was logged out on this PC).
- Created public repo https://github.com/pranjalSy/CashFlow with only a README; branches **main** and **experiment** (both at the README commit).
- Local repo linked as remote `origin` (nothing pushed). The local history (T00) is separate from the README commit, so the first push will merge them; that push happens only after the owner's phone test and yes.

## 2026-10-15: T01 · Theme (owner testing)
- Order decided by owner: **Frontend first** (TASK.md phases A→E). Working on local branch `experiment`.
- Fonts downloaded from Google Fonts (owner approved, ~2 MB, OFL licences saved): Inter 400/500/600/700, Noto Sans Devanagari 400/600, Noto Sans Gujarati 400/600 in `app/assets/fonts/`. Checked with a cmap reader: Inter has ₹ and Latin; Noto fonts have Hindi/Gujarati.
- New `lib/core/theme/`: `app_colors.dart` (light + dark tokens as a ThemeExtension, `context.colors`), `app_typography.dart` (Inter + Noto fallback, tabular amounts), `app_shapes.dart` (squircle radii, spacing), `app_theme.dart` (light/dark ThemeData). `app.dart` uses both themes, follows the phone setting. Temporary `lib/app/theme_preview.dart` replaces the placeholder.
- [Verify] done: `RoundedSuperellipseBorder`, `ClipRSuperellipse`, `FontFeature.tabularFigures` exist in Flutter 3.44.7 SDK.
- Tests: 15 new (token values, contrast ≥ 4.5 for button text and amounts on page/card/glass/sheet, muted ≥ 3.0, tints, ThemeData, tabular digits, squircle, dark black page, small-phone no overflow) + 2 old = **17 pass**; analyze clean; dev APK built. Real-font screenshots (light and dark) checked: ₹, Hindi, Gujarati render.
- **Deviation:** the contrast test found light muted `#8A97A8` = 2.77 on the page; app uses `#808EA0` (3.12). Mockups unchanged.
- No packages added.
- Owner approved the darker muted colour (A5) and said yes to push to `experiment`. **Correction:** the owner had NOT tested on the phone yet (I misread "test kar liya, sab theek he??"). Phone test of T00b + T01 is still pending; `main` untouched.
- Owner decision: build **T02 → T10 in a row**, phone test all together at the end.

**Next:** T02 · Widget library + gallery (PLAN first).
- Pushed: commit `ff6a132` (T00b + T01 + docs + designs) and merge `0f3c16b` (GitHub README) on **`experiment`** → https://github.com/pranjalSy/CashFlow/tree/experiment. GitHub login got the `workflow` scope (needed to upload `ci.yml`). `main` untouched (README only). CI run started on GitHub (first run ever).

## 2026-10-15: Approvals for T02–T10
- Owner: build T02 → T10 in a row; phone test all together at the end.
- Packages approved (versions checked on pub.dev, all fit Flutter 3.44.7 / Dart 3.12.2): flutter_riverpod 3.4.3, go_router 18.1.0, drift 2.35.2, sqlite3 3.7.1, path_provider 2.1.6, path 1.9.1, flutter_secure_storage 11.2.0, cryptography 2.9.0, local_auth 3.0.2, flutter_contacts 2.6.0, shared_preferences 2.5.6, intl 0.20.3, flutter_localizations (SDK), uuid 4.6.0; dev: drift_dev 2.35.1, build_runner 2.17.1.
- [Verify] Drift encryption (official docs): drift ≥ 2.32 + sqlite3 3.x with `hooks: user_defines: sqlite3: source: sqlite3mc`; key via `PRAGMA key` in `NativeDatabase` setup; check `PRAGMA cipher`; do NOT add sqlcipher_flutter_libs or encrypted_drift. `drift_flutter` not used (NativeDatabase + path_provider directly).
- Owner allowed **local checkpoint commits** after each task (no push, no main) until the phone test.

## 2026-10-15: T02 · Widget library + gallery (built, phone test after T10)
- Packages added and pinned (approved): flutter_riverpod 3.4.3, go_router 18.1.0, drift 2.35.2, sqlite3 3.5.2, path_provider 2.1.6, path 1.9.1, flutter_secure_storage 11.2.0, cryptography 2.9.0, local_auth 3.0.2, flutter_contacts 2.6.0, shared_preferences 2.5.6, intl 0.20.2, uuid 4.6.0, flutter_localizations; dev: drift_dev 2.35.1, build_runner 2.15.1. **Deviations:** sqlite3 3.7.1 needs a newer Flutter (meta 1.19) → 3.5.2; build_runner 2.17.1 conflicts with drift_dev → 2.15.1; intl 0.20.3 → 0.20.2 (pinned by flutter_localizations). `hooks: user_defines: sqlite3: source: sqlite3mc` added (verified in sqlite3 3.5.2 `doc/hook.md`).
- `lib/shared/widgets/`: glass (GlassSurface, reduceGlassProvider), app_page (Marble / black + glow), app_card, amount_text, app_button (never disabled, ≥ 48 dp), basics (IconTile, SectionLabel, AppChip, SegmentedSwitch, AppToggle, ListRowTile), number_pad, overlays (solid sheet + popup with one blur scrim, CompactSnackbar 54 px), swipe_row (60% full swipe → delete callback), states (EmptyState, OfflineBar, PremiumLockCard), glass_nav_bar (4 tabs + "+"), plus_menu.
- Dev gallery `lib/features/dev/gallery_screen.dart` is the app home for now; ProviderScope in bootstrap. Theme preview removed.
- Tests: 44 pass (11 new widget tests: tap size, amount fit at 2× text, glass on/off/reduced, nav bar, number pad, swipe thresholds, gallery on 320 px light/dark). A test found the nav bar overflowing on 320 px phones → active tab label now shrinks. Real-font screenshots (light/dark) match the mockups.

## 2026-10-16: T03 · Languages + money/date/EMI utilities (built, phone test after T10)
- `l10n.yaml` + `lib/l10n/app_{en,hi,gu}.arb`: 291 keys for all screens up to T10 (nav, common, first run, PIN, fingerprint, opening balance, contacts permission, Home, Add entry, categories, Contacts/udhar, EMI). Same keys in all 3 files (checked). Hindi "उधार", Gujarati "ઉધાર", "EMI" Latin everywhere. `flutter: generate: true`; generated `app_localizations*.dart` committed. App has localization delegates; `context.l10n`.
- **Owner review needed:** Hindi and Gujarati wording was written by Claude; please check the main screens on the phone.
- `core/utils/money.dart` (₹ en_IN format, signs, parse typed amount to paise, number-pad rules), `dates.dart` (IST dates, month ranges, LocalDate with 29/30/31 clamp), `emi.dart` (EMI, months from EMI, not-possible check, exact schedule with interest per installment).
- Tests: 47 pass. EMI reference numbers all exact: ₹7,996.39; total interest ₹5,956.69; last ₹7,996.40; remaining after 4 ₹63,971.13; installment 5 interest ₹611.86; EMI ₹8,500 → 12 months; ₹800 → not possible; 0% → exact totals.
- Dev-only text `devPremiumToggle` added: a Premium switch shown **only in the dev flavor** so EMI and due dates can be tested before billing (T20). Not in prod.

## 2026-10-16: T04 · Encrypted phone database (built, phone test after T10)
- `data/local/tables.dart`: all TRD 6.1 tables (profiles, categories, people, transactions, debts, debt_payments, debt_extensions, emis, emi_installments, bills, bill_payments, budgets, budget_category_limits) with the sync column mixin (id, user_id, created_at, updated_at, deleted_at, is_synced), plus phone-only sync_outbox, sync_cursors, plan_cache, app_flags. Money integer paise, due dates ISO text, instants stored as ISO UTC text (`build.yaml`). No local foreign keys. Debts also keep `extra_not_added` for the G7 card line.
- `database.dart` (Drift, generated `database.g.dart`), `openEncryptedDatabase` + `applyKey`: refuses to open if `PRAGMA cipher` is missing, sets `PRAGMA key`, checks the key at once. `local_store.dart`: random 256-bit key in secure storage, DB file in app support dir, `wipe()` deletes DB + WAL/SHM/journal + all secure keys. `repositories/local_writer.dart`: one transaction for rows + outbox, shared batch id, 5 s undo window, `dropBatch`; `localUserId` until account login. Riverpod providers; bootstrap opens the DB before the app starts.
- [Verify] on device build: APK contains `libsqlite3mc.so` for arm64-v8a, armeabi-v7a, x86_64.
- Tests: 57 pass. On-disk test: file header is not "SQLite format 3", a stored secret is not readable in the bytes, wrong key fails, same key reused, all tables exist, wipe removes files and keys, outbox batch/undo/rollback.
- **Build fix:** `kotlin.incremental=false` in `android/gradle.properties` (Kotlin incremental cache breaks when plugins are on C: and the build on D:).

## 2026-10-16: T05 · Calculation engine (built, phone test after T10)
- `data/repositories/calculations.dart`: SQL aggregates only (TRD 7). `month(y, m)` → income, expense, new lent, new borrowed, repayments received/paid, split cash/online; Monthly Net; cash, online and total balance at month end (opening + everything before + this month). `watchMonth` re-emits on any money-table change. `people()` / `watchPeople()` → Contact Net per person; `debtRemaining`; `expenseInMonth` (budgets, udhar excluded). Months use IST ranges; deleted rows and other users never count.
- Tests: 8 new (Monthly Net 13,500; repayments in net; Contact Net 3,000; balances by mode across months; IST month edge 23:59/00:00; deleted/other user excluded; budget per category; live stream). Total 65 pass.
