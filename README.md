# SpendSnap

A personal finance tracker built with Flutter and Firebase. Track expenses, set budgets, save toward goals, and get AI-powered insights — all in a clean, opinionated UI.

---

## What you can do today

### Track money
- **Log transactions** — income and expenses, with categories, notes, dates, and recurring schedules
- **Activity view** — full transaction list with live search (note, amount, category) and filters (type, category, date range)
- **Edit / delete** — full CRUD with optimistic updates

### Categorize
- 31 built-in Lucide vector icons (food, transport, shopping, bills, etc.)
- Custom categories with icon + color picker
- Backward-compatible with old emoji-based data

### Plan
- **Budgets** — set monthly limits per category, see progress rings, get over/near-limit alerts
- **Goals** — savings targets with contributions, progress rings that change color from red → amber → green based on completion
- Combined "Plan" tab for budgets and goals

### Insights (rule-based AI)
- Weekend vs. weekday spending pattern detection
- Category drift (50%+ month-over-month increases)
- Burn-rate projection (will you exceed budget at current pace?)
- Unusual transaction detection (>2σ from 30-day mean)
- Savings streak achievements (consecutive months of net savings)
- **Dismissible + restorable** — dismissed insights stay dismissed across re-generations
- Minimum data threshold (7 transactions across 3 unique days) before generating to avoid noise

### Notifications
- Bell icon with badge showing combined count of budget alerts + active insights
- Bottom sheet with budget alerts, active insights, and dismissed insights with "Restore"

### Auth
- Email/password
- Google Sign-In
- Persistent session

### UX polish
- Light/dark theme support
- Offline banner when network drops
- Keyboard auto-dismiss on tap outside (login + main app)
- Tappable goal chips on dashboard → quick contribute sheet

---

## On the roadmap: Receipt scanning with on-device AI

**Goal:** Tap the camera button → snap a photo of a receipt → AI extracts amount, date, merchant, and suggests a category → review and save as a transaction.

This is the next big feature. The plan is **on-device AI by default** so receipts never leave your phone.

### AI architecture options

We've evaluated three approaches:

#### Option A — Google ML Kit + custom parser (recommended for v1)
- **What it is:** ML Kit's text recognition (OCR) runs fully on-device. On iOS it uses Apple's Vision framework under the hood; on Android it uses Google's. We add a custom parser that scans the OCR text for `TOTAL`, currency-formatted numbers, dates, and merchant names.
- **Pros:** Cross-platform (iOS + Android), free, fully on-device, no model download, works on any modern phone, fast (sub-second).
- **Cons:** Receipts with messy layouts may need manual correction. Parsing is heuristic, not LLM-grade.
- **Privacy:** Image and text never leave the device.

#### Option B — Apple Intelligence (iOS-only enhancement)
- **What it is:** iOS 18.1+ Foundation Models framework gives access to a structured on-device LLM. Combined with Vision OCR, we can ask the LLM "extract amount, merchant, date as JSON" and get high-quality structured output.
- **Pros:** Smart parsing of messy receipts, handles edge cases (foreign currencies, split totals, tips), private (fully on-device).
- **Cons:** iOS 18.1+ only, requires A17 Pro or M-series chip (iPhone 15 Pro and newer), needs a Flutter platform channel to bridge Swift → Dart, doesn't help Android users.
- **When we'd add it:** As an iOS-only enhancement layered on top of Option A. If `FoundationModels` is available, use it; otherwise fall back to the ML Kit parser.

#### Option C — Cloud LLM (Claude / GPT vision)
- **What it is:** Send the receipt image to a cloud API (Anthropic Claude or OpenAI vision).
- **Pros:** Highest accuracy, handles any receipt layout.
- **Cons:** Costs money per scan, requires internet, image leaves the device, adds latency.
- **Decision:** Skip for v1. Could add later as an opt-in "premium accuracy" mode.

### Implementation plan

