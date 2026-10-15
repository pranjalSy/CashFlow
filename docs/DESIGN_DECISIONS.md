# CashFlow: Design decisions (owner approved)

Ye file un faislon ki list hai jo design review mein liye gaye, aur jo `CashFlow_Master_Brief.md` / PRD se **alag** hain ya unme **naye** hain.
PRD / TRD update karte waqt ye list use karni hai. Design mockups: `design/screens/`, logo: `design/logo/`.

Last updated: 14 Oct 2026

## A. Brand

| # | Decision | Brief se farak |
|---|---|---|
| A1 | Logo "Rupee Track": ₹ + tick (trend line + dot). Files `design/logo/` | Naya |
| A2 | Brand indigo `#3B5BDB`, page Marble `#F2F8FC`, cards `#FFFFFF`, text Ink `#1F2A37`, secondary Slate `#5B6B7F` | Brief: sky blue `#5AB7F1`, page `#FAFCFF` |
| A3 | Meaning colours: Income `#15803D`, Expense `#C62828`, Lent `#2B4BC7`, Borrowed `#A3165A`, Due soon `#C2410C`, Premium `#B45309` | Brief: `#1FA971`, `#E5484D`, `#3B8EEA`, `#C2477A` (gehre kiye, text contrast ke liye) |
| A5 | Light muted/hint text `#8A97A8` → **`#808EA0`** in the app (contrast 2.77 → 3.12 on Marble page; found by the T01 test) | **Owner approved** (15 Oct) |
| A4 | Splash tagline "Track every rupee" | Naya |

## B. Glass, sheets, keypad

| # | Decision |
|---|---|
| B1 | Glass sirf: bottom nav pill, language screen ka bottom bar. Sab amounts solid surface par |
| B2 | Number pad (Add entry, Opening balance) **solid white**, keys `#F2F5FA` |
| B3 | Bottom sheets (category picker, repayment, person picker) **solid white** |
| B4 | Overlay ke peeche screen: `rgba(17,24,39,.42)` + blur 8px (ek hi blur layer) |

## C. First-run flow

| # | Decision | Brief se farak |
|---|---|---|
| C1 | Splash → Login/Sign up → (email ho to) Verify email → **Language** → Create PIN → Confirm PIN → Fingerprint → Opening balance → Contacts permission → Home | Language ab login ke **baad** alag full screen (search ke saath). Welcome par language chip nahi |
| C2 | Language list: 13 Indian languages, search (English + apni script). Launch par sirf English, Hindi, Gujarati chalu; baaki "Coming soon". Default English | Brief: sirf 3 |
| C3 | Verify email: code poora hone par **Verify button** dabana zaroori (auto-verify nahi) | Naya |
| C4 | PIN: 4 digit poore hote hi apne aap aage (button nahi) | Same |
| C5 | Biometric: **sirf fingerprint** (face nahi, Release 2 mein soch sakte). Sirf strong biometric. Sensor nahi to screen skip; sensor hai par set nahi to "Set up fingerprint first" | Brief: fingerprint ya face |

## D. Navigation

| # | Decision | Brief se farak |
|---|---|---|
| D1 | Bottom bar: glass pill, **4 tabs**: Home, Contacts, Charts, EMI & Bills. Active tab par naam. Alag blue "+" button | Brief: 5 tabs (Settings bhi) |
| D2 | Settings: Home header ke avatar par tap | Naya |
| D3 | "+" menu: right side, "+" ke upar **4 alag solid white buttons** (Expense, Income, Lent, Borrowed), 8px gap. "+" ghoom kar "×" | Brief: glass sheet Income/Expense; Contacts ka alag "+" hata diya |
| D4 | Contacts tab ka naam (heading + tab) "Contacts" | Same |

## E. Home

| # | Decision | Brief se farak |
|---|---|---|
| E1 | List mein **Income, Expense aur Udhar** (Lent/Borrowed) sab. Filter chips: All / Expense / Income / Udhar | Brief: Home par loans nahi |
| E2 | Har entry **alag card**, 8px gap | Naya |
| E3 | Swipe right→left: Edit + Delete buttons, ungli ke saath dheere dheere dikhte hain, normally chhupe. Soft glass style (blur nahi) | Naya |
| E4 | Full swipe (60%+) ya Delete button = **confirm sheet** "Delete this entry?" (Cancel / Delete), phir Undo 5 sec | Brief jaisa confirm (owner decision) |
| E5 | Kahin bhi aur tap / scroll = khula card band. Ek waqt mein ek | Naya |
| E6 | Udhar entry par tap = us person ki detail screen. Arrow nahi | Naya |
| E7 | Summary card par eye icon: amounts chhupao | Naya |
| E8 | Home header mein month picker ke left **gol search button** → Search (23, Premium) | Naya (owner approved) |

