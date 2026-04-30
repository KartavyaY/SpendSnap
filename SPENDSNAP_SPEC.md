# SpendSnap — Flutter Implementation Spec

> A complete build specification for an AI coding agent. Every section is prescriptive: when there's a choice, the choice has been made. Implement in the order given.

**Project**: SpendSnap — Personal Finance Tracker
**Course**: Mobile Application Development (CSL371)
**Stack**: Flutter 3.19+ · Dart 3.3+ · Firebase · flutter_bloc

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Tech Stack & Exact Dependencies](#2-tech-stack--exact-dependencies)
3. [Initial Setup](#3-initial-setup)
4. [Folder Structure](#4-folder-structure)
5. [Architecture Rules](#5-architecture-rules)
6. [Data Models](#6-data-models)
7. [Firestore Schema & Security Rules](#7-firestore-schema--security-rules)
8. [Feature Specs](#8-feature-specs)
9. [Custom Logic — Insight Engine](#9-custom-logic--insight-engine)
10. [UI/UX System](#10-uiux-system)
11. [Required Custom Widgets](#11-required-custom-widgets)
12. [Routing](#12-routing)
13. [Dependency Injection](#13-dependency-injection)
14. [Testing Requirements](#14-testing-requirements)
15. [Coding Conventions](#15-coding-conventions)
16. [Implementation Phases](#16-implementation-phases)
17. [Definition of Done Checklist](#17-definition-of-done-checklist)

---

## 1. Project Overview

SpendSnap is a personal finance tracker. Users log income and expenses, set per-category budgets, track savings goals, and receive rule-based insights about their spending habits.

### Core capabilities
- Email/password + Google sign-in (Firebase Auth)
- CRUD on transactions (income + expense)
- User-defined categories with icons and colors
- Monthly budgets per category with usage alerts
- Savings goals with progress tracking
- Smart insights engine (rule-based pattern detection)
- Visual analytics (pie, bar, line charts)
- Offline-first with cached data fallback

### Non-negotiables (graded)
- Must NOT look template-generated
- Must use **Bloc** for state (not Provider, not setState beyond UI animations)
- Must integrate Firebase Auth + Firestore
- Must include ≥3 custom reusable widgets
- Must include ≥1 non-trivial custom logic system (insight engine)
- Must include data visualization with interpretation
- Must handle edge cases (empty states, no internet, invalid input)
- Must include 3 widget tests + 2 integration tests

---

## 2. Tech Stack & Exact Dependencies

Use these **exact** versions in `pubspec.yaml`:

```yaml
name: spendsnap
description: Personal finance tracker built with Flutter and Firebase.
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.3.0 <4.0.0'
  flutter: '>=3.19.0'

dependencies:
  flutter:
    sdk: flutter

  # State management
  flutter_bloc: ^8.1.6
  equatable: ^2.0.5

  # Firebase
  firebase_core: ^2.32.0
  firebase_auth: ^4.20.0
  cloud_firestore: ^4.17.5
  google_sign_in: ^6.2.1

  # Routing
  go_router: ^14.0.0

  # DI
  get_it: ^7.7.0

  # Charts
  fl_chart: ^0.68.0

  # Utils
  intl: ^0.19.0
  uuid: ^4.4.0
  shared_preferences: ^2.2.3
  connectivity_plus: ^6.0.3
  cached_network_image: ^3.3.1

  cupertino_icons: ^1.0.6

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  bloc_test: ^9.1.7
  mocktail: ^1.0.3
  integration_test:
    sdk: flutter

flutter:
  uses-material-design: true
  assets:
    - assets/icons/
    - assets/images/
```

---

## 3. Initial Setup

Execute these commands in order:

```bash
# 1. Create the project
flutter create --org com.spendsnap --project-name spendsnap spendsnap
cd spendsnap

# 2. Install Firebase CLI tools
npm install -g firebase-tools
dart pub global activate flutterfire_cli

# 3. Login & configure Firebase
firebase login
flutterfire configure --project=spendsnap-<your-id>

# 4. Replace pubspec.yaml with the version in §2, then:
flutter pub get

# 5. Set minimum SDK in android/app/build.gradle
# minSdkVersion 21  (required for Firebase Auth)
```

After `flutterfire configure`, `lib/firebase_options.dart` is auto-generated. Do not edit it manually.

In Firebase Console:
1. Enable **Authentication** → Email/Password and Google providers
2. Create **Firestore Database** in production mode (rules below)
3. Add SHA-1 fingerprint for Android Google Sign-In

---

## 4. Folder Structure

Create exactly this structure. Every file path in this spec assumes it.

```
lib/
├── main.dart
├── app.dart
├── firebase_options.dart            # auto-generated
│
├── core/
│   ├── theme/
│   │   ├── app_colors.dart
│   │   ├── app_typography.dart
│   │   └── app_theme.dart
│   ├── routing/
│   │   └── app_router.dart
│   ├── di/
│   │   └── service_locator.dart
│   ├── utils/
│   │   ├── date_utils.dart
│   │   ├── currency_formatter.dart
│   │   └── validators.dart
│   └── error/
│       └── failures.dart
│
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   └── auth_repository.dart
│   │   ├── domain/
│   │   │   └── user_model.dart
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── auth_bloc.dart
│   │       │   ├── auth_event.dart
│   │       │   └── auth_state.dart
│   │       └── pages/
│   │           ├── login_page.dart
│   │           └── signup_page.dart
│   │
│   ├── transactions/
│   │   ├── data/
│   │   │   └── transaction_repository.dart
│   │   ├── domain/
│   │   │   └── transaction_model.dart
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── transaction_bloc.dart
│   │       │   ├── transaction_event.dart
│   │       │   └── transaction_state.dart
│   │       └── pages/
│   │           ├── transaction_list_page.dart
│   │           └── add_transaction_page.dart
│   │
│   ├── categories/
│   │   ├── data/
│   │   │   └── category_repository.dart
│   │   ├── domain/
│   │   │   └── category_model.dart
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── category_bloc.dart
│   │       │   ├── category_event.dart
│   │       │   └── category_state.dart
│   │       └── pages/
│   │           └── categories_page.dart
│   │
│   ├── budgets/
│   │   ├── data/
│   │   │   └── budget_repository.dart
│   │   ├── domain/
│   │   │   └── budget_model.dart
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── budget_bloc.dart
│   │       │   ├── budget_event.dart
│   │       │   └── budget_state.dart
│   │       └── pages/
│   │           └── budget_page.dart
│   │
│   ├── goals/
│   │   ├── data/
│   │   │   └── goal_repository.dart
│   │   ├── domain/
│   │   │   └── goal_model.dart
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── goal_bloc.dart
│   │       │   ├── goal_event.dart
│   │       │   └── goal_state.dart
│   │       └── pages/
│   │           └── goals_page.dart
│   │
│   ├── insights/
│   │   ├── domain/
│   │   │   ├── insight_engine.dart
│   │   │   └── insight_model.dart
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── insight_bloc.dart
│   │       │   ├── insight_event.dart
│   │       │   └── insight_state.dart
│   │       └── widgets/
│   │           └── insight_card.dart
│   │
│   ├── analytics/
│   │   └── presentation/
│   │       ├── pages/
│   │       │   └── analytics_page.dart
│   │       └── widgets/
│   │           ├── category_pie_chart.dart
│   │           ├── monthly_bar_chart.dart
│   │           └── balance_line_chart.dart
│   │
│   └── dashboard/
│       └── presentation/
│           └── pages/
│               └── dashboard_page.dart
│
└── shared/
    └── widgets/
        ├── spend_ring.dart           # Custom widget #1
        ├── transaction_tile.dart     # Custom widget #2
        ├── empty_state.dart          # Custom widget #3
        ├── primary_button.dart
        └── loading_indicator.dart

test/
├── widget/
│   ├── spend_ring_test.dart
│   ├── transaction_tile_test.dart
│   └── empty_state_test.dart
└── integration/
    ├── auth_flow_test.dart
    └── transaction_crud_test.dart
```

---

## 5. Architecture Rules

### Layer separation (strict)

| Layer | Responsibility | Imports allowed |
|---|---|---|
| **Presentation** | Widgets, pages, Bloc | Bloc, models, shared widgets |
| **Domain** | Models, business logic | Nothing Flutter-specific |
| **Data** | Repositories, Firebase calls | Domain models, Firebase SDKs |

**Rules:**
- A widget NEVER imports `cloud_firestore` or `firebase_auth`. It talks to a Bloc.
- A Bloc NEVER imports `cloud_firestore` or `firebase_auth`. It calls a repository.
- Domain models (`*_model.dart`) NEVER import `package:flutter/...`. They are pure Dart.
- The `InsightEngine` is pure Dart — no Flutter, no Firebase imports.

### Bloc pattern

Every Bloc follows this structure:

```dart
// transaction_event.dart
abstract class TransactionEvent extends Equatable {
  const TransactionEvent();
  @override
  List<Object?> get props => [];
}

class LoadTransactions extends TransactionEvent {}
class AddTransaction extends TransactionEvent {
  final TransactionModel transaction;
  const AddTransaction(this.transaction);
  @override
  List<Object?> get props => [transaction];
}
// ... DeleteTransaction, UpdateTransaction, FilterTransactions
```

```dart
// transaction_state.dart
abstract class TransactionState extends Equatable {
  const TransactionState();
  @override
  List<Object?> get props => [];
}

class TransactionInitial extends TransactionState {}
class TransactionLoading extends TransactionState {}
class TransactionLoaded extends TransactionState {
  final List<TransactionModel> transactions;
  const TransactionLoaded(this.transactions);
  @override
  List<Object?> get props => [transactions];
}
class TransactionError extends TransactionState {
  final String message;
  const TransactionError(this.message);
  @override
  List<Object?> get props => [message];
}
```

```dart
// transaction_bloc.dart
class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  final TransactionRepository repository;
  StreamSubscription? _sub;

  TransactionBloc(this.repository) : super(TransactionInitial()) {
    on<LoadTransactions>(_onLoad);
    on<AddTransaction>(_onAdd);
    on<DeleteTransaction>(_onDelete);
    on<UpdateTransaction>(_onUpdate);
  }

  Future<void> _onLoad(LoadTransactions e, Emitter<TransactionState> emit) async {
    emit(TransactionLoading());
    await emit.forEach<List<TransactionModel>>(
      repository.watchTransactions(),
      onData: (txns) => TransactionLoaded(txns),
      onError: (err, _) => TransactionError(err.toString()),
    );
  }

  // ... other handlers

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
```

---

## 6. Data Models

All models are immutable, use `Equatable`, and have `fromFirestore` / `toFirestore` methods.

### UserModel — `lib/features/auth/domain/user_model.dart`

```dart
import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String uid;
  final String email;
  final String displayName;
  final String currency;        // e.g. 'INR', 'USD'
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.currency,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) => UserModel(
    uid: uid,
    email: map['email'] as String,
    displayName: map['displayName'] as String? ?? '',
    currency: map['currency'] as String? ?? 'INR',
    createdAt: (map['createdAt'] as Timestamp).toDate(),
  );

  Map<String, dynamic> toMap() => {
    'email': email,
    'displayName': displayName,
    'currency': currency,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  @override
  List<Object?> get props => [uid, email, displayName, currency, createdAt];
}
```

### TransactionModel — `lib/features/transactions/domain/transaction_model.dart`

```dart
enum TransactionType { income, expense }

class TransactionModel extends Equatable {
  final String id;
  final String uid;
  final double amount;
  final TransactionType type;
  final String categoryId;
  final String? note;
  final DateTime date;
  final bool isRecurring;
  final String? recurringFrequency;  // 'weekly' | 'monthly'

  const TransactionModel({
    required this.id,
    required this.uid,
    required this.amount,
    required this.type,
    required this.categoryId,
    this.note,
    required this.date,
    this.isRecurring = false,
    this.recurringFrequency,
  });

  // factory fromFirestore(DocumentSnapshot doc) ...
  // Map<String, dynamic> toFirestore() ...

  @override
  List<Object?> get props => [id, uid, amount, type, categoryId, note, date, isRecurring];
}
```

### CategoryModel — `lib/features/categories/domain/category_model.dart`

```dart
class CategoryModel extends Equatable {
  final String id;
  final String uid;
  final String name;
  final String icon;       // emoji string, e.g. '🍔'
  final String color;      // hex string, e.g. '#7F77DD'
  final double? monthlyLimit;
  final bool isDefault;    // pre-seeded categories

  // ... constructor, fromFirestore, toFirestore, props
}
```

### GoalModel — `lib/features/goals/domain/goal_model.dart`

```dart
enum GoalStatus { active, completed, abandoned }

class GoalModel extends Equatable {
  final String id;
  final String uid;
  final String title;
  final double targetAmount;
  final double currentAmount;
  final DateTime? deadline;
  final GoalStatus status;
  final DateTime createdAt;

  double get progress => (currentAmount / targetAmount).clamp(0.0, 1.0);
  // ...
}
```

### Default categories (seed on first signup)

```dart
const defaultCategories = [
  {'name': 'Food', 'icon': '🍔', 'color': '#D85A30'},
  {'name': 'Transport', 'icon': '🚗', 'color': '#378ADD'},
  {'name': 'Shopping', 'icon': '🛍️', 'color': '#D4537E'},
  {'name': 'Bills', 'icon': '📄', 'color': '#BA7517'},
  {'name': 'Entertainment', 'icon': '🎬', 'color': '#7F77DD'},
  {'name': 'Health', 'icon': '🏥', 'color': '#1D9E75'},
  {'name': 'Salary', 'icon': '💰', 'color': '#639922'},
  {'name': 'Other', 'icon': '📦', 'color': '#888780'},
];
```

---

## 7. Firestore Schema & Security Rules

### Collection structure (flat, scoped by `uid`)

```
users/{uid}
  - email, displayName, currency, createdAt

transactions/{txnId}
  - uid, amount, type, categoryId, note, date, isRecurring, recurringFrequency

categories/{categoryId}
  - uid, name, icon, color, monthlyLimit, isDefault

goals/{goalId}
  - uid, title, targetAmount, currentAmount, deadline, status, createdAt
```

### Security rules — `firestore.rules`

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    function isOwner(uid) {
      return request.auth != null && request.auth.uid == uid;
    }

    match /users/{uid} {
      allow read, write: if isOwner(uid);
    }

    match /transactions/{id} {
      allow read: if isOwner(resource.data.uid);
      allow create: if isOwner(request.resource.data.uid);
      allow update, delete: if isOwner(resource.data.uid);
    }

    match /categories/{id} {
      allow read: if isOwner(resource.data.uid);
      allow create: if isOwner(request.resource.data.uid);
      allow update, delete: if isOwner(resource.data.uid);
    }

    match /goals/{id} {
      allow read: if isOwner(resource.data.uid);
      allow create: if isOwner(request.resource.data.uid);
      allow update, delete: if isOwner(resource.data.uid);
    }
  }
}
```

### Required indexes

Create composite indexes in Firebase Console for:
- `transactions`: `uid ASC` + `date DESC`
- `transactions`: `uid ASC` + `type ASC` + `date DESC`
- `transactions`: `uid ASC` + `categoryId ASC` + `date DESC`

---

## 8. Feature Specs

### 8.1 Authentication

**Routes**: `/login`, `/signup`

**Acceptance criteria:**
- Email/password signup with validation (email format, password ≥ 6 chars)
- Email/password login
- Google Sign-In button
- On first signup: create `users/{uid}` doc + seed default categories
- Persist auth state across app restarts
- Logout from drawer/profile menu
- Show loading indicator during auth operations
- Show inline error messages (not snackbars) for auth failures

**AuthBloc events**: `AuthCheckRequested`, `LoginRequested`, `SignupRequested`, `GoogleSignInRequested`, `LogoutRequested`

**AuthBloc states**: `AuthInitial`, `AuthLoading`, `Authenticated(user)`, `Unauthenticated`, `AuthError(message)`

### 8.2 Transactions

**Routes**: `/transactions`, `/transactions/add`, `/transactions/edit/:id`

**Acceptance criteria:**
- List all transactions, sorted by date (newest first)
- Filter by: date range, type (income/expense/all), category
- Search by note text (client-side, case-insensitive)
- Add via floating action button → bottom sheet form
- Form fields: amount, type toggle, category dropdown, date picker, optional note, recurring toggle
- Validation: amount > 0, category required
- Edit by tapping a transaction tile
- Delete via swipe-to-dismiss with confirmation dialog
- Empty state when no transactions: illustration + "Add your first transaction" CTA
- Real-time updates via Firestore stream

### 8.3 Categories

**Route**: `/categories`

**Acceptance criteria:**
- Grid view of all categories with icon + name
- Add custom category: name, emoji picker (or text input), color picker (preset palette)
- Edit category (default categories cannot be deleted, only edited)
- Delete custom category (must reassign transactions or block if used)
- Set monthly budget per category from this screen

### 8.4 Budgets

**Route**: `/budgets`

**Acceptance criteria:**
- List categories with their `monthlyLimit` and current month's spend
- Progress bar per category: green (<70%), amber (70–100%), red (>100%)
- Tap to edit budget amount
- Show overall monthly budget at the top (sum of all category budgets)
- Show "Days left in month" indicator
- Project end-of-month spend based on current burn rate

### 8.5 Goals

**Route**: `/goals`

**Acceptance criteria:**
- List active goals with progress ring (custom widget — `SpendRing`)
- Add new goal: title, target amount, optional deadline
- Add contribution to a goal (creates a `goal_contribution` transaction tagged to it — or just update `currentAmount`)
- Mark goal as complete
- Show achieved goals in a separate section
- Animation when contribution is added (ring fills smoothly)

### 8.6 Insights — see [§9](#9-custom-logic--insight-engine)

### 8.7 Analytics

**Route**: `/analytics`

**Acceptance criteria:**
- Pie chart: spending by category for current month (use `fl_chart`)
- Bar chart: last 6 months income vs expense
- Line chart: balance over the last 30 days
- Each chart MUST have a 1-line interpretation below it (e.g., "Food is your top spending category at 34%")
- Date range selector at top: This month / Last 3 months / Last 6 months / This year
- Empty state when no data

### 8.8 Dashboard (home screen)

**Route**: `/`

**Acceptance criteria:**
- Greeting with user's name + current month
- Big balance card: this month's income, expense, net
- "Top insight" card from InsightBloc
- Mini pie chart of category spending (tap → goes to /analytics)
- Recent 5 transactions
- Active goals carousel
- Bottom nav: Home, Transactions, Analytics, Goals, Profile

---

## 9. Custom Logic — Insight Engine

This is the **graded custom logic system**. It lives in `lib/features/insights/domain/insight_engine.dart` as a pure Dart class.

### Insight model

```dart
enum InsightType { warning, observation, achievement, projection }
enum InsightSeverity { info, low, medium, high }

class Insight extends Equatable {
  final String id;
  final InsightType type;
  final InsightSeverity severity;
  final String title;
  final String description;
  final String? actionLabel;
  final DateTime generatedAt;

  // ...
}
```

### The engine

```dart
class InsightEngine {
  List<Insight> generate({
    required List<TransactionModel> transactions,
    required List<CategoryModel> categories,
    required DateTime now,
  }) {
    final insights = <Insight>[];
    insights.addAll(_weekendSpendingRule(transactions, now));
    insights.addAll(_categoryDriftRule(transactions, categories, now));
    insights.addAll(_burnRateProjectionRule(transactions, categories, now));
    insights.addAll(_unusualTransactionRule(transactions, now));
    insights.addAll(_savingsStreakRule(transactions, now));
    return insights..sort((a, b) => b.severity.index.compareTo(a.severity.index));
  }

  // Each rule is a private method that returns 0+ insights.
}
```

### Required rules (implement all 5)

**Rule 1: Weekend spending ratio**
- Compute total expense on Sat+Sun vs Mon–Fri (current month, normalized per day)
- If weekend per-day spend > 1.5× weekday per-day spend → emit observation
- Title: `"You spend more on weekends"`
- Description: `"Your weekend daily spend is X% higher than weekdays. Consider planning weekend budgets."`

**Rule 2: Category drift**
- For each category, compare this month's spend vs last month's
- If `(thisMonth - lastMonth) / lastMonth > 0.5` (50% increase) AND `thisMonth > 1000` → emit warning
- Title: `"<Category> spending is up X%"`
- Description: `"You've spent ₹X on <Category> this month, up from ₹Y last month."`

**Rule 3: Burn rate projection**
- For each category with a `monthlyLimit`:
  - `daysIntoMonth = today.day`
  - `daysInMonth = totalDaysInMonth`
  - `projectedSpend = currentSpend / daysIntoMonth * daysInMonth`
  - If `projectedSpend > monthlyLimit * 1.1` AND `daysIntoMonth >= 7` → emit projection
- Title: `"<Category> on track to exceed budget"`
- Description: `"At current pace, you'll spend ₹X by month-end (budget: ₹Y)."`

**Rule 4: Unusual transaction**
- Compute mean and stddev of expense amounts in the last 30 days
- For each new transaction in the last 7 days where `amount > mean + 2*stddev` → emit observation
- Title: `"Unusual transaction detected"`
- Description: `"A ₹X expense on <date> is significantly higher than your typical spending."`

**Rule 5: Savings streak**
- Count consecutive months where `income > expense`
- If streak ≥ 2 → emit achievement
- Title: `"X-month savings streak"`
- Description: `"You've spent less than you earned for X months in a row. Keep it up!"`

### Testability

Every rule must be a **pure function** of its inputs. No `DateTime.now()` calls inside rules — accept `now` as a parameter. This makes unit testing trivial:

```dart
test('weekend spending rule fires when ratio exceeds 1.5', () {
  final txns = [
    // 2 weekend txns of 1000 each (1000/day)
    TransactionModel(/*date: Saturday*/, amount: 1000, ...),
    TransactionModel(/*date: Sunday*/, amount: 1000, ...),
    // 5 weekday txns of 200 each (200/day = 5x lower)
    // ...
  ];
  final engine = InsightEngine();
  final result = engine.generate(transactions: txns, categories: [], now: testDate);
  expect(result.any((i) => i.title.contains('weekends')), isTrue);
});
```

---

## 10. UI/UX System

### Color palette (custom, NOT Flutter defaults)

In `lib/core/theme/app_colors.dart`:

```dart
class AppColors {
  // Primary — deep teal (uncommon, distinctive)
  static const primary = Color(0xFF0F6E56);
  static const primaryLight = Color(0xFF1D9E75);
  static const primaryDark = Color(0xFF085041);

  // Accent — warm coral
  static const accent = Color(0xFFD85A30);

  // Semantic
  static const success = Color(0xFF639922);
  static const warning = Color(0xFFBA7517);
  static const danger = Color(0xFFE24B4A);
  static const info = Color(0xFF378ADD);

  // Neutrals
  static const bgPrimary = Color(0xFFFAFAF7);
  static const bgSecondary = Color(0xFFF1EFE8);
  static const surface = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF2C2C2A);
  static const textSecondary = Color(0xFF5F5E5A);
  static const textTertiary = Color(0xFF888780);
  static const border = Color(0x33888780);

  // Dark mode counterparts
  static const darkBgPrimary = Color(0xFF1A1A19);
  static const darkSurface = Color(0xFF2C2C2A);
  // ...
}
```

### Typography

In `lib/core/theme/app_typography.dart`:

```dart
class AppTypography {
  static const _family = 'Inter';  // Add Inter to assets, or use GoogleFonts

  static const displayLarge = TextStyle(
    fontFamily: _family, fontSize: 32, fontWeight: FontWeight.w600, height: 1.2,
  );
  static const headingLarge = TextStyle(
    fontFamily: _family, fontSize: 22, fontWeight: FontWeight.w600, height: 1.3,
  );
  static const headingMedium = TextStyle(
    fontFamily: _family, fontSize: 18, fontWeight: FontWeight.w500, height: 1.3,
  );
  static const bodyLarge = TextStyle(
    fontFamily: _family, fontSize: 16, fontWeight: FontWeight.w400, height: 1.5,
  );
  static const bodyMedium = TextStyle(
    fontFamily: _family, fontSize: 14, fontWeight: FontWeight.w400, height: 1.5,
  );
  static const caption = TextStyle(
    fontFamily: _family, fontSize: 12, fontWeight: FontWeight.w400, height: 1.4,
  );
  static const numeric = TextStyle(
    fontFamily: _family, fontSize: 24, fontWeight: FontWeight.w600,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}
```

### Theme

In `lib/core/theme/app_theme.dart`, build a `ThemeData` with:
- `useMaterial3: true`
- Custom `ColorScheme.fromSeed` overridden with `AppColors.primary`
- All text styles from `AppTypography`
- `inputDecorationTheme` with rounded borders (12px)
- `cardTheme` with 0px elevation, 16px border radius
- `elevatedButtonTheme` with 12px radius, 48px height

Support both light and dark themes. Switch via `ThemeMode.system` by default, with manual override in settings.

### Micro-interactions (≥2 required)

1. **Animated balance counter** on dashboard — when transactions update, the balance number animates from old → new value over 600ms (use `TweenAnimationBuilder<double>`).
2. **Goal ring fill animation** — when contributing to a goal, the ring fills smoothly with `AnimatedBuilder` + custom painter.

---

## 11. Required Custom Widgets

These three are graded. They MUST be in `lib/shared/widgets/` and used in multiple places.

### 11.1 `SpendRing` — circular progress with center label

```dart
class SpendRing extends StatelessWidget {
  final double progress;        // 0.0 to 1.0
  final double size;
  final Color color;
  final Color backgroundColor;
  final String? centerLabel;
  final String? centerSubLabel;
  final double strokeWidth;

  // Use CustomPainter for the ring
  // Use TweenAnimationBuilder for animation when progress changes
}
```

Used in: dashboard (budget overview), goals page (per-goal), categories page.

### 11.2 `TransactionTile` — list item

```dart
class TransactionTile extends StatelessWidget {
  final TransactionModel transaction;
  final CategoryModel category;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final bool dense;

  // Layout: [icon circle] [name + note + date] [amount with +/- sign]
  // Color amount: green for income, red for expense
  // Swipe-to-delete with Dismissible
}
```

Used in: transaction list, dashboard recent, search results.

### 11.3 `EmptyState` — illustrated empty placeholder

```dart
class EmptyState extends StatelessWidget {
  final String title;
  final String description;
  final IconData? icon;
  final Widget? illustration;
  final String? actionLabel;
  final VoidCallback? onAction;
}
```

Used in: empty transaction list, empty goals, empty insights, no search results, no internet.

---

## 12. Routing

Use `go_router` with auth-based redirect. In `lib/core/routing/app_router.dart`:

```dart
final appRouter = GoRouter(
  initialLocation: '/',
  refreshListenable: AuthChangeNotifier(authBloc),
  redirect: (context, state) {
    final isAuthed = authBloc.state is Authenticated;
    final isAuthRoute = state.matchedLocation == '/login'
                     || state.matchedLocation == '/signup';
    if (!isAuthed && !isAuthRoute) return '/login';
    if (isAuthed && isAuthRoute) return '/';
    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
    GoRoute(path: '/signup', builder: (_, __) => const SignupPage()),
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(path: '/', builder: (_, __) => const DashboardPage()),
        GoRoute(path: '/transactions', builder: (_, __) => const TransactionListPage()),
        GoRoute(path: '/transactions/add', builder: (_, __) => const AddTransactionPage()),
        GoRoute(path: '/transactions/edit/:id', builder: (_, state) =>
          AddTransactionPage(editId: state.pathParameters['id'])),
        GoRoute(path: '/categories', builder: (_, __) => const CategoriesPage()),
        GoRoute(path: '/budgets', builder: (_, __) => const BudgetPage()),
        GoRoute(path: '/goals', builder: (_, __) => const GoalsPage()),
        GoRoute(path: '/analytics', builder: (_, __) => const AnalyticsPage()),
      ],
    ),
  ],
);
```

`MainShell` contains the bottom navigation bar.

---

## 13. Dependency Injection

In `lib/core/di/service_locator.dart`:

```dart
final getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  // External
  getIt.registerLazySingleton(() => FirebaseAuth.instance);
  getIt.registerLazySingleton(() => FirebaseFirestore.instance);
  getIt.registerLazySingleton(() => GoogleSignIn());

  // Repositories
  getIt.registerLazySingleton(() => AuthRepository(getIt(), getIt()));
  getIt.registerLazySingleton(() => TransactionRepository(getIt()));
  getIt.registerLazySingleton(() => CategoryRepository(getIt()));
  getIt.registerLazySingleton(() => GoalRepository(getIt()));

  // Domain services
  getIt.registerLazySingleton(() => InsightEngine());
}
```

In `main.dart`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await setupServiceLocator();
  runApp(const SpendSnapApp());
}
```

In `app.dart`, wrap the router with a `MultiBlocProvider`:

```dart
class SpendSnapApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthBloc(getIt())..add(AuthCheckRequested())),
        BlocProvider(create: (_) => TransactionBloc(getIt())..add(LoadTransactions())),
        BlocProvider(create: (_) => CategoryBloc(getIt())..add(LoadCategories())),
        BlocProvider(create: (_) => BudgetBloc(getIt())),
        BlocProvider(create: (_) => GoalBloc(getIt())..add(LoadGoals())),
        BlocProvider(create: (_) => InsightBloc(getIt())),
      ],
      child: MaterialApp.router(
        title: 'SpendSnap',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        routerConfig: appRouter,
      ),
    );
  }
}
```

---

## 14. Testing Requirements

### Widget tests (3 required) — `test/widget/`

1. **`spend_ring_test.dart`** — verify ring renders, progress prop affects arc sweep, animates on prop change.
2. **`transaction_tile_test.dart`** — verify income shows green +amount, expense shows red -amount, tap callback fires, swipe triggers delete callback.
3. **`empty_state_test.dart`** — verify title/description render, action button only shown when `onAction` provided, tapping it fires callback.

### Integration tests (2 required) — `integration_test/`

1. **`auth_flow_test.dart`** — full signup → land on dashboard → logout → land on login.
2. **`transaction_crud_test.dart`** — login → add transaction → verify appears in list → edit → verify updated → delete → verify removed.

### Unit tests (recommended for InsightEngine)

Each of the 5 insight rules should have ≥1 unit test verifying it fires (or doesn't) under specific input conditions. These are easy because the engine is pure Dart.

### Documented manual test scenarios

In the project report, document these scenarios with screenshots:
- Happy path: signup → add 5 transactions → see analytics
- Empty state: fresh signup → see empty states everywhere
- No internet: airplane mode → app shows cached data with banner
- Invalid input: amount = 0, amount = "abc", future date → form blocks submit

---

## 15. Coding Conventions

- **Linting**: use `package:flutter_lints/flutter.yaml` + add `prefer_const_constructors`, `prefer_final_fields`, `avoid_print`.
- **File naming**: `snake_case.dart`. One public class per file.
- **Class naming**: `PascalCase`. Models end in `Model`, Blocs end in `Bloc`, Repositories end in `Repository`.
- **Imports**: order — Dart SDK, Flutter, third-party packages, project files. Alphabetical within each group.
- **Const everywhere**: every widget that can be const, must be const.
- **No print statements**: use a logger or remove before commit.
- **No magic numbers**: extract to named constants.
- **Currency formatting**: always go through `CurrencyFormatter` utility — never `'₹$amount'` directly.
- **Date formatting**: always go through `intl` `DateFormat` — never `'${date.day}/${date.month}'`.

### Commit message convention

```
<type>: <short summary>

Types: feat, fix, refactor, test, docs, chore, style
Examples:
- feat: implement weekend spending insight rule
- fix: prevent negative amount in transaction form
- refactor: extract currency formatting to utility
- test: add widget test for SpendRing
```

NO commits like "final update", "fix", "wip", "asdf".

---

## 16. Implementation Phases

Build in this order. Each phase produces a runnable app.

### Phase 1: Foundation (Days 1–2)
- [ ] Project scaffold + folder structure
- [ ] `pubspec.yaml` with all dependencies
- [ ] Firebase setup + `flutterfire configure`
- [ ] Theme + colors + typography
- [ ] Service locator + main.dart wiring

### Phase 2: Auth (Days 3–4)
- [ ] AuthRepository + UserModel
- [ ] AuthBloc + events + states
- [ ] LoginPage + SignupPage
- [ ] Router with auth redirect
- [ ] Default category seeding on signup

### Phase 3: Transactions CRUD (Days 5–7)
- [ ] TransactionModel + TransactionRepository
- [ ] TransactionBloc with full CRUD
- [ ] TransactionListPage + AddTransactionPage
- [ ] Filter UI (date range, type, category)
- [ ] TransactionTile widget
- [ ] EmptyState widget

### Phase 4: Categories + Budgets (Days 8–10)
- [ ] CategoryModel + CategoryRepository + CategoryBloc
- [ ] CategoriesPage with grid + add/edit
- [ ] BudgetBloc (computes spend per category)
- [ ] BudgetPage with progress bars
- [ ] SpendRing widget

### Phase 5: Dashboard + Analytics (Days 11–13)
- [ ] DashboardPage with all summary cards
- [ ] AnalyticsPage with 3 charts
- [ ] Chart interpretation labels
- [ ] Date range selector

### Phase 6: Goals + Insights (Days 14–16)
- [ ] GoalModel + GoalRepository + GoalBloc
- [ ] GoalsPage with rings
- [ ] Goal contribution flow
- [ ] InsightEngine with all 5 rules
- [ ] InsightBloc + InsightCard widget
- [ ] Top insight on dashboard

### Phase 7: Polish + Edge Cases (Days 17–18)
- [ ] Connectivity handling — show offline banner
- [ ] Animated balance counter
- [ ] Goal ring fill animation
- [ ] All loading states
- [ ] All error states
- [ ] Form validation everywhere

### Phase 8: Testing (Day 19)
- [ ] 3 widget tests passing
- [ ] 2 integration tests passing
- [ ] Insight engine unit tests
- [ ] Manual test scenarios documented

### Phase 9: Build + Submit (Day 20)
- [ ] App icon + splash screen (`flutter_launcher_icons` + `flutter_native_splash`)
- [ ] App name everywhere
- [ ] `flutter build apk --release`
- [ ] README.md with screenshots
- [ ] Final commit + tag

---

## 17. Definition of Done Checklist

Before declaring complete, verify EVERY item:

### Functional
- [ ] All 6 features from §8 work end-to-end
- [ ] At least 2 extensions implemented (goals + insights ✓)
- [ ] User flows have no dead ends
- [ ] Empty states exist for: transactions, goals, insights, search, no internet
- [ ] Invalid input is blocked with inline error messages

### UI/UX
- [ ] Custom color palette (not default Flutter blue)
- [ ] Custom typography hierarchy
- [ ] 3 reusable custom widgets in `shared/widgets/`
- [ ] Responsive across phone sizes (test on small + large devices)
- [ ] At least 2 micro-interactions

### Architecture
- [ ] Bloc used everywhere (zero `setState` in business logic)
- [ ] Repository pattern enforced (Blocs don't import Firebase)
- [ ] Domain models are pure Dart
- [ ] InsightEngine is pure Dart and unit-tested

### Backend
- [ ] Firebase Auth working (email + Google)
- [ ] Firestore reads/writes working
- [ ] Security rules deployed
- [ ] Composite indexes created
- [ ] Offline cached data works

### Custom Logic
- [ ] InsightEngine implements all 5 rules
- [ ] Each rule unit-tested
- [ ] Insights surface on dashboard

### Visualization
- [ ] Pie chart with interpretation
- [ ] Bar chart with interpretation
- [ ] Line chart with interpretation
- [ ] Progress rings on goals + budgets

### Testing
- [ ] 3 widget tests pass
- [ ] 2 integration tests pass
- [ ] Insight rule unit tests pass
- [ ] `flutter test` exits clean

### Performance
- [ ] No visible UI lag when scrolling 100+ transactions
- [ ] No unnecessary rebuilds (use `BlocSelector` where appropriate)
- [ ] Images cached (`cached_network_image`)

### Deployment
- [ ] Release APK builds successfully
- [ ] Custom app icon configured
- [ ] Custom splash screen configured
- [ ] App name = "SpendSnap" everywhere

### Documentation
- [ ] README with setup, features, screenshots
- [ ] Architecture diagram in report
- [ ] State management explanation in report
- [ ] AI usage disclosure in report
- [ ] Challenges section in report

### GitHub
- [ ] Clean folder structure matches §4
- [ ] Meaningful commit messages
- [ ] No leaked API keys (use `.env` or `firebase_options.dart` only)
- [ ] `.gitignore` excludes `build/`, `.dart_tool/`, `*.lock`, etc.
- [ ] README screenshots embedded

---

## Appendix A: Project README template

After implementation, the actual `README.md` shown in the GitHub repo should contain:

1. Project name + tagline + screenshots
2. Features list (with checkmarks)
3. Tech stack badges
4. Setup instructions (clone → `flutterfire configure` → `flutter run`)
5. Architecture overview (1-paragraph)
6. Folder structure (truncated tree)
7. Testing instructions
8. Build instructions
9. License

---

## Appendix B: Anti-patterns to avoid

These will lower the grade:

- ❌ `setState` for business logic (only use for purely visual state like animation controllers)
- ❌ Importing `cloud_firestore` from a widget or Bloc
- ❌ Hardcoded strings for colors, sizes, or currency symbols
- ❌ One giant `home_page.dart` file with everything in it
- ❌ `print()` statements left in code
- ❌ Generic Material default theme (the "AI-cloned" tell)
- ❌ Unhandled `Future` errors (every `await` needs try/catch or `.catchError`)
- ❌ Missing keys on dynamic list items
- ❌ "TODO" comments in submitted code
- ❌ Commented-out code blocks

---

**End of spec.** Implement strictly in order. When blocked, reference the relevant section by number.
