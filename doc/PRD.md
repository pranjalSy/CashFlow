# PRD: CashFlow

**Owner:** Pranjal Paghadal · **Version:** 2.0 (14 Oct 2026) · **Status:** Approved by owner (14 Oct 2026) · **Audience:** the owner, AI coding agents, and any developer.

> **Hinglish:** Ye CashFlow app ka poora "kya banana hai" document hai. Har requirement ka ek ID hai (jaise FR-E4), taaki task mein seedha us ID ka naam liya ja sake. Design review ke saare faisle isme shaamil hain.

**Sources merged into this version**
- PRD v1.0 (`D:\caseFlow\docs\PRD.md`, Final v1.0 build baseline)
- `docs/CashFlow_Master_Brief.md` (8 Oct 2026)
- `docs/DESIGN_DECISIONS.md` (owner-approved design review, up to 14 Oct 2026)
- Mockups in `design/screens/` (screens 01–28) and the logo in `design/logo/`

**Rules for reading**
- Requirement IDs from v1.0 are kept. **[Changed]** means the owner changed it in the design review. **[New]** means it was added in v2.0. **[Removed]** means it is no longer built.
- Priority: **M** = must, **S** = should.
- If this PRD and a mockup disagree, this PRD wins. If this PRD and the TRD disagree, stop and ask the owner.
- Decision codes in brackets (for example `G5`) point to `docs/DESIGN_DECISIONS.md`.

---

## 1. Summary

> **Hinglish:** Ek mobile app jisme income, kharcha, udhar (diya / liya), EMI aur bills ka hisaab ho, aur har due date ka reminder aaye. Data phone par bhi aur cloud par bhi, isliye naya phone lene par login karte hi sab wapas.

CashFlow is an Android app (iOS later) for people in India to track income, expenses, money lent and borrowed (udhar), EMIs and recurring bills, with reminders for every due date. Data lives on the phone (encrypted, works offline) and in the cloud, so a new phone restores everything after login and approval. A low-cost subscription unlocks reminders, due dates, EMI and bills, charts, budget, export and search.

**Core promise:** never miss a due date · know where every rupee came from and went · works offline · private.
**Tagline:** "Track every rupee" (A4).

## 2. Goals and non-goals

**Goals**
- G1. One place for all money in, money out, and money owed.
- G2. Never miss a due date: reminders for udhar, EMIs and bills.
- G3. Fast, offline-first, automatic restore on a new device.
- G4. Safe: a new login must be approved from a trusted device or by email code.
- G5. Sustainable: subscription revenue covers running cost.

**Non-goals (Release 1)**
- Bank linking, reading SMS, or any automatic transaction import.
- Automatic bill fetch from providers (BBPS) (I6). The customer ID is stored so it can be added later.
- Shared ledgers, split bills, or sending payment requests to other people.
- Multiple currencies (INR only), web or desktop apps, receipt photos.
- Interest on personal udhar.
- **Recurring income** (salary reminders) [Removed] (I1). Salary is a normal Income entry.
- End-to-end encryption of cloud data (H2). An optional "Privacy mode" may come later (section 9).
- Face unlock (C5). Release 1 uses fingerprint only.

## 3. Users

Everyday people in India who lend and borrow informally, pay EMIs (bike, phone, loan), pay bills every 1–2 months (electricity, gas, mobile) and yearly premiums, use UPI, and want reminders. Many use mid-range phones (for example Realme on Android 13/14) with aggressive battery savers. Preferred language: English, Hindi or Gujarati.

## 4. Platforms and languages

- **Release 1: Android** (minimum Android 7, API 24). **Release 2: iOS.** One Flutter codebase; avoid Android-only packages when a cross-platform one exists.
- **Languages [Changed] (C2):** the language screen lists 13 Indian languages with search (English name and native script). At launch only **English, Hindi and Gujarati** work; the rest show "Coming soon". Default English.
- All user-facing text lives in localization files. "EMI" stays in Latin script in all languages; Hindi "उधार", Gujarati "ઉધાર".
- Currency: ₹ with Indian digit grouping (₹1,20,000). Dates in India time (IST).

## 5. Plans and pricing

> **Hinglish:** Free mein roz ka hisaab (income, kharcha, udhar) hamesha free. Reminders, due date, EMI, bills, charts, budget, export, search Premium mein. Shuruaat ₹1 mein 3 mahine.

| Plan | Price | Access | Ads |
|---|---|---|---|
| Intro (once per store account) | ₹1 for the first 3 months | Everything | No |
| Paid | ₹20/month or ₹200/year | Everything | No |
| Free | ₹0 | Income, expense, categories, udhar **without due dates or reminders** with per-person history, sync, device approval, app lock | Light ads later, behind a switch |

- **Premium-only:** udhar **due dates** [Changed] (G3) and udhar reminders, the udhar due popup, EMI, Bills, Budget, Charts, PDF/CSV export, transaction search (Home search button). The category search inside the add-entry form stays free.
- Free users see EMI & Bills and Charts as **locked tabs** (blurred preview + Try Premium card) (screen 28).
- When a plan ends: the user becomes Free, **keeps all data**, reminders stop, Premium screens become read-only.

