# SpendSnap

Personal finance tracker. Flutter + Firebase. Track spending, set budgets, hit savings goals, scan receipts with on-device AI.

---

## Features

### Track money
- Log income + expenses with category, notes, date, recurring schedule
- Full transaction list — live search (note/amount/category), filters (type/category/date range)
- Edit + delete with optimistic updates
- Floating add button on activity page

### Categorize
- 31 built-in vector icons (food, transport, bills, etc.)
- Custom categories with icon + color picker
- Income/expense classification per category
- Default categories editable + deletable
- Inline "+ Add category" tile in transaction picker — no navigation needed
- Backward-compat with legacy emoji-based data

### Plan
- **Budgets** — monthly limits per category, progress rings, near-limit + over-limit alerts
- **Savings goals** — target amount, deadline, contribute flow, ring color shifts red → amber → green
- Combined "Plan" tab with Budgets + Savings sub-tabs

### Receipt scan (on-device AI)
- Camera capture → on-device OCR → AI parse → review screen → save as transaction
- Two-stage pipeline:
  1. **Google ML Kit** — text recognition runs fully on-device (Apple Vision on iOS, Google ML on Android)
  2. **Groq LLM API** — parses raw OCR text into structured JSON (merchant, amount, date, items, category guess)
- Review card shows extracted fields, lets user edit before save
- Picks expense category by default (Salary excluded from picker)

### Insights (rule-based)
- Weekend vs weekday spend pattern
- Category drift detection (50%+ MoM increase)
- Burn-rate projection (will you blow budget at current pace?)
- Unusual transaction flag (>2σ from 30-day mean)
- Savings streak achievements
- Dismissible + restorable
- Min data threshold (7 txns across 3 days) before generating

### Dashboard
- Overall spend ring + budget heatmap
- Active goal chips → tap to contribute
- Recent transactions feed
- Notification bell — combined badge for budget alerts + active insights
- Notification sheet with dismiss/restore for insights

### Auth
- Email + password
- Google Sign-In (OAuth)
- Persistent session via Firebase Auth state stream
- GoRouter redirect guards

### UX polish
- Glass/frosted floating pill nav (BackdropFilter blur + transparent fill)
- Editorial typography — Instrument Serif headings, JetBrains Mono for currency, system font body
- Warm beige + ink palette
- Offline banner on disconnect
- Keyboard auto-dismiss on tap-outside
- Smooth modal sheets with safe-area handling
- Dynamic safe-area override propagates pill clearance to all scroll views

---

## Architecture

Clean architecture + feature-first folder layout.

```
lib/
├── core/                 # Theme, routing, utils, DI
│   ├── routing/          # GoRouter + ShellRoute + MainShell (pill nav)
│   ├── theme/            # AppColors, AppTypography
│   └── utils/            # CurrencyFormatter, CategoryIcon, DateUtils
├── features/             # One folder per domain
│   ├── auth/
│   ├── transactions/
│   ├── categories/
│   ├── budgets/
│   ├── goals/
│   ├── analytics/
│   ├── dashboard/
│   ├── insights/
│   └── scan/             # Receipt OCR + AI parse
└── shared/widgets/       # Reusable: EmptyState, LoadingIndicator, etc.
```

Per-feature layers:
- **domain/** — models, business rules (pure Dart, no Flutter)
- **data/** — repositories, Firestore queries
- **presentation/** — BLoC (event/state/bloc) + pages + widgets

Dependencies flow inward: presentation → data → domain.

---

## State management

`flutter_bloc` (BLoC pattern). One bloc per domain:

| Bloc | Responsibility |
|---|---|
| AuthBloc | Sign-in/out, listens to `authStateChanges()` |
| TransactionBloc | CRUD, filter, search |
| CategoryBloc | Category CRUD, default seeding |
| BudgetBloc | Budget limits, calc spent/remaining |
| GoalBloc | Goal CRUD, contributions, completion |
| InsightBloc | Rule engine, dismiss/restore |

Events → bloc → state (`Loading | Loaded | Error`). UI rebuilds via `BlocBuilder`. Side-effects via `BlocListener`. `BlocProvider.value` propagates blocs into modal sheets.

---

## Tech stack

| Layer | Tech |
|---|---|
| UI | Flutter (Material 3) |
| State | flutter_bloc, equatable |
| Routing | go_router (ShellRoute) |
| Backend | Firebase Auth + Cloud Firestore |
| Auth | firebase_auth + google_sign_in |
| DI | get_it |
| Charts | fl_chart |
| Icons | lucide_icons + Material Icons |
| Fonts | google_fonts (Instrument Serif, JetBrains Mono) |
| OCR | google_mlkit_text_recognition (on-device) |
| LLM | Groq API (HTTP) |
| Storage | shared_preferences (prefs), Firestore (data) |
| Network | connectivity_plus, http |
| Env | flutter_dotenv |

---

## Data model

Firestore per-user collections:

```
users/{uid}/
├── transactions/{id}    # amount, type, categoryId, note, date, recurring
├── categories/{id}      # name, icon, color, isIncome, monthlyLimit?
├── goals/{id}           # title, targetAmount, currentAmount, deadline, status
└── prefs/...            # dismissed insight IDs, etc.
```

Budgets are derived from category `monthlyLimit` + transaction aggregation — no separate budget collection.

Firestore offline persistence enabled by default → cached reads, queued writes, syncs on reconnect.

---

## Setup

### Prereqs
- Flutter 3.19+
- Firebase project (Auth + Firestore enabled)
- iOS: Xcode 15+, CocoaPods
- Android: Android Studio, JDK 17
- Groq API key (free tier OK)

### Install

```bash
git clone https://github.com/KartavyaY/SpendSnap.git
cd SpendSnap/finance_app
flutter pub get
```

### Firebase config

`lib/firebase_options.dart` is gitignored. Generate:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

### Env vars

Create `.env` in project root:

```
GROQ_API_KEY=your_key_here
```

Loaded at startup via `flutter_dotenv`.

### Google Sign-In

Project starts in Firebase "Testing" mode — add your Gmail under **Google Cloud Console → APIs & Services → OAuth consent screen → Test users**. Publish flow requires Google review.

### Run

```bash
flutter run
```

---

## Permissions

- **iOS** (`Info.plist`): `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`
- **Android** (`AndroidManifest.xml`): `CAMERA`, `INTERNET`

---

## Privacy

- Receipt OCR runs fully on-device — image never leaves the phone for text extraction
- OCR text (not image) sent to Groq for structured parse
- Firestore writes go to user's own document tree (`users/{uid}/...`)
- Auth tokens managed by Firebase SDK
- No analytics or third-party tracking

---

## Roadmap

- [x] Email + Google auth
- [x] Transaction CRUD with categories + recurring
- [x] Search + filter activity
- [x] Budget limits + alerts
- [x] Savings goals with rings
- [x] Custom categories with income/expense classification
- [x] Rule-based insights with dismiss/restore
- [x] Notification panel
- [x] Lucide icon system
- [x] Receipt scanning (camera → ML Kit OCR → Groq LLM → transaction)
- [x] Glass pill nav with BackdropFilter
- [ ] Multi-currency
---

## License

Personal project. Not open-sourced.
