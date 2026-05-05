# SpendSnap — Testing Guide for AI Code Generation

Hand this file to a code-generation agent (Claude Sonnet, etc.) and ask it to write more tests. It contains every convention, helper pattern, and gap analysis it needs.

---

## 1. Project context

SpendSnap is a Flutter + Firebase personal finance tracker. Architecture is feature-first clean architecture:

```
lib/features/<feature>/
├── domain/         # Pure Dart models — testable without Flutter
├── data/           # Firestore repositories
└── presentation/
    ├── bloc/       # event / state / bloc
    ├── pages/
    └── widgets/
```

Each feature has at minimum a model in `domain/`, a repo in `data/`, and a BLoC in `presentation/bloc/`. Domain layer is pure Dart and the highest-priority test target.

### Tech under test

- **State management**: `flutter_bloc` 8.1, `equatable`
- **Backend**: Firebase Auth + Cloud Firestore (mock these — never hit real Firebase)
- **Routing**: `go_router` 14 (ShellRoute)
- **OCR**: `google_mlkit_text_recognition` (mock)
- **LLM**: Groq API over HTTP (mock with `http.MockClient`)

---

## 2. Test types we use

| Type | Location | Purpose |
|---|---|---|
| Unit | `test/<feature>_test.dart` | Pure-Dart business rules (insight engine, currency formatter, budget calc) |
| Widget | `test/widget/<widget>_test.dart` | Renders, callbacks, conditional UI |
| BLoC | `test/<feature>/<feature>_bloc_test.dart` | State transitions for events using `bloc_test` |
| Integration | `integration_test/` | End-to-end flows (not yet present — opportunity) |

---

## 3. Existing tests — patterns to copy

### 3.1 Pure-Dart unit (`test/insight_engine_test.dart`)

**Pattern:**
- Local helper factories `_txn()` and `_cat()` reduce boilerplate
- Fixed `now = DateTime(2024, 1, 15)` for deterministic time-dependent rules
- One `group()` per rule with positive + negative cases

**Snippet:**
```dart
TransactionModel _txn({
  required double amount,
  required TransactionType type,
  required DateTime date,
  String categoryId = 'cat1',
}) =>
    TransactionModel(
      id: '${date.millisecondsSinceEpoch}_$amount',
      uid: 'user1',
      amount: amount,
      type: type,
      categoryId: categoryId,
      date: date,
    );

void main() {
  final engine = InsightEngine();
  final now = DateTime(2024, 1, 15);

  group('InsightEngine — Rule X', () {
    test('fires when condition met', () {
      final txns = [_txn(...)];
      final insights = engine.generate(transactions: txns, categories: [], now: now);
      expect(insights.any((i) => i.title.contains('xyz')), isTrue);
    });
    test('does not fire when condition not met', () { ... });
  });
}
```

### 3.2 Widget — primitive (`test/widget/empty_state_test.dart`)

**Pattern:**
- `MaterialApp + Scaffold + body: <widget under test>`
- Test prop combinations: title-only, title+description, title+icon, title+actionLabel, title+actionLabel+onAction
- Use `find.text()` and `find.byIcon()` for assertions
- Use `tester.tap()` + closure to verify callbacks fire

**Snippet:**
```dart
testWidgets('action button shown when onAction provided', (tester) async {
  bool pressed = false;
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: EmptyState(
          title: 'Empty',
          description: 'No data.',
          actionLabel: 'Add Now',
          onAction: () => pressed = true,
        ),
      ),
    ),
  );
  expect(find.text('Add Now'), findsOneWidget);
  await tester.tap(find.text('Add Now'));
  expect(pressed, isTrue);
});
```

### 3.3 Widget — domain primitive (`test/widget/transaction_tile_test.dart`)

**Pattern:**
- Const factory for default `CategoryModel`
- `_makeTransaction({...})` factory with sensible defaults
- Assert on rendered text + style (color/sign for income vs expense)
- `tester.widget<Text>(find.textContaining('+'))` to grab a widget and assert its `.style.color`
- Tap test using `find.byType(InkWell).first`

### 3.4 Widget — animated/sized (`test/widget/spend_ring_test.dart`)

**Pattern:**
- Render at multiple progress values (0, 0.5, 1.5 to test clamp)
- Use `StatefulBuilder` to drive animation, call `pumpAndSettle()` after
- Use `find.descendant()` to drill into widget internals (`SizedBox` inside `SpendRing`)

