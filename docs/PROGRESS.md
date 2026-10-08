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