1. **Capture** — `image_picker` opens the native camera, returns a photo file
2. **OCR** — `google_mlkit_text_recognition` extracts text blocks on-device
3. **Parse** — custom Dart parser with heuristics:
   - **Amount:** find lines containing `TOTAL`, `AMOUNT`, `GRAND TOTAL`, `BALANCE`; pick the largest currency-formatted number near the bottom
   - **Date:** regex against common formats (`DD/MM/YYYY`, `MM-DD-YYYY`, `Jan 5 2024`, etc.)
   - **Merchant:** first 1–3 lines, filter out address-like lines
   - **Category hint:** keyword match against existing category names (e.g. "STARBUCKS" → Food)
4. **Review screen** — show captured photo + extracted fields, user edits if needed
5. **Save** — submit through existing `AddTransaction` event
6. **iOS enhancement (later):** platform channel calling Foundation Models for ambiguous receipts

### Permissions needed
- iOS: `NSCameraUsageDescription` in `Info.plist`
- Android: `<uses-permission android:name="android.permission.CAMERA" />`

### Privacy commitment
- v1 (ML Kit only): zero network calls for receipt processing
- v2 (Apple Intelligence): still zero network calls
- Cloud option, if added: opt-in only, with clear consent

---

## Tech stack

| Layer | Tech |
|---|---|
| UI | Flutter (Material 3) |
| State | flutter_bloc |
| Routing | go_router (ShellRoute with bottom nav) |
| Backend | Firebase Auth + Cloud Firestore |
| DI | get_it |
| Charts | fl_chart |
| Icons | lucide_icons |
| Fonts | google_fonts |

---

## Project structure

```
lib/
├── core/                    # Theme, routing, utils, DI
│   ├── routing/
│   ├── theme/
│   └── utils/
├── features/                # Feature-first organization
│   ├── auth/                # Login, signup, profile
│   ├── transactions/        # Add, edit, list, search, filter
│   ├── categories/          # Category CRUD with icon picker
│   ├── budgets/             # Monthly limits + goals (Plan tab)
│   ├── goals/               # Savings goals
│   ├── analytics/           # Charts and breakdowns
│   ├── dashboard/           # Home: rings, goals, recent activity, notifications
│   └── insights/            # Rule-based insight engine + bloc
└── shared/                  # Reusable widgets
```

Each feature follows: `domain/` (models, business rules) → `data/` (Firestore repos) → `presentation/` (bloc + pages + widgets).

---

## Setup

### Prerequisites
- Flutter 3.19+
- Firebase project with Auth (Email + Google) and Firestore enabled
- iOS: Xcode 15+, CocoaPods
- Android: Android Studio, JDK 17

### First run

```bash
git clone https://github.com/KartavyaY/SpendSnap.git
cd SpendSnap/finance_app
flutter pub get
```

### Firebase config

`lib/firebase_options.dart` is **gitignored** (contains API keys). Generate your own:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

Then run:

```bash
flutter run
```

### Google Sign-In

For your own Firebase project, you'll need to set up OAuth client IDs in the Firebase Console. While in development, your project is in "Testing" mode — add your own Gmail under **Google Cloud Console → APIs & Services → OAuth consent screen → Test users** so you can sign in. Publishing to verified status requires Google's review process.

---

## Roadmap

- [x] Email + Google auth
- [x] Transaction CRUD with categories, recurring
- [x] Search + filter activity
- [x] Budget limits with alerts
- [x] Savings goals with progress rings
- [x] Rule-based insight engine
- [x] Notification panel with dismiss/restore
- [x] Lucide icon system with legacy fallback
- [ ] **Receipt scanning (camera → OCR → AI parse → transaction)**
- [ ] CSV / PDF export
- [ ] Apple Intelligence integration for iOS 18.1+
- [ ] Multi-currency support
- [ ] Web build polish

---

## License

Personal project. Not yet open-sourced.