---

## 4. Conventions for new tests

### 4.1 File locations

- Unit / domain: `test/<feature>_test.dart` (e.g. `test/insight_engine_test.dart`)
- Widget: `test/widget/<widget_name>_test.dart`
- BLoC: `test/<feature>/<feature>_bloc_test.dart`
- Mocks: `test/_mocks/<mock_name>.dart` (create directory if needed)

### 4.2 Imports

Always use the `package:spendsnap/...` form, never relative imports:

```dart
import 'package:spendsnap/features/transactions/domain/transaction_model.dart';
```

### 4.3 Naming

- File: `snake_case_test.dart`
- Group: feature or class name with rule descriptor — `'InsightEngine — Rule 3: Burn rate'`
- Test: behavior in plain English — `'fires when projected spend exceeds budget by 10%'`

### 4.4 Test data factories

Always define local helpers at the top of the file:

```dart
TransactionModel _txn({required ..., ...}) => TransactionModel(...);
CategoryModel _cat({...}) => CategoryModel(...);
GoalModel _goal({...}) => GoalModel(...);
BudgetModel _budget({...}) => BudgetModel(...);
```

Use sensible defaults so each test only specifies fields relevant to it.

### 4.5 Determinism

- Time-dependent code: pass a fixed `now` parameter (not `DateTime.now()`)
- Random: seed any RNG
- Floats: use `closeTo(expected, 0.01)` not `equals(expected)`

### 4.6 Asserting on collections

```dart
expect(insights.any((i) => i.type == InsightType.warning), isTrue);
expect(filtered.length, 3);
expect(filtered.map((t) => t.id), containsAll(['id1', 'id2']));
```

---

## 5. BLoC testing — when you write these next

Use `package:bloc_test/bloc_test.dart` (already in `dev_dependencies`).

### 5.1 Pattern

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockTransactionRepo extends Mock implements TransactionRepository {}

void main() {
  late _MockTransactionRepo repo;

  setUp(() {
    repo = _MockTransactionRepo();
  });

  blocTest<TransactionBloc, TransactionState>(
    'emits [Loading, Loaded] on LoadTransactions',
    setUp: () {
      when(() => repo.watchTransactions(any())).thenAnswer(
        (_) => Stream.value([_txn(amount: 100, type: TransactionType.expense, date: DateTime(2024, 1, 1))]),
      );
    },
    build: () => TransactionBloc(repo: repo, uid: 'user1'),
    act: (bloc) => bloc.add(const LoadTransactions()),
    expect: () => [
      isA<TransactionLoading>(),
      isA<TransactionLoaded>().having((s) => s.transactions.length, 'count', 1),
    ],
  );
}
```

### 5.2 What to test per BLoC

- Initial state
- Each event → expected state sequence
- Error path: repo throws → emit Error state
- Filter combinations (type + category + date + search)
- Edge case: empty list, null fields

---

## 6. Mocking strategy

Use `mocktail` (preferred over `mockito` — no codegen).

### 6.1 Firestore repository mocks

Don't use `fake_cloud_firestore`. Mock the repository interface instead:

```dart
class _MockCategoryRepo extends Mock implements CategoryRepository {}
```

This isolates BLoC tests from Firestore details.

### 6.2 HTTP mocks (Groq LLM)

```dart
import 'package:http/testing.dart';

