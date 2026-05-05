import 'package:flutter_test/flutter_test.dart';
import 'package:spendsnap/features/budgets/domain/budget_model.dart';
import 'package:spendsnap/features/categories/domain/category_model.dart';

// Minimal category — BudgetModel only uses category.id in its props.
const _category = CategoryModel(
  id: 'cat-food',
  uid: 'user1',
  name: 'Food',
  icon: 'food',
  color: '#D85A30',
);

// Factory helper.
BudgetModel _budget({
  double spent = 0.0,
  double limit = 5000.0,
  CategoryModel category = _category,
}) =>
    BudgetModel(category: category, spent: spent, limit: limit);

void main() {
  group('BudgetModel — progress', () {
    test('returns 0.0 when nothing has been spent', () {
      final b = _budget(spent: 0.0, limit: 5000.0);
      expect(b.progress, closeTo(0.0, 0.001));
    });

    test('returns 0.5 at half the limit', () {
      final b = _budget(spent: 2500.0, limit: 5000.0);
      expect(b.progress, closeTo(0.5, 0.001));
    });

    test('returns 1.0 exactly at the limit', () {
      final b = _budget(spent: 5000.0, limit: 5000.0);
      expect(b.progress, closeTo(1.0, 0.001));
    });

    test('exceeds 1.0 when over-budget (clamped to 2.0)', () {
      final b = _budget(spent: 8000.0, limit: 5000.0);
      // progress = 8000/5000 = 1.6, which is within the [0,2] clamp
      expect(b.progress, closeTo(1.6, 0.001));
    });

    test('clamps progress at 2.0 when spending is extreme', () {
      final b = _budget(spent: 20000.0, limit: 5000.0);
      expect(b.progress, closeTo(2.0, 0.001),
          reason: 'progress should not exceed the clamp ceiling of 2.0');
    });

    test('returns 0.0 when limit is zero to prevent division by zero', () {
      final b = _budget(spent: 100.0, limit: 0.0);
      expect(b.progress, closeTo(0.0, 0.001));
    });
  });

  group('BudgetModel — remaining', () {
    test('equals the full limit when nothing has been spent', () {
      final b = _budget(spent: 0.0, limit: 5000.0);
      expect(b.remaining, closeTo(5000.0, 0.001));
    });

    test('returns the correct difference mid-month', () {
      final b = _budget(spent: 1500.0, limit: 5000.0);
      expect(b.remaining, closeTo(3500.0, 0.001));
    });

    test('returns 0.0 when spent equals limit', () {
      final b = _budget(spent: 5000.0, limit: 5000.0);
      expect(b.remaining, closeTo(0.0, 0.001));
    });

    test('clamps to 0.0 and never goes negative when over-budget', () {
      final b = _budget(spent: 7000.0, limit: 5000.0);
      expect(b.remaining, closeTo(0.0, 0.001),
          reason: 'remaining must never be negative');
    });
  });

  group('BudgetModel — isOverBudget', () {
    test('returns false when spent is less than limit', () {
      final b = _budget(spent: 4999.99, limit: 5000.0);
      expect(b.isOverBudget, isFalse);
    });

    test('returns false when spent equals limit exactly', () {
      final b = _budget(spent: 5000.0, limit: 5000.0);
      expect(b.isOverBudget, isFalse,
          reason: 'at-limit is not over-budget');
    });

    test('returns true when spent exceeds limit by even one rupee', () {
      final b = _budget(spent: 5000.01, limit: 5000.0);
      expect(b.isOverBudget, isTrue);
    });

    test('returns true when spending significantly exceeds limit', () {
      final b = _budget(spent: 10000.0, limit: 5000.0);
      expect(b.isOverBudget, isTrue);
    });
  });

  group('BudgetModel — isNearLimit', () {
    test('returns false when progress is below 70%', () {
      final b = _budget(spent: 3000.0, limit: 5000.0); // 60%
      expect(b.isNearLimit, isFalse);
    });

    test('returns true at exactly 70% (threshold boundary)', () {
      final b = _budget(spent: 3500.0, limit: 5000.0); // 70%
      expect(b.isNearLimit, isTrue);
    });

    test('returns true when between 70% and 100%', () {
      final b = _budget(spent: 4000.0, limit: 5000.0); // 80%
      expect(b.isNearLimit, isTrue);
    });

    test('returns false when over-budget even though progress >= 0.7', () {
      final b = _budget(spent: 6000.0, limit: 5000.0); // 120%
      expect(b.isNearLimit, isFalse,
          reason: 'over-budget takes precedence and isNearLimit should be false');
    });

    test('returns false at exactly the limit (isOverBudget is false, but progress == 1.0)', () {
      // At 100%, spent == limit so isOverBudget is false.
      // progress >= 0.7 is satisfied, so isNearLimit should be true.
      final b = _budget(spent: 5000.0, limit: 5000.0);
      expect(b.isNearLimit, isTrue);
    });
  });

  group('BudgetModel — equatable identity', () {
    test('two identical budget instances are equal', () {
      final a = _budget(spent: 1000.0, limit: 5000.0);
      final b = _budget(spent: 1000.0, limit: 5000.0);
      expect(a, equals(b));
    });

    test('budgets with different spent amounts are not equal', () {
      final a = _budget(spent: 1000.0, limit: 5000.0);
      final b = _budget(spent: 2000.0, limit: 5000.0);
      expect(a, isNot(equals(b)));
    });
  });
}