## F. Add entry

| # | Decision |
|---|---|
| F1 | Expense aur Income **ek hi screen**: amount, category, title, date, time, payment, note |
| F2 | **Compulsory:** Amount + Paid via / Received in (Cash ya Online → UPI/Card/Bank). Baaki optional |
| F3 | Date/Time na chuna to abhi ka ("Now" tag) |
| F4 | Save button kabhi disabled nahi; kuch bacha ho to laal border + message |
| F5 | Category picker: solid sheet, recent 4, 4-column grid (har category apna colour/icon), search, "Create" se nayi category |

## G. Udhar

| # | Decision | Brief se farak |
|---|---|---|
| G1 | Add Lent/Borrowed ek screen. Compulsory: Person, Amount, payment type | Same + payment compulsory |
| G2 | Person detail ke Lent/Borrowed button = form, naam pehle se | Same |
| G3 | **Due date bhi Premium** (Remind me pehle se Premium). Free user ko Premium tag + paywall; entry bina due date save | **Brief: due date free tha** |
| G4 | Due date Premium hone se: Person detail ka due tag aur Contacts tab ka "Due in X days" sirf Premium users ko; free users ko udhar ki date | Naya |
| G5 | **Zyada repayment allowed.** Sheet mein Save se upar hisaab (udhar chukaya / extra / total). Save par purana udhar Settled | **Brief: repayment baaki se zyada nahi** |
| G6 | Save ke baad sheet khuli rehti hai; button "Payment saved"; neeche sheet ke upar compact snackbar (54px, brand blue, 5 sec, Yes + ×) | Naya |
| G7 | Yes = extra amount ulti direction ka naya udhar (zyada diya → Lent, zyada mila → Borrowed). Yes nahi = sirf Settled; card par "₹X extra not added · Add as lent/borrowed" | Naya |
| G8 | Database rule safe: repayment row sirf baaki amount ka; extra hamesha alag nayi debt row | TRD rule same rehta hai |
| G9 | **Udhar due popup** (EMI jaisa): due ke din "Did you get it?" / "Did you pay it back?": Got full / Got some (amount + Cash/Online) / Not yet (+ Change due date). Premium. Mockup `14b_udhar_due_popup.html` | **Naya** |
| G10 | "Extend due date": nayi date, history mein "Due date changed: X → Y", reminder nayi date se. Premium | Brief mein tha, owner ne confirm kiya |

## I. EMI & Bills

| # | Decision | Brief se farak |
|---|---|---|
| I1 | Tab mein sirf **EMIs \| Bills**. Recurring income feature **hata diya**; salary normal Income entry se | **Brief 5.6: EMIs \| Bills \| Income** |
| I2 | Is tab par "+" = sirf Add EMI, Add bill | Naya |
| I3 | Bills: pehle **type** chuno (Electricity, Gas, Mobile, Internet, DTH, Water, Insurance, Other). **"Comes every N months"** (1/2/3/6/12; Torrent, Adani Gas = 2) + next due date; aage ki dates apne aap. Due ke din notification + popup "Did you pay this bill?" Yes = **pichle 3 bill ke amount suggestion chips** (ek tap) ya Other amount, Paid via compulsory, Expense · Bills mein add. Not yet = kal phir. "Same amount" switch hataya | **Brief: monthly/yearly + average.** Owner ka idea |
| I7 | **Budget**: Charts Spending tab ke upar chhota Budget card (tap = screen 21) + Settings mein Budget row. Export sirf Settings mein (Charts par nahi) | Owner: Claude decide kare / Export no |
| I8 | Premium/lock buttons har jagah **amber** `#B45309` (Charts 16 bhi) | Naya |
| I9 | Paywall par **Monthly ₹20 (default) aur Yearly ₹200 (Save 17%)** dono, ₹1 intro ke baad. Alag "upcoming dues" list nahi (cards kaafi). Bill pause/stop = should. Dark mode review agla task | Owner answers Q1–Q5 (PRD v2.0) |
| I6 | Online bill fetch (BBPS) Release 1 mein **nahi**: company registration, per-fetch kharcha, payment ke rules. Baad mein soch sakte | Owner discussion |
| I4 | EMI "Paid or not?" popup aur Charts "Include udhar" switch: rakhe (owner confirmed) | Same |
| I5 | EMI detail: "Mark paid" sirf agli due installment par. Mark paid sheet mein **Paid via compulsory** (Cash/Online → UPI/Card/Bank), pichli baar wala pehle se chuna. Installment Paid + expense ek saath; Undo 5 sec | Owner confirmed |

