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

## 2026-10-16: T06 · First run + T07 · App lock (built, phone test after T10)
- Navigation: go_router (`app/router.dart`), 4-tab `StatefulShellRoute` shell with the glass bar and "+" menu (`app/shell.dart`; EMI tab shows only Add EMI / Add bill). Tab screens are placeholders until T08–T10 (Charts shows "comes in a later update").
- First run (C1): Splash (logo + tagline) → Welcome (Log in / Create account; both continue on this phone with a note that account and sync come later) → Language (13 listed, en/hi/gu live, search, applies at once, saved in shared_preferences) → Create + confirm PIN (auto-advance, mismatch shake) → Fingerprint (skipped without sensor; "Set up fingerprint first" when not enrolled; enabling needs one good scan) → Opening balance (cash + online on a solid number pad, Skip) → Contacts permission (explain, then ask) → Home. Profile row + outbox written; `onboarding_done` flag.
- App lock: `PinService` (PBKDF2-HMAC-SHA256, 100k rounds, random salt, in a background isolate; 5 tries → 30 s, doubling, persisted), `BiometricService` (strong/fingerprint only, `biometricOnly: true`), `LockScreen` (fingerprint first, PIN fallback, countdown, Forgot PIN explains it needs account login), `LockController` (relock after 1 min in background).
- Android (local_auth docs): `MainActivity` → `FlutterFragmentActivity`; Launch/Normal themes → `Theme.AppCompat` (light + night); permissions `USE_BIOMETRIC`, `READ_CONTACTS`. No new packages.
- Logo PNG (approved Rupee Track, 512 px) bundled as `assets/images/logo.png`.
- Tests: 81 pass (8 new flow tests with fake fingerprint/contacts: full first run saving the opening balance, Allow contacts, Hindi applied at once, PIN mismatch, fingerprint enrolled / not enrolled, returning user wrong → right PIN, fingerprint first; 3 lock-timer tests). Tests found overflow at small heights → PIN, lock and opening screens now compact on short screens.
- **Pending decisions:** (1) hide app in recents (`FLAG_SECURE`, FR-L10, "should") also blocks screenshots, which the owner uses for review → not enabled yet, ask before T22. (2) [Verify] on the Realme: fingerprint shows as available (`strong`), face unlock never used. (3) Change PIN / lock-after / fingerprint switch UI is part of Settings (T14).

