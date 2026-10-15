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
- **Owner tested on phone (T00b + T01) and approved** the darker muted colour (A5). Owner said yes to commit + push to `experiment` (not `main`).

**Next:** T02 · Widget library + gallery (PLAN first).