## 6. Functional requirements

### 6.1 First run, account and login

> **Hinglish:** Pehli baar app kholne par: Splash → Login/Sign up → (email ho to verify) → Language → PIN → Fingerprint → Opening balance → Contacts permission → Home.

- FR-A1 (M) Sign in with **Google** or **email + password**; email must be verified with a 6-digit code. [Changed] (C3) The user taps a **Verify** button after typing the code (no auto-verify).
- FR-A4 (M) [New] (C1) First-run order: Splash → Login / Sign up → Verify email (email users) → **Language** (full screen with search, default English) → Create PIN → Confirm PIN → Fingerprint (if the phone has a sensor) → Opening balance → Contacts permission explainer → Home. The welcome screen has no language chip.
- FR-A2 (M) [Changed] (J6) **Logout erases everything on that phone:** the user-data database, encryption keys, cache, PIN and fingerprint setting, scheduled local reminders and the notification token. No user data may remain. Only files the user exported to Downloads stay (they are the user's own files). Cloud data stays safe and returns on the next login. The logout sheet says this in plain words. UI preferences (language, theme, reduce glass) may stay because they hold no user data.
- FR-A3 (M) [Changed] (J1, J2) Delete account is **immediate** (no waiting or undo period):
  1. Screen lists what is deleted (entries, EMI and bills, people, all devices signed out), from the phone **and** the cloud, cannot be undone. Shows "Export your data first" and, for Premium users, "Cancel Premium in Play Store; deleting the account does not stop billing".
  2. The user types **"Delete"** (any letter case accepted), then confirms with PIN or fingerprint.
  3. Server deletes all cloud data; the phone wipes everything as in FR-A2; screen "Account deleted". Backups clear within 7 days.
  4. Needs internet; offline shows "Connect to the internet to delete your account".
- FR-A5 (M) [New] Splash shows the logo and tagline; the app opens to the lock screen for returning users.

### 6.2 Home

> **Hinglish:** Home par is mahine ka balance, 4 rang ke tiles, aur saari entries (udhar bhi), har entry alag card mein. Swipe karke Edit/Delete.

- FR-O6 (M) Header: avatar (Google photo or first letter), greeting and name, **search button** [New] (E8), **month picker**. Everything on the screen follows the selected month. Tapping the avatar opens Settings [Changed] (D2).
- FR-O6a (M) Summary card: big number = **Balance at the end of the selected month** (opening balance + all Monthly Net values up to that month), cash and online balances shown separately (FR-O4), four tiles (Income green, Expense red, Lent blue, Borrowed pink), and a row "Net this month". An **eye icon** hides all amounts (E7).
- FR-H1 (M) [Changed] (E1) The list shows **income, expense and udhar** entries. Filter chips: **All / Expense / Income / Udhar**. Section "Transactions" with count, grouped by day.
- FR-H2 (M) [New] (E2) Every entry is a **separate card** with 8 px gap: icon tile, title, "category · payment · time" (or "Lent · Due 25 Oct · UPI"), amount (+green / −red / blue / pink).
- FR-H3 (M) [New] (E3, E5) **Swipe right-to-left** reveals Edit and Delete. Buttons are hidden normally and grow with the finger (soft glass style). Releasing past halfway keeps the card open; less springs back. Only one card open at a time; any other tap or scroll closes it.
- FR-H4 (M) [Changed] (E4) **Full swipe (60%+) or tapping Delete opens a confirm sheet** "Delete this entry?" showing the entry, with Cancel / Delete. Cancel returns the card. Delete removes it and shows a 5-second **Undo**. Deletes are soft deletes.
- FR-H5 (M) [New] (E6) Tapping an udhar entry opens that person's detail screen. Tapping an income/expense entry opens it for editing.
- FR-H6 (M) [Changed] (D3) The floating **+** opens a compact menu on the right, above the button: **four separate solid white buttons** (Expense, Income, Lent, Borrowed), 8 px apart; "+" rotates to "×". On the EMI & Bills tab the menu shows only **Add EMI** and **Add bill** (I2).
- FR-O7 (M) First setup asks the opening balance for cash and for online money (may be 0, skippable). The number pad is solid white (B2).

### 6.3 Add / edit income and expense

- FR-T1 (M) [Changed] (F1) Expense and Income use **one screen** with an Expense | Income switch (whole screen colour and sign change): amount, category, optional title (empty = category name), date, time, payment, note.
- FR-T6 (M) [New] (F2) **Required:** amount and **Paid via / Received in** (Cash or Online). Everything else is optional.
- FR-T2 (M) Online may specify **UPI, Card or Bank** (default UPI).
- FR-T7 (M) [New] (F3) If date and time are not chosen, the current date-time is used (shown with a "Now" tag).
- FR-T8 (M) [New] (F4) **Save is never disabled.** Missing required fields get a red border and a message ("Choose how you paid").
- FR-T3 (M) [Changed] (F5) Category picker: solid white sheet, 4 recent categories on top, 4-column grid (each category has its own colour and icon), search, "Create" for a new category (saved automatically and found next time). Income and expense categories are separate; default names in the user's language.
- FR-T9 (M) [New] The amount opens a solid white number pad (B2) with Indian commas as you type and a "." key for paise.
- FR-T4 (M) Filters and search across transactions (Premium search, section 6.10).
- FR-T5 (S) Monthly summary per category (Charts).

### 6.4 Contacts and udhar (lend / borrow)

> **Hinglish:** Contacts tab mein kitna lena hai / dena hai, recent log, aur saare phone contacts. Kisi par tap = us insaan ka poora hisaab. Zyada paisa wapas aaya to app poochti hai "extra ko naya udhar banaun?".

- FR-D9 (M) [Changed] (D4) The tab and heading are named **"Contacts"**. Top to bottom: To receive (blue) and To pay (pink) cards; the 5 most recent people with activity; search; all phone contacts A–Z with a letter index, each showing its net amount. If contact permission is off, a card explains and offers to turn it on. The tab has no separate "+" button (D3).
- FR-D7 (M) Person picked from phone contacts (normal contacts permission) or typed. Each person has the app's own id; name and normalized phone number are saved; the phone's contact id is only a local cache; the same number reuses the same person.
- FR-D10 (M) Contacts are read on the phone; only a contact used in an entry is saved to the cloud.
- FR-D8 (M) **Person detail:** net card ("Rahul owes you ₹3,000" / "You owe Amit ₹2,000"), buttons **Lent / Borrowed / Repayment**, history grouped by date, each udhar with a progress bar ("₹2,000 of ₹5,000 repaid"). The due tag shows only for Premium users; Free users see the udhar date (G4).
- FR-D1 (M) [Changed] (G1, G2, G3) **Add Lent / Borrowed** (one screen): person, amount, date, **payment type (required)**, note, and **due date + Remind me (Premium)**. Free users see a Premium tag; tapping opens the small paywall sheet and the entry is saved without a due date. From Person detail the name is filled in.
- FR-D2 (M) Partial repayments are separate records with amount, date and payment type. Status becomes open, partial or settled automatically.
- FR-D3 (M) [Changed] (G5–G8) **Overpayment is allowed.** In the repayment sheet a summary above Save shows "udhar repaid / extra / total". On Save:
  - The repayment row stores **only the remaining amount**, and the udhar becomes **Settled** (database rule "repayment ≤ remaining" stays true).
  - The sheet stays open, the button shows "Payment saved", and a compact snackbar appears on top of the sheet (54 px, brand blue, 5 s, **Yes** and ×): "₹2,000 extra. Add it as borrowed/lent?".
  - **Yes** creates a new udhar in the opposite direction for the extra (paid more → Lent; received more → Borrowed).
  - No answer: only Settled; the card shows "₹X extra not added · Add as lent/borrowed".
- FR-D11 (M) [New] (G9) **Udhar due popup (Premium):** on the due date (after the reminder, on app open) a popup asks "Did you get it?" (lent) or "Did you pay it back?" (borrowed):
  - **Got full / Paid full:** the remaining amount becomes a repayment (asks Cash/Online), udhar Settled.
  - **Got some / Paid some:** amount on an in-popup number pad + Cash/Online; shows what remains; keep or change the due date. More than remaining follows FR-D3.
  - **Not yet:** asks again next day; link "Change due date".
- FR-D4 (M) (G10) **Extend due date (Premium):** new date, history line "Due date changed: X → Y", reminders move to the new date.
- FR-D5 (M) Reminders (Premium): 3 or 7 days before, plus the due day.
- FR-D6 (M) Udhar is not income or expense; it moves cash/online balances (Loan In / Loan Out) (section 8).

### 6.5 EMI (Premium)

- FR-E1 (M) Add EMI: name (+ icon), lender (optional), item price, down payment (optional), loan amount (auto = price − down payment, or typed directly), yearly interest rate, first EMI date. The user chooses **"I know the: Months | EMI amount"** and enters one.
- FR-E2 (M) Months given → EMI calculated (reducing balance; zero interest = loan ÷ months). EMI given → months calculated, rounded up, with a smaller last installment.
- FR-E3 (M) Both stay editable; the result card updates live: EMI/month or months, total interest, total to pay, last EMI. Note that totals may differ slightly from the lender's schedule.
- FR-E9 (M) [New] If the EMI is not more than the monthly interest, show a red "Not possible" card with the reason (for example "Interest alone is ₹900 a month"). Save stays enabled; pressing it shakes the card and does not save.
- FR-E4 (M) Creating an EMI generates all installments. Day 29/30/31 uses the month's last day. The last installment is adjusted so totals are exact.
- FR-E5 (M) EMI list card: name, lender, rate, EMI/month, progress bar "4 of 12 paid · 8 left", "₹63,971 remaining", due tag (orange when under 7 days). Summary card "Due this month".
- FR-E10 (M) [New] (I5) **EMI detail:** hero card (remaining to pay, progress, end month), facts (EMI, loan, rate + total interest), installment list: earlier paid ones collapsed into one row, last paid, the **next due** one (orange border + **Mark paid**), then upcoming (dimmed). Each row shows date, amount and interest part. The screen scrolls to the due one.
- FR-E11 (M) [New] (I5) **Mark paid only on the next due installment** (in order). The Mark paid sheet (solid white) shows amount, "Paid on" (default today), **Paid via required** (Cash/Online → UPI/Card/Bank, last choice pre-selected). Mark paid = installment paid + an expense in category "EMI" in one atomic action; 5-second Undo. A paid installment can be opened and marked unpaid (removes the expense too).
- FR-E6 (M) Reminder before and on the due date; on app open a popup "Paid or not?" for each due installment (I4).
- FR-E7 (M) Popup **Paid** = same atomic action as FR-E11; **Not yet** asks again next open.
- FR-E8 (M) After the last installment the EMI shows as **Closed** (green) in a "Closed" section. The ⋯ menu has Edit EMI and Delete EMI (with confirm).

### 6.6 Bills (Premium)

> **Hinglish:** Bill ka type chuno, kitne mahine mein aata hai (Torrent aur Adani Gas = 2), aur due date. Due ke din app poochti hai "bill pay kiya?". Yes par pichle 3 bill ke amount chips mein, ek tap mein select.

- FR-B1 (M) [Changed] (I3) **Add bill, step 1:** pick a type: Electricity, Gas, Mobile, Internet, DTH / Cable, Water, Insurance, Other (each with its own icon and colour). Popular providers for the region (for example Torrent Power, Adani Total Gas) come pre-filled with their gap.
- FR-B6 (M) [New] (I3) **Step 2:** provider name, customer ID (optional, for reference only, never sent anywhere), **"Comes every N months"** (1, 2, 3, 6, 12), **next due date**, a preview of the next dates ("Then 15 Jan, 15 Mar, 15 May…"), usual amount (optional), Remind me (on due day / 3 days / 7 days before).
- FR-B2 (M) [Changed] (I3) On the due day: notification + popup **"Did you pay this bill?"** with **Yes, paid** / **Not yet**. Not yet = ask again tomorrow until paid.
- FR-B4 (M) [Changed] (I3) **Yes, paid:** the amounts of the **last 3 bills** appear as suggestion chips with month names (newest pre-selected), plus "Other amount" (number pad). First time: the usual amount (if given) as the chip, else the number pad. **Paid via is required.** Save = an expense in category **Bills** and the next due date moves forward by the gap (15 Nov + 2 months = 15 Jan). The old "Same amount every month" switch is removed.
- FR-B7 (M) [New] Bills list: grouped by this month / later; tags Due today (orange solid), Due in X days, Paid (green). Tap = bill detail with payment history, Edit and Delete.
- FR-B3 (S) Pause or stop a bill (kept in Release 1 as "should", Q4): a paused bill sends no reminders or popups until resumed.
- FR-B5 (later) Automatic bill fetch (BBPS) is out of scope for Release 1 (I6): it needs a registered business, an aggregator agreement and a per-fetch fee, and usually a payment flow. Reading SMS automatically is not planned (Play policy).

### 6.7 Overview and dues

- FR-O1 (M) Totals for the chosen month: income, expense, Money in, Money out, balance (Money in/out include Loan In/Out).
- FR-O2 (M) Total to receive and to pay (Contacts tab cards).
- FR-O3 (S) [Changed] (Q3) No separate "upcoming dues" list in Release 1. Dues are shown by the EMI & Bills summary card ("Due this month"), due tags on EMI/bill cards, and the Contacts tab ("Due in X days" for Premium).
- FR-O4 (M) Cash and online balances shown separately.
- FR-O5 [Removed] Monthly commitments view based on recurring income (recurring income removed, I1).

### 6.8 Reminders and notifications

- FR-R1 (M) Reminders are Premium; the server checks the plan before sending.
- FR-R2 (M) Lead time per item (on due day / 3 / 7 days before), default in Settings.
- FR-R3 (M) Server push plus local notifications, same id so a repeat replaces instead of duplicating.
- FR-R4 (M) Tapping a notification opens the item (and its due popup).
- FR-R5 (M) Help screen "Reminders not coming?" explains battery and auto-start settings (Realme and similar).
- FR-R6 (M) [New] Setting "Hide amounts in notifications": notification text has no amounts ("Open CashFlow to see details").

### 6.9 Sync and offline

- FR-S1 (M) Everything is saved on the phone first and works without internet.
- FR-S2 (M) On open the app fetches only changes since the last sync.
- FR-S3 (M) On a new device, login + approval downloads everything automatically.
- FR-S4 (M) Offline edits upload later with retry.
- FR-S5 (M) Deletes are soft deletes.
- FR-S6 (M) Conflict rule: the last edit to reach the server wins.
- FR-S7 (M) Linked actions (mark paid + create expense) sync together.
- FR-S8 (M) [New] (screen 28) Offline UI: a small grey bar "Offline · N changes saved on phone"; unsynced entries show a small clock icon; no blocking popups. Back online: automatic sync and a green toast "Back online · all synced" (2 s).
- FR-S9 (M) [New] Screens that need internet (login, device approval, Premium purchase, delete account) show "No internet" with Try again and say that entries work offline.

### 6.10 Device approval and lost phone

> **Hinglish:** Naye phone par login = purane phone se "Yes" ya Gmail code. Phone kho gaya to naye phone se purane ko sign out kar sakte ho (Gmail code ke saath), aur purane phone ka data internet se judte hi mit jaata hai.

- FR-V1 (M) The first device on an account is trusted automatically.
- FR-V2 (M) A login on another device stays **pending** and sees no data until approved. The new phone shows "Approve this phone" with the trusted phone's name and a 10-minute timer.
- FR-V3 (M) Trusted devices get "New login from [device]. Was this you?" (Yes, it's me / No, block). The app must be unlocked first. No = that phone is signed out and the request is recorded as Blocked. Only the device name and Android version are shown (no location).
- FR-V4 (M) (J3) No trusted device available: approve with a **6-digit email code** (one-time, 15 minutes, 5 attempts). The email address is partly hidden on screen.
- FR-V5 (M) Pending requests expire after 10 minutes.
- FR-V6 (M) [Changed] (J5) Settings → Devices lists all phones ("This phone" tag, last active) and recent requests (Approved / Blocked). **Remove always needs an email code**, then signs that phone out.
- FR-V8 (M) [New] (J4) **Lost phone:** after logging in with an email code, the new phone shows "Lost your old phone?" with the other phones. **Sign out** on one → new email code → that phone is signed out at once. When the lost phone next connects, the server refuses it and the app **erases all its local data** (FR-A2). Until then its data stays encrypted behind the PIN.
- FR-V7 (M) All access rules are enforced on the server.

### 6.11 Subscription and paywall

- FR-P1 (M) Google Play Billing (Apple In-App Purchase in Release 2).
- FR-P2 (M) Purchases verified on the server; plan stored in the cloud; daily status check.
- FR-P3 (M) (screen 26) Full paywall: 5 Premium benefits (Reminders, Due dates on udhar, EMI & Bills, Charts & Budget, Export & Search), offer card "₹1 for the first 3 months, then ₹20/month", a plan choice after the intro: **Monthly ₹20/month (pre-selected)** or **Yearly ₹200/year ("Save 17%", ₹16.7/month)** (Q1), button "Start for ₹1", fine print with the exact first full-charge date, the 3-day reminder and "Cancel in Play Store". No hidden terms.
- FR-P7 (M) [New] Small paywall sheet when a Free user taps a Premium item (for example Due date): explains that item, Try Premium, "See all features", "Not now"; the user's work is never lost.
- FR-P8 (M) [New] After purchase: "You're Premium!", next charge date, and what was switched on.
- FR-P4 (M) Notify the user 3 days before the first full-price charge.
- FR-P5 (M) Plan ends → Free, data kept, reminders stop, Premium screens read-only.
- FR-P6 (M) Restore purchases (top right of the paywall).
- FR-P9 (M) [New] (I8) All Premium and lock buttons use the Premium amber `#B45309`.

### 6.12 Ads (later)

- FR-X1 (S) Ads only for Free users, only when the remote setting `ads_enabled` is true. Off at launch.
- FR-X2 (S) Never on add/edit screens, popups, login, device approval or the paywall. No financial data shared with ad SDKs.

### 6.13 Settings

- FR-G1 (M) (screen 24) Opened from the Home avatar. Sections:
  - Profile card and plan card (Premium: renewal date + Manage; Free: benefits + "Try Premium · ₹1 for 3 months").
  - **General:** Language, Theme (System / Light / Dark), Default reminder, Hide amounts in notifications.
  - **Security:** App lock (PIN, fingerprint on/off, change PIN), Lock after (Immediately / 1 minute default / 5 minutes), Devices.
  - **Data:** Sync status, Export data, Budget.
  - **Display & privacy:** Reduce glass effects, Share anonymous usage (no amounts, names or notes).
  - **Help:** Reminders not coming?, Privacy policy & terms.
  - **Account:** Log out (confirm sheet), Delete account. Version at the bottom.

### 6.14 App lock

- FR-L1 (M) After the first login and before any data is shown, the user creates a 4-digit PIN (entered twice). Each PIN screen moves on automatically when 4 digits are entered (C4).
- FR-L2 (M) The PIN is stored only as a salted slow hash in secure storage, per device, never uploaded.
- FR-L3 (M) [Changed] (C5) **Fingerprint only** (strong biometric). If the phone has a fingerprint sensor with a finger enrolled, ask "Use fingerprint to unlock?". If it has a sensor but no finger, say "Set up fingerprint first" (open phone settings / skip). No sensor = skip the screen. Face unlock is not used in Release 1.
- FR-L4 (M) On Yes, verify once with the system prompt; enable only on success.
- FR-L5 (M) Every open: fingerprint first if enabled; PIN as the second option and fallback.
- FR-L6 (M) The app never reads or stores biometric data.
- FR-L7 (M) 5 wrong PINs = 30-second lock, longer afterwards; survives restarts.
- FR-L8 (M) Change PIN (old PIN required), fingerprint on/off, lock-after time.
- FR-L9 (M) Forgot PIN: sign in again with the account, then set a new PIN.
- FR-L10 (S) Hide the app preview in recent apps.

### 6.15 Recurring income [Removed]

- FR-I1 [Removed] (I1). Salary and other income are added as normal Income entries.

### 6.16 Budget (Premium)

- FR-BG1 (M) (screen 21) One monthly overall limit plus per-category limits. Overview card: spent, limit, percent ring, "₹6,500 left · 17 days · ₹382/day"; month picker for past months. Category rows with bars and "₹X left" or "₹X over".
- FR-BG3 (M) [New] Colour rule: under 80% green, 80–99% orange, 100%+ red.
- FR-BG4 (M) [New] Limit sheet (solid white): amount on a number pad, suggestions (average of the last 3 months and round numbers), "Alert me" on/off, Remove, Save. The limit repeats every month.
- FR-BG2 (M) Alerts at 80% and 100%, once per month each, respecting "Hide amounts".
- FR-BG5 (M) [New] (I7) Entry points: a small Budget card at the top of Charts → Spending (tap = Budget screen) and a Budget row in Settings. Only expenses count (udhar does not).

### 6.17 Charts, export and search (Premium)

- FR-C1 (M) Charts → **Spending:** budget card, donut by category with month total and change vs last month, "Include udhar" switch (off by default), category list with bars. **Trends:** income vs expense bars for 6 months, average income and expense, month card (income, expense, saved).
- FR-C2 (M) [Changed] (screen 22, I7) **Export** from Settings only (not from Charts): format PDF or CSV, date range (This month, Last month, 3 months, This year, Custom), include Income & expenses / Lent & borrowed / EMI & bills with counts; button shows the total entries. The file is made on the phone, saved to Downloads; result sheet with file name, pages, size, Open and Share. The report uses the user's language.
- FR-C3 (M) [Changed] (E8, screen 23) **Search** from the Home search button: searches entries (title, note, category, payment, amount) and people (name, number); filters All / Expense / Income / Udhar / People; results as you type, fully offline; People first, then entries newest first, matches highlighted; recent searches; clear empty state.

### 6.18 Look and feel

- FR-U1 (M) [Changed] (A2, A3) Soft, calm, premium and light. Colour tokens:

| Token | Value |
|---|---|
| Brand indigo | `#3B5BDB` (light `#5C7CFA`, soft `#91A7FF`) |
| Page (Marble) / cards | `#F2F8FC` / `#FFFFFF` |
| Text Ink / Slate | `#1F2A37` / `#5B6B7F` |
| Income / Expense | `#15803D` / `#C62828` |
| Lent / Borrowed | `#2B4BC7` / `#A3165A` |
| Due soon / Premium | `#C2410C` / `#B45309` |
| Accents | Blush `#FFD6E7`, Lavender `#E5DBFF` |
| Dark background | `#111827` |

- FR-U5 (M) [New] (A1) Logo "Rupee Track" (₹ with a rising tick). Files in `design/logo/` (SVG, PNG 1024/512/192/48, dark and mono variants).
- FR-U2 (M) [Changed] (B1–B4) **Glass only** on the bottom navigation pill and the language screen's bottom bar. Number pads, bottom sheets and popups are **solid white**. Overlays dim the screen with `rgba(17,24,39,.42)` + 8 px blur (one blur layer).
- FR-U6 (M) [New] (D1) Bottom bar: glass pill with **4 tabs** (Home, Contacts, Charts, EMI & Bills); the active tab shows its name; separate blue "+" button. Settings is not a tab.
- FR-U3 (M) Smooth continuous (squircle) corners matched to the device; layouts adapt to screen sizes, notches and system bars.
- FR-U4 (M) Amounts always on solid, high-contrast surfaces and never wrap or truncate. "Reduce glass effects" gives a solid fallback.
- FR-U7 (M) [New] Premium animations that stay smooth on low-end phones (short springs, no heavy blur stacks; reduce motion when the system asks).
- FR-U8 (M) [New] (screen 28) Empty states share one style (icon, one line, one button); Home shows a "Tap + to add" hint only the first time.
- FR-U9 (M) Font Inter (Noto Sans Devanagari and Gujarati for Hindi and Gujarati). Light and dark themes; Settings → Theme (System default / Light / Dark).
- FR-U10 (M) [New] (K1–K4) **Dark mode = proper black + glass:** page `#000` with a soft brand glow; cards are frosted glass (amounts allowed on dark glass); sheets, popups, number pads and menus stay solid `#141418`; bottom bar dark glass; dark meaning colours per `design/screens/dark/00_dark_tokens.html`. "Reduce glass effects" or low-end phones fall back to solid `#111114`.

### 6.19 Screens (design status)

All mockups are HTML files in `design/screens/` and are a **visual reference only**; build from the app's own widget library.

| # | Screen | Status |
|---|---|---|
| 01–09 | Splash, Login/Sign up, Language, Email, Verify email, Create PIN, Fingerprint (+cases), Opening balance, Contacts permission | Approved |
| 10, 10b | Home, swipe + "+" menu demo (with delete confirm) | Approved |
| 11–12 | Add expense/income, Category picker | Approved |
| 13–15, 14b | Contacts, Person detail (overpayment), Udhar due popup, Add lent/borrowed | Approved |
| 16 | Charts (with Budget card, amber lock) | Approved |
| 17–19 | EMI & Bills, Add EMI, EMI detail | Approved |
| 20 | Add bill (type → gap → popup → suggestion chips) | Approved |
| 21–28 | Budget, Export, Search, Settings, Devices & lost phone, Paywall, Delete account, Empty/locked/offline states | Owner reviewed, decisions applied |
| — | Dark mode versions of all screens (`design/screens/dark/`) | Approved style; all 31 generated |

### 6.20 Design ignore list (never build)

Profile icon at the top right; duplicate titles; status dots on avatars; call button on Person detail; "Initiation", "Completed", "UPI Ref" labels; footers like "Calculated and backed up"; "Surplus" badges; "Budget Health" cards; quick actions; SMS or bill-sync; split-bill; tips and promotions; arrows on udhar entries in the Home list (E6); a recurring-income tab (I1). Only what this PRD lists is built.

## 7. Non-functional requirements

- NFR-1 Screens open from local data in under 1 second on a mid-range phone.
- NFR-2 Money uses exact arithmetic: integer paise, never floating point.
- NFR-3 Row-level security on every cloud table; a user can never read another user's data.
- NFR-4 No secrets or service keys in the app or repo.
- NFR-5 Accessibility: readable font sizes (works at 2.0× text), sufficient contrast, 48 dp tap targets, light and dark themes.
- NFR-6 Works offline for everything except login, device approval, purchases and delete account.
- NFR-7 Crash and error reporting enabled (no personal data).
- NFR-8 The PIN wrong-attempt delay (FR-L7) is required.
- NFR-9 The phone database is encrypted with the key in secure storage; Android backup is disabled for app data. Traffic uses TLS; cloud data is encrypted at rest by the provider.
- NFR-10 [Confirmed] (H2) Cloud data is **not** end-to-end encrypted in Release 1, so a lost phone never means lost data and server reminders stay reliable. The code must keep an optional "Privacy mode (E2E)" possible later.
- NFR-11 Analytics: Firebase Analytics and Crashlytics only, never amounts, names, numbers or notes; user toggle in Settings.
- NFR-12 Contacts and phone numbers are disclosed in the privacy policy and the Play data-safety form.
- NFR-13 [New] Smooth on low-end phones: animations around 60 fps on a mid-range device; heavy effects drop to solid automatically or with "Reduce glass effects".
- NFR-14 [New] Logout and lost-phone wipe leave no user data on the device (verified by a test that inspects the app storage after logout).

## 8. Key rules and calculations (single source of truth)

1. Udhar (lent/borrowed and repayments) moves cash/online balances and Money in/out (Loan In / Loan Out) but is **not** income or expense in charts, budgets or savings, unless "Include udhar" is on in Charts.
2. Premium features are enforced on the server; the app only mirrors them.
3. Data is never deleted when a plan ends.
4. Instants stored in UTC; the user's local (IST) date is used for months and reminders.
5. Every synced record has `id`, `user_id`, `created_at`, `updated_at`, `deleted_at`; soft delete only.
6. A repayment row never exceeds the remaining amount; overpayment extra is always a separate new udhar (G8).

All amounts are integer paise. A month is chosen by the entry's own date in IST.

| Name | Formula |
|---|---|
| Total Income / Expense | Sum of income / expense entries dated in the month |
| Total Lent / Borrowed | Sum of new lent / borrowed entries dated in the month |
| **Monthly Net** | Income − Expense − Lent + Borrowed + Repayments received − Repayments paid |
| **Contact Net** (per person, all time) | (Lent − repayments received) − (Borrowed − repayments paid). Positive = the person owes the user |
| **Balance (end of month)** | Opening balance (cash + online) + all Monthly Net values up to that month |
| Bill suggestions | The last 3 paid amounts of that bill, newest first |
| Budget per day | (Limit − spent) ÷ days left in the month |

**EMI (reducing balance):** EMI = P·r·(1+r)^n / ((1+r)^n − 1), r = yearly rate ÷ 12 ÷ 100; zero rate: EMI = P ÷ n. Months from a chosen EMI: n = −ln(1 − P·r/EMI) / ln(1+r), rounded up, smaller last installment; if EMI ≤ monthly interest → "Not possible" (cap 600 months).

**Reference numbers (tests must use these):**
- Loan ₹90,000, 12% a year, 12 months → EMI **₹7,996.39** (799,639 paise); total interest ₹5,956.69; last installment ₹7,996.40; remaining after 4 paid ₹63,971.13.
- Same loan with EMI ₹8,500 → 12 months, last EMI ₹2,112.98. EMI ₹800 → Not possible (interest ₹900/month).
- Monthly Net: income 45,000, expense 28,500, lent 5,000, borrowed 2,000 → **13,500**.
- Contact Net: lent 5,000, repaid 2,000 → **3,000 to receive**.
- Overpayment: owe Rahul 3,000, pay 5,000 → repayment row 3,000, debt Settled; Yes → new Lent 2,000 to Rahul.

## 9. Privacy and security summary

> **Hinglish:** Phone ka data encrypted, cloud mein sirf apna data dikhe, naye phone ko approval chahiye, logout par phone saaf. Poora E2E abhi nahi (data khone ka khatra), baad mein optional.

- Encrypted phone database; key in secure storage; Android backup off.
- Cloud: TLS in transit, encryption at rest, row-level security, approved-device check on the server.
- New device approval (old phone or email code); lost-phone remote sign-out with wipe on reconnect.
- Contacts stay on the phone unless used in an entry. Logs and analytics never contain amounts, names, numbers or notes.
- Hide amounts in notifications; hide recent-apps preview; PIN + fingerprint lock.
- Later option: "Privacy mode (E2E)" for users who want it, with a clear warning that losing the recovery code and all phones means the data cannot be recovered.

## 10. Success metrics

- Day-7 retention; share of users who add at least one udhar, EMI or bill.
- Reminder delivery rate.
- Trial-to-paid conversion after the ₹1 period.
- Crash-free sessions above 99%.

## 11. Dependencies and costs

| Item | Note |
|---|---|
| Google Play developer account | Owner's brother's account: agree in writing on ownership and payouts |
| Supabase (Mumbai) and Firebase | Free tiers to start; Supabase Pro when real users depend on reminders. Backup: weekly database dump via GitHub Actions on the free plan (H3) |
| Email sender | Dedicated Gmail over SMTP for codes now (may land in spam); a domain sender before wide launch |
| Apple Developer Program, Mac or cloud build | Only for Release 2 |
| Store commission | About 15% on subscriptions (verify) |

## 12. Risks

- Sync bugs; reminder reliability on aggressive battery savers (help screen + server push + local backup).
- Price jump from ₹1 to ₹20 (clear disclosure, 3-day reminder).
- Three languages triple the text to review.
- Free Supabase project pausing after inactivity (daily job keeps it active).
- Lost-phone wipe only happens when that phone reconnects (data stays encrypted until then).
- The owner reviews results, not code: automated tests, plain reports and phone checks are essential.

## 13. Owner answers (14 Oct 2026)

| # | Question | Answer |
|---|---|---|
| Q1 | Yearly plan on the paywall? | **Show both**, monthly pre-selected (FR-P3, screen 26 updated) |
| Q2 | ₹1 intro price in India | OK: confirm in Play Console; fallback ₹10 intro or free trial |
| Q3 | Separate "upcoming dues" list? | **No**, the cards are enough (FR-O3) |
| Q4 | Pause / stop a bill? | **Yes**, "should" priority (FR-B3) |
| Q5 | Dark mode review before coding? | **Yes**, next design task |

## 14. Out of scope for AI agents (owner does these)

Store accounts and payments, Supabase and Firebase keys, production configuration, store listings, privacy policy sign-off, the Play Console agreement.

## 15. Glossary

**Paise:** 1/100 of a rupee. **Udhar:** informal lend/borrow. **EMI:** monthly loan installment. **Settled:** an udhar fully repaid. **RLS:** database rules on who can read or write rows. **Soft delete:** mark as deleted instead of removing. **E2E:** end-to-end encryption (only the user's phones can read the data). **BBPS:** Bharat Bill Payment System. **Premium:** the paid plan, including the ₹1 intro.

---

### Change log

| Version | Date | Change |
|---|---|---|
| 1.0 | Oct 2026 | Final build baseline (old project) |
| 2.0 | 14 Oct 2026 | Owner answered Q1–Q5 and approved. Merged the master brief and all design-review decisions (A1–J6, H2); new screens 01–28; recurring income removed; udhar due date Premium; overpayment flow; new bills flow; delete confirm on swipe; lost-phone sign-out; full logout wipe; fingerprint only; 13-language picker |
