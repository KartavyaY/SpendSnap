import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:spendsnap/core/utils/category_icon.dart';

void main() {
  group('CategoryIcon.resolve — known keys', () {
    test('resolves "food" to the correct Lucide icon', () {
      expect(CategoryIcon.resolve('food'), LucideIcons.utensils);
    });

    test('resolves "transport" to the car icon', () {
      expect(CategoryIcon.resolve('transport'), LucideIcons.car);
    });

    test('resolves "shopping" to the shoppingBag icon', () {
      expect(CategoryIcon.resolve('shopping'), LucideIcons.shoppingBag);
    });

    test('resolves "bills" to the fileText icon', () {
      expect(CategoryIcon.resolve('bills'), LucideIcons.fileText);
    });

    test('resolves "entertainment" to the tv2 icon', () {
      expect(CategoryIcon.resolve('entertainment'), LucideIcons.tv2);
    });

    test('resolves "health" to the heartPulse icon', () {
      expect(CategoryIcon.resolve('health'), LucideIcons.heartPulse);
    });

    test('resolves "salary" to the banknote icon', () {
      expect(CategoryIcon.resolve('salary'), LucideIcons.banknote);
    });

    test('resolves "other" to the package icon', () {
      expect(CategoryIcon.resolve('other'), LucideIcons.package);
    });

    test('resolves "savings" to the piggyBank icon', () {
      expect(CategoryIcon.resolve('savings'), LucideIcons.piggyBank);
    });

    test('resolves "travel" to the plane icon', () {
      expect(CategoryIcon.resolve('travel'), LucideIcons.plane);
    });

    test('resolves "rent" to the building icon', () {
      expect(CategoryIcon.resolve('rent'), LucideIcons.building);
    });

    test('resolves "investment" to the trendingUp icon', () {
      expect(CategoryIcon.resolve('investment'), LucideIcons.trendingUp);
    });
  });

  group('CategoryIcon.resolve — case normalisation', () {
    test('resolves uppercase key "FOOD" the same as lowercase "food"', () {
      expect(CategoryIcon.resolve('FOOD'), CategoryIcon.resolve('food'));
    });

    test('resolves mixed-case key "Transport" the same as lowercase', () {
      expect(CategoryIcon.resolve('Transport'), CategoryIcon.resolve('transport'));
    });
  });

  group('CategoryIcon.resolve — unknown key fallback', () {
    test('returns the tag fallback icon for an unknown key', () {
      expect(CategoryIcon.resolve('totally_unknown_key'), LucideIcons.tag);
    });

    test('returns the tag fallback icon for an empty string key', () {
      expect(CategoryIcon.resolve(''), LucideIcons.tag);
    });

    test('returns the tag fallback icon for a numeric string key', () {
      expect(CategoryIcon.resolve('12345'), LucideIcons.tag);
    });

    test('resolved icon for unknown key is an IconData instance', () {
      final icon = CategoryIcon.resolve('not-a-real-key');
      expect(icon, isA<IconData>());
    });
  });

  group('CategoryIcon.allKeys', () {
    test('returns a non-empty list of keys', () {
      expect(CategoryIcon.allKeys, isNotEmpty);
    });

    test('list of keys includes all default category icons', () {
      final keys = CategoryIcon.allKeys;
      expect(keys, containsAll(['food', 'transport', 'shopping', 'salary', 'other']));
    });

    test('all keys resolve to non-fallback icons', () {
      for (final key in CategoryIcon.allKeys) {
        final icon = CategoryIcon.resolve(key);
        expect(icon, isNot(LucideIcons.tag),
            reason: '"$key" should map to a specific icon, not the fallback');
      }
    });
  });

  group('CategoryIcon.label', () {
    test('capitalises the first letter of a key', () {
      expect(CategoryIcon.label('food'), 'Food');
    });

    test('returns "Other" for an empty string', () {
      expect(CategoryIcon.label(''), 'Other');
    });

    test('returns the key with first letter capitalised for a multi-word key', () {
      expect(CategoryIcon.label('fastfood'), 'Fastfood');
    });
  });
}
