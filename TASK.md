# TASK.md: CashFlow task board

> **Hinglish:** Ye file batati hai ki hum kahan hain. Har session mein agent **sabse pehle ye file padhega**. Har task ki status: ✅ Done · 🔄 Running · 🧪 Owner testing · ⏳ Next · ⬜ Todo · ⏸ Paused. Detail log `docs/PROGRESS.md` mein hai.

**Last updated:** 15 Oct 2026 · **Updated by:** Claude Code (after every task or status change)

---

## 📍 Abhi kahan hain (Current)

| | |
|---|---|
| **Running** | 🔄 T09 (left: udhar due popup on Home, T09 UI tests) → then T10 EMI |
| **Waiting for owner** | Nothing (packages approved); phone test after T10 |
| **Next** | ⏳ T02 · Widget library + gallery (PLAN first) |
| **Git** | Repo https://github.com/pranjalSy/CashFlow · local branch: **`experiment`** · `experiment` pushed with T00b + T01 + docs + designs (pushed before the phone test, by mistake; main untouched) · `main` = README only (merge only on owner's yes) |

---

## ✅ Done

| # | Task | Result | Date |
|---|---|---|---|
| T00 | Flutter skeleton: `app/`, flavors dev/prod, package id, minSdk 24, folders, CI | Commit `6454517` | 8 Oct |
| D1 | Logo "Rupee Track" + brand colours | `design/logo/` | 13 Oct |
| D2 | Light screens 01–28 (+07b, 10b, 14b) | `design/screens/` | 13–15 Oct |
| D3 | Dark mode: Proper black + glass, 31 screens | `design/screens/dark/` | 15 Oct |
| DOC1 | PRD v2.0 (approved) | `doc/PRD.md` | 14 Oct |
| DOC2 | TRD v2.0 (approved) | `doc/TRD.md` | 14 Oct |
| DOC3 | AGENTS.md (agent rules) + this TASK.md | root | 15 Oct |
| G1 | GitHub repo `pranjalSy/CashFlow` (public) with `main` + `experiment` | README only | 15 Oct |

## 🔄 Running / 🧪 Owner testing

| # | Task | Status | What is left |
|---|---|---|---|
| T00b | App setup fixes (INTERNET, data-extraction rules, iOS name, colours) | 🧪 Built + pushed to `experiment`; **phone test pending** | Owner tests together with T02–T10 |
| T01 | Theme: tokens light/dark, Inter + Noto fonts, squircle, spacing, preview; 17 tests pass | 🧪 Built + pushed to `experiment`; **phone test pending** | Same |

## ⏸ Paused

| # | Task | Why |
|---|---|---|
| — | Flutter upgrade (3.44.7 → 3.47.7) | Owner: stay on 3.44.7 |
| — | Android cmdline-tools + licences | Needed before Play release; separate task later |

---

## ⏳ Todo

**Order (owner decided 15 Oct 2026): Frontend first** → phases A → B → C → D (backend) → E.

### Phase A · Frontend foundation
| # | Task | PRD / TRD | Status |
|---|---|---|---|
| T01 | Theme tokens (light + dark), fonts (Inter, Noto Devanagari/Gujarati) | FR-U1, FR-U9, FR-U10 · TRD 14 | 🧪 Phone test pending |
| T02 | Shared widget library + dev gallery screen (cards, glass nav, sheets, number pad, chips, snackbar, swipe row, empty state…) | FR-U2–U8 · TRD 14 | 🧪 Built · local commit · phone test after T10 |
| T03 | Localization en/hi/gu + money, date (IST), EMI utilities with tests | §4, §8 · TRD 5, 7, 15 | 🧪 Built · local commit · phone test after T10 |

### Phase B · Phone brain (offline)
| # | Task | PRD / TRD | Status |
|---|---|---|---|
| T04 | Encrypted local database (Drift) + all tables + outbox | NFR-9 · TRD 6, 11.1 | 🧪 Built · local commit · phone test after T10 |
| T05 | Calculation engine (totals, balance, contact net, budget) | §8 · TRD 7 | 🧪 Built · local commit · phone test after T10 |

### Phase C · Screens (work offline)
| # | Task | PRD / TRD | Status |
|---|---|---|---|
| T06 | First run: splash, language, PIN, fingerprint, opening balance, contacts permission | FR-A4, FR-A5, FR-L1–L4, FR-O7 | 🧪 Built · local commit · phone test after T10 |
| T07 | App lock (PIN, fingerprint, lock-after, wrong-attempt delay) | FR-L5–L10 · TRD 11 | 🧪 Built (lock screen, timer, lockout) · Settings parts in T14 |
| T08 | Home + Add/edit entry + category picker + swipe/delete confirm | FR-H1–H6, FR-O6, FR-T1–T9 | 🧪 Built · local commit · phone test after T10 |
| T09 | Contacts + Person detail + Add lent/borrowed + repayment/overpayment + due popup | FR-D1–D11 | 🔄 Mostly built (due popup + UI tests left) · local commit |
| T10 | EMI: add, list, detail, mark paid, popup | FR-E1–E11 | ⬜ |
| T11 | Bills: add (type, every N months), list, pay popup with suggestions, pause | FR-B1–B7 | ⬜ |
| T12 | Charts + Budget | FR-C1, FR-BG1–BG5 | ⬜ |
| T13 | Export (PDF/CSV) + Search | FR-C2, FR-C3 | ⬜ |
| T14 | Settings + empty/offline states | FR-G1, FR-S8, FR-U8 | ⬜ |

### Phase D · Backend
| # | Task | PRD / TRD | Status |
|---|---|---|---|
| T15 | Supabase schema (fresh), RLS, RPC functions + SQL tests | TRD 6, 13.2 · NFR-3 | ⬜ |
| T16 | Login (Google, email + code) | FR-A1 · TRD 9 | ⬜ |
| T17 | Sync engine (outbox up, cursor down, undo window) | FR-S1–S9 · TRD 8 | ⬜ |
| T18 | Devices: approval, email code, lost phone, remote wipe | FR-V1–V8 · TRD 10 | ⬜ |
| T19 | Reminders: local + server push, due popups | FR-R1–R6 · TRD 12 | ⬜ |
| T20 | Premium: Play Billing, paywall, plan checks | FR-P1–P9 · TRD 13 | ⬜ |
| T21 | Logout wipe + delete account (with tests) | FR-A2, FR-A3 · NFR-14 | ⬜ |

### Phase E · Release
| # | Task | PRD / TRD | Status |
|---|---|---|---|
| T22 | Polish: light/dark check, 2.0× text, low-end phones, privacy policy items | NFR · §9 | ⬜ |
| T23 | Full test pass + Play internal testing (signing key by owner) | TRD 20 | ⬜ |
| T24 | Ads switch (off at launch) | FR-X1–X2 | ⬜ (later) |

---

## How this file is updated (rules for the agent)

1. **Read this file first** in every session, before anything else.
2. When a task starts: move it to **🔄 Running**, set "Current".
3. When the build is done: **🧪 Owner testing**, with the exact phone check.
4. After the owner's OK (and commit/push only after the owner's yes): move to **✅ Done** with the date and commit.
5. Any new owner decision that changes the order or scope: update this file and `docs/PROGRESS.md` the same day.
6. Never mark a task Done that the owner has not tested.
