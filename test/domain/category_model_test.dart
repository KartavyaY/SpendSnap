import 'package:flutter_test/flutter_test.dart';
import 'package:spendsnap/features/categories/domain/category_model.dart';

// Factory helper with sensible defaults.
CategoryModel _cat({
  String id = 'cat1',
  String uid = 'user1',
  String name = 'Food',
  String icon = 'food',
  String color = '#D85A30',
  double? monthlyLimit,
  bool isDefault = false,
  bool isIncome = false,
}) =>
    CategoryModel(
      id: id,
      uid: uid,
      name: name,
      icon: icon,
      color: color,
      monthlyLimit: monthlyLimit,
      isDefault: isDefault,
      isIncome: isIncome,
    );

void main() {
  group('CategoryModel — toFirestore', () {
    test('serialises isIncome false for expense categories', () {
      final map = _cat(isIncome: false).toFirestore();
      expect(map['isIncome'], isFalse);
    });

    test('serialises isIncome true for income categories', () {
      final map = _cat(isIncome: true, icon: 'salary').toFirestore();
      expect(map['isIncome'], isTrue);
    });

    test('serialises all scalar fields', () {
      final map = _cat(
        uid: 'u99',
        name: 'Transport',
        icon: 'transport',
        color: '#378ADD',
        isDefault: true,
      ).toFirestore();

      expect(map['uid'], 'u99');
      expect(map['name'], 'Transport');
      expect(map['icon'], 'transport');
      expect(map['color'], '#378ADD');
      expect(map['isDefault'], isTrue);
    });

    test('monthlyLimit null is preserved when not set', () {
      final map = _cat(monthlyLimit: null).toFirestore();
      expect(map['monthlyLimit'], isNull);
    });

    test('monthlyLimit value is serialised when provided', () {
      final map = _cat(monthlyLimit: 5000.0).toFirestore();
      expect(map['monthlyLimit'], closeTo(5000.0, 0.001));
    });
  });

  group('CategoryModel — toFirestore round-trip (map equality)', () {
    test('expense category survives manual map round-trip', () {
      final original = _cat(
        id: 'c1',
        uid: 'user1',
        name: 'Shopping',
        icon: 'shopping',
        color: '#D4537E',
        monthlyLimit: 3000.0,
        isDefault: false,
        isIncome: false,
      );

      final map = original.toFirestore();

      final restored = CategoryModel(
        id: original.id,
        uid: map['uid'] as String,
        name: map['name'] as String,
        icon: map['icon'] as String,
        color: map['color'] as String,
        monthlyLimit: (map['monthlyLimit'] as num?)?.toDouble(),
        isDefault: map['isDefault'] as bool? ?? false,
        isIncome: map['isIncome'] as bool? ?? false,
      );

      expect(restored.name, original.name);
      expect(restored.icon, original.icon);
      expect(restored.color, original.color);
      expect(restored.monthlyLimit, closeTo(original.monthlyLimit!, 0.001));
      expect(restored.isIncome, original.isIncome);
    });

    test('income category round-trips correctly', () {
      final original = _cat(
        name: 'Salary',
        icon: 'salary',
        color: '#639922',
        isIncome: true,
        monthlyLimit: null,
      );
      final map = original.toFirestore();
      expect(map['isIncome'], isTrue);
      expect(map['monthlyLimit'], isNull);
    });
  });

  group('CategoryModel — isIncome flag edge cases', () {
    test('category with salary icon but explicit isIncome false is not income', () {
      final cat = _cat(icon: 'salary', isIncome: false);
      expect(cat.isIncome, isFalse,
          reason: 'Explicit constructor value takes precedence over icon name');
    });

    test('category with non-salary icon but explicit isIncome true is income', () {
      final cat = _cat(icon: 'freelance', isIncome: true);
      expect(cat.isIncome, isTrue);
    });
  });

  group('CategoryModel — monthlyLimit edge cases', () {
    test('category with zero monthlyLimit stores the value', () {
      final cat = _cat(monthlyLimit: 0.0);
      expect(cat.monthlyLimit, closeTo(0.0, 0.001));
    });

    test('category with very large monthlyLimit is preserved', () {
      final cat = _cat(monthlyLimit: 999999.99);
      expect(cat.monthlyLimit, closeTo(999999.99, 0.01));
    });
  });

  group('CategoryModel — copyWith', () {
    test('clears monthlyLimit when clearLimit is true', () {
      final cat = _cat(monthlyLimit: 1000.0);
      final updated = cat.copyWith(clearLimit: true);
      expect(updated.monthlyLimit, isNull,
          reason: 'clearLimit: true must set monthlyLimit to null');
    });

    test('updating name does not affect other fields', () {
      final original = _cat(name: 'Old', monthlyLimit: 500.0, isIncome: false);
      final updated = original.copyWith(name: 'New');
      expect(updated.name, 'New');
      expect(updated.monthlyLimit, closeTo(500.0, 0.001));
      expect(updated.isIncome, isFalse);
    });

    test('isIncome can be toggled via copyWith', () {
      final cat = _cat(isIncome: false);
      final toggled = cat.copyWith(isIncome: true);
      expect(toggled.isIncome, isTrue);
    });
  });

  group('CategoryModel — equatable identity', () {
    test('two instances with identical props are equal', () {
      final a = _cat(id: 'cat-same', monthlyLimit: 1000.0);
      final b = _cat(id: 'cat-same', monthlyLimit: 1000.0);
      expect(a, equals(b));
    });

    test('instances with different ids are not equal', () {
      final a = _cat(id: 'cat-a');
      final b = _cat(id: 'cat-b');
      expect(a, isNot(equals(b)));
    });
  });
}