final mockClient = MockClient((request) async {
  return http.Response(
    jsonEncode({
      'choices': [{'message': {'content': '{"merchant":"Starbucks","total":150,...}'}}],
    }),
    200,
  );
});
```

Inject the client into your service.

### 6.3 ML Kit OCR mocks

Mock the `TextRecognizer` wrapper. Don't try to test on-device OCR directly.

---

## 7. Domain features — what needs tests

### 7.1 Already covered

| Component | Coverage |
|---|---|
| InsightEngine (5 rules) | Good — positive + negative cases each |
| TransactionTile widget | Good — sign, color, tap, note, category |
| SpendRing widget | Good — progress, label, clamp, animation, size |
| EmptyState widget | Good — all prop permutations |

### 7.2 Critical gaps — write these next

#### Domain models

- `TransactionModel.fromMap` / `toMap` — round-trip equality
- `CategoryModel.fromMap` / `toMap` — including isIncome and monthlyLimit edge cases
- `GoalModel.contribute(amount)` — clamp to remaining, mark complete
- `BudgetModel` — derived `progress`, `isNearLimit`, `isOverBudget`, `remaining` computations

#### Utilities

- `CurrencyFormatter.format(amount)` — INR symbol, decimals, large numbers, negative
- `AppDateUtils.formatDay(date)` — today / yesterday / older formats
- `CategoryIcon.resolve(key)` — fallback for unknown keys

#### BLoCs

| BLoC | Events to test |
|---|---|
| AuthBloc | SignInWithEmail, SignInWithGoogle, SignOut, AuthStateChanged |
| TransactionBloc | LoadTransactions, AddTransaction, UpdateTransaction, DeleteTransaction, FilterTransactions (each filter dimension + combinations) |
| CategoryBloc | LoadCategories, AddCategory (with duplicate check), UpdateCategory, DeleteCategory |
| BudgetBloc | LoadBudgets (computes from categories+txns), SetBudgetLimit, RemoveBudgetLimit |
| GoalBloc | AddGoal, ContributeToGoal (clamp + auto-complete), MarkGoalComplete, DeleteGoal |
| InsightBloc | GenerateInsights, DismissInsight (persists), RestoreInsight |

#### Receipt scan pipeline

- `ReceiptParser.parseLLMResponse(json)` — handles missing fields, malformed JSON
- `ReceiptPrefill.fromGroqResponse(...)` — category fuzzy match
- Scan service: OCR fail → error state, LLM 500 → error state, success → ReceiptLoaded

#### Routing

- GoRouter redirect: unauthed → /login, authed on /login → /
- Deep link to /transactions/edit/:id resolves correctly
- Scan tab does not highlight Home (verify `_currentIndex` returns -1 for /scan)

#### Recurring transactions

- Generation idempotency — same (originalId, periodStart) never duplicates
- Weekly / monthly / yearly schedule produces correct due dates

---

## 8. Test data — canonical fixtures

When generating multiple tests, prefer these reusable shapes over inventing new ones:

```dart
final _foodCategory = CategoryModel(
  id: 'cat-food',
  uid: 'user1',
  name: 'Food',
  icon: 'fastfood',
  color: '#D85A30',
  isIncome: false,
  monthlyLimit: 5000,
);

final _salaryCategory = CategoryModel(
  id: 'cat-salary',
  uid: 'user1',
  name: 'Salary',
  icon: 'salary',
  color: '#1D9E75',
  isIncome: true,
);

final _now = DateTime(2024, 1, 15);
final _user = 'user1';
```

---

## 9. Running tests

```bash
# All tests
flutter test

# Specific file
flutter test test/insight_engine_test.dart

# With coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html

# Watch mode (auto-rerun on save)
flutter test --watch
```

CI smoke check: `flutter analyze --no-fatal-infos && flutter test`.

---

## 10. Style rules for AI-generated tests

- **No print statements** in tests
- **Always `await tester.pumpAndSettle()`** after triggering animations
- **Always dispose controllers** in widget tests (`tester.binding.delayed(...)` or just let test framework clean up)
- **Never call `DateTime.now()`** — pass a `now` parameter
- **Group related tests** under a `group()` block
- **One assertion per test** when possible — multiple `expect` calls OK if they're checking facets of same outcome
- **Comments explain why, not what** — code shows what
- **Use `reason:` parameter on `expect()`** for non-obvious assertions
- **Test names as full sentences** that describe behavior, not implementation

---

## 11. What NOT to test

- Firebase SDK internals (mock the repo, trust Firebase)
- Flutter framework widgets (Material, Cupertino — already tested upstream)
- Exact pixel positions (brittle, low value)
- LLM output content (test the parser, not the LLM)
- Private methods directly — test through public API

---

## 12. Coverage goal

Target ≥70% line coverage on `lib/features/*/domain/` and `lib/features/*/presentation/bloc/`. Widget and integration tests boost confidence but coverage of domain + state is the priority.

Run `flutter test --coverage` and inspect `coverage/lcov.info`.

---

## 13. Prompt template for Sonnet

> Read `test/TESTING_GUIDE.md` for conventions.
> Now write Flutter tests for `lib/features/<X>/<Y>.dart`.
> Match the style of `test/insight_engine_test.dart` for unit tests or `test/widget/<existing>_test.dart` for widget tests.
> Use `mocktail` for any Firestore or HTTP mocking. Use the test data factories from section 8 when possible.
> Cover positive + negative + edge cases. Run `flutter test` after writing and confirm green.