## J. Account

| # | Decision | Brief se farak |
|---|---|---|
| J1 | Delete account **turant** (koi 7/30 din undo nahi). Steps: kya hatega + Export first + Play Store cancel note → "Delete" type karo → PIN/fingerprint → Account deleted | Same as brief (owner confirmed) |
| J3 | Naye phone par login: purane phone se approval **ya** Gmail code (dono). Login ke baad saara data wapas | Brief same |
| J4 | **Kho gaya phone:** email code se login ke baad sheet "Lost your old phone?"; kisi phone par Sign out = phir email code, wo phone turant sign out; internet se judte hi us phone ka saara local data mit jata hai | **Owner idea, naya** |
| J5 | Devices list se Remove hamesha email code maangta hai | Naya |
| J6 | **Logout = phone se sab kuch mitao:** database, keys, cache, PIN/fingerprint setting, scheduled reminders, notification token. Ek bhi data nahi bachta (sirf user ki Downloads mein export files) | Brief same, owner ne pakka kiya |
| J2 | Confirm word "**Delete**" (DELETE capital nahi) | Naya |

## K. Dark mode (owner approved: Proper black + glass)

| # | Decision | Brief se farak |
|---|---|---|
| K1 | Dark style = **Proper black + glass**: page `#000` + brand glow (blue/purple/pink upar, blue neeche). Owner ne 3 styles (navy, black, black+glass) mein se chuna (`design/screens/dark/30_black_demo.html`) | Naya |
| K2 | **Cards = frosted glass** (rgba(255,255,255,.06), blur 18px, 1px light edge): summary, entries, lists, search, chips. **Sheets, popups, number pad, menus = solid `#141418`**. Bottom bar dark glass pill; "+" gradient + glow | B1 (amount sirf solid par) **dark mode mein badla**: cards glass par amounts allowed. Light mode same |
| K3 | Dark text/amount colours: text `#E8EDF5`, secondary `#A3B1C4`, income `#4ADE80`, expense `#F87171`, lent `#8EA2FF`, borrowed `#F472B6`, due `#FB923C`, premium `#FBBF24`. Buttons (white text, contrast 4.5+): brand `#4263EB`, income `#15803D`, expense `#DC2626`, premium `#B45309` | Naya |
| K4 | "Reduce glass effects" ya low-end phone: glass ki jagah solid `#111114` (same layout) | Same rule |
| K5 | Saari 31 dark screens ek token map se bani: `design/screens/dark/index.html`, tokens `00_dark_tokens.html` | Naya |

## H. Backend / privacy (discussion, final nahi)

| # | Topic | Status |
|---|---|---|
| H1 | Supabase (Mumbai) + Drift + FCM sahi stack | Agreed |
| H2 | **Release 1 = phone par encrypted DB + server par TLS/at-rest encryption + RLS (poora E2E nahi)**, taaki phone khone par data na khoye aur server reminders pakke rahein. Baad mein optional "Privacy mode (E2E)" recovery-code warning ke saath | **Owner decided** |
| H4 | **Fresh start:** purane project `D:\caseFlow` ka koi code, migration, test, theme ya widget reuse nahi. Flutter **3.44.7 hi rahega** (15 Oct: upgrade nahi; zaroorat padi to owner se poochhenge) | Owner (TRD v2.0 Q1–Q3) |
| H3 | Backup: free mein GitHub Actions weekly dump, baad mein Supabase Pro daily | Suggested |

## Pending decisions
Abhi koi nahi.