## 2026-10-16: T08 · Home + Add/edit entry (built, phone test after T10)
- Data: `category_repository.dart` (15 expense + 7 income default categories with localized name keys, icons, colours; typed category saved once and reused; recent 4), `entry_repository.dart` (add / update / soft delete with 5 s undo / last payment remembered / Home list merging income, expense and udhar for an IST month), `people_repository.dart` (people + Indian phone → E.164 normalising; used by T09), `core/utils/streams.dart` (small combineLatest helper, no new package), `core/ui/labels.dart` (category icons/names, payment, day, month and time labels in the user's language).
- Home (screen 10): greeting, search (shows "coming soon" until T13), month picker, balance card (end-of-month balance, cash/online, 4 tiles, net, eye hides amounts — saved in profile), chips All/Expense/Income/Udhar, "Transactions" count, day groups (Today/Yesterday), separate cards; swipe for Edit/Delete; full swipe or Delete → confirm sheet → soft delete → Undo snackbar; udhar rows open the person (T09). Avatar opens a Settings placeholder (T14).
- Add/edit entry (screen 11): Expense | Income switch (colour + sign), big amount with number pad + Done, category chip → picker sheet (recent, search, 4-column grid, Create), title, date/time with "Now", Paid via required (Cash / Online → UPI/Card/Bank, last choice pre-selected), note; Save never disabled (red message), edit mode with Delete.
- Shared: `payment_picker.dart`, `person_avatar.dart`; "+" menu now keeps a "×" above the dim layer and has soft shadows (screenshot check).
- Tests: 94 pass (9 repository + 4 Home/entry flow tests: payment required then saved, full swipe → confirm → delete → Undo, income with a new typed category, dark Home). Test-infra fix: widget tests no longer close the in-memory DB (drift stream timers on the fake clock made tearDown hang) and unmount the app at the end.
- Real-font screenshots (light/dark Home, + menu, Add entry) match screens 10 and 11.

## 2026-10-16: T09 · Contacts + udhar (built, phone test after T10)
- Done: `plan_repository.dart` (plan cache; dev-only Premium switch on the Settings placeholder), `debt_repository.dart` (add lent/borrowed with Premium-only due date/reminders, repayment capped at remaining + extra remembered, "Yes" → opposite udhar, extend due date with history, delete, person history stream, due-popup list + "Not yet" snooze) with 8 passing tests; Contacts tab, Person detail, Add Lent/Borrowed form (person picker, Premium tag + small paywall sheet), Repayment sheet (summary, stays open "Payment saved", extra snackbar with Yes); routes.
- Due popup (FR-D11, G9, screen 14b): `features/contacts/udhar_due_popup.dart`, shown after Home's first frame, Premium only, one after another for several due udhar. Got full (asks Cash/Online, settles), Got some (in-popup number pad, "₹X will still be left", keep or change due date, more than remaining → extra snackbar as in FR-D3), Not yet (asks again tomorrow), Change due date (new date with history, G10). 5 new strings in en/hi/gu.
- Tests: `test/features/udhar_test.dart` (5 widget flows: Free add lent + Premium tag sheet + overpayment extra as borrowed; Premium popup Got some / Got full / Not yet; Free sees no popup). Full suite 107 passing, `flutter analyze` clean.
- Fix found by tests: premium and person name are read once from the database (a stream `.first` did not finish), so the popup appears reliably.
- Real-font screenshots of the popup (light ask, dark "Got some") match mockup 14b.
- Deviation: none. Next: T10 (EMI).

## 2026-10-16: T10 · EMI (built, phone test pending)
- Data: `emi_repository.dart`: add an EMI and all its installments in one action. Day 29/30/31 falls back to the month's last day, and the last installment takes the remainder.
  - Mark paid works only on the next due installment. In one action it marks the installment paid, adds an expense in category EMI (source `emi`), and closes the EMI after the last one. Its upload is held for the 5 s Undo window.
  - Undo and "Mark as unpaid" (on the last paid one) remove the expense.
  - Edit: name, icon and lender can always change; loan terms only while nothing is paid (the installments are then rebuilt).
  - Delete is a soft delete; expenses already added stay.
  - "Due this month", next date and remaining are SQL sums. Due-popup list included.
  - The Drift data class is renamed `EmiLoan` (`@DataClassName`) so it does not clash with the `Emi` maths. The schema is unchanged.
- Screens:
  - EMI & Bills tab (screen 17): EMIs | Bills, with Bills showing "coming in the next update" until T11. Summary card, EMI cards (progress, remaining, due tag: orange under 7 days, red when late), Closed section. Free users see the locked card.
  - Add/Edit EMI (screen 18): icon picker, item price − down payment = loan (or type the loan), rate, first EMI date. "I know the: Months | EMI amount" with a live result card. The "Not possible" red card shakes on Save and nothing is saved.
  - EMI detail (screen 19): fixed header with ⋯ (Edit / Delete with confirm), hero, 3 facts, installments (earlier paid collapsed, last paid, next due with orange border and Mark paid, upcoming dimmed, "Last" tag). Opens scrolled to the due one.
  - Mark paid sheet: Paid on and Paid via required, last choice pre-selected. Then a snackbar "Installment N paid · Expense added · N left" with Undo. A paid row opens its details, with "Mark as unpaid" on the last paid one.
  - "Paid or not?" popup on Home open (Premium), shown before the udhar popup. Paid opens the Mark paid sheet; Not yet asks again next open (PRD FR-E7; TRD 12 says "tomorrow", PRD wins).
- "Add bill" in the + menu shows "Bills come in the next update" until T11, so it cannot open a missing page.
- Shared widget fixes: `AppCard` gets an optional `border`; `GlassSurface` now keeps a border the caller asks for, which was hidden on dark glass.
- 10 new strings in en/hi/gu.
- Tests: `test/data/emi_repository_test.dart` (10, PRD §8 numbers: ₹7,996.39, last ₹7,996.40, interest ₹5,956.69, ₹63,971.13 left after 4 paid, ₹611.86 interest in installment 5) and `test/features/emi_test.dart` (6 flows). Full suite **123 passing**, analyze clean, dev debug APK built.
- Bugs found by tests or screenshots, all fixed:
  - The next-due row overflowed with wide text.
  - The detail header scrolled away when the screen opened at the due installment.
  - "Next on" showed a past date.
- Real-font screenshots (light and dark: list, detail, Mark paid, Undo, Add, Not possible) match screens 17–19.
- Deviation: EMI ₹8,500 gives a last EMI of ₹2,112.97, 1 paisa from PRD ₹2,112.98. This comes from rounding interest each month, the same as noted in T03.
- Open items for the owner:
  - An EMI expense on Home can still be edited or deleted by hand, which does not change the installment.
  - Reminders for EMI arrive in T19.

## 2026-10-16: Bottom bar liquid glass animation (owner request)
- Owner asked for an iOS 26 / Instagram-style tab bar: one selection pill that slides in a line to the tapped tab. Approved in chat (16 Oct 2026). Under FR-U7, premium animations.
- `shared/widgets/glass_nav_bar.dart`:
  - One pill slides from tab to tab (340 ms, easeOutBack: small bounce at the end). It stretches and flattens mid-way (liquid feel).
  - Tabs grow from icon-only to icon + name as the pill arrives; the name fades in and the icon pops a little.
  - Selection haptic on tap. With system "remove animations" the pill jumps.
  - Only transforms, sizes and opacity inside a `RepaintBoundary` (TRD 14). No new package.
- Not added (not approved): dragging the finger along the bar; Hero / card-expand transitions; the other mockup animations (Welcome, Fingerprint, Contacts, Home). These are noted for the owner to decide.
- Tests: 3 new (the pill passes the tabs in between and ends on the tapped one; jumps with remove-animations; no overflow at 320 px and 2.0× text while moving). Suite **126 passing**, analyze clean.
- Real-font frames (light and dark) checked. Dev release APK installed on the owner's Realme over USB.
- **Bug fix (owner, 16 Oct):** while the pill moved, the tabs in between grew, showed their names, and wobbled with the bounce. Now only the old tab (shrinks) and the new tab (grows) change. The layout moves once with no bounce; only the pill has a gentle bounce and stays inside the bar. The old name fades out fast and the new name fades in as the pill arrives. Regression test added: tabs in between never grow or show their name. Suite **127 passing**, installed on the owner's phone and checked there.
- Seen on the phone, not fixed (separate T09 bug): some phone contacts show as "?" in Contacts → All contacts (name not read).
- **Bug fix (owner, 16 Oct): "?" in Contacts.** 6 of 262 phone contacts had no name. Now a contact without a name shows its name parts, nickname or first number. Contacts with no name and no number are left out. Number-only contacts (Android uses the number as the name) are listed after the named ones under "#". The same names are used in the Add lent/borrowed person picker. 2 tests added (`test/features/contacts_test.dart`); suite **129 passing**; installed and checked on the owner's phone: no "?" left.
- **Found in the phone test, not fixed (needs owner decision):** the app turns to landscape with auto-rotate. In landscape the + menu runs under the status bar and the Add entry number pad covers the whole screen (amount hidden, last key row cut). PRD/TRD say nothing about orientation. Recommendation: lock the app to portrait.

