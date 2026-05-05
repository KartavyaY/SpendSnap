import 'package:flutter_test/flutter_test.dart';
import 'package:spendsnap/core/utils/currency_formatter.dart';

void main() {
  group('CurrencyFormatter.format — INR (default)', () {
    test('formats a whole-number amount with rupee symbol', () {
      final result = CurrencyFormatter.format(1000.0);
      expect(result, contains('₹'),
          reason: 'INR formatting must include the rupee symbol');
    });

    test('formats 1000 rupees with two decimal places', () {
      final result = CurrencyFormatter.format(1000.0);
      expect(result, contains('1,000.00'),
          reason: 'INR format should include commas and two decimal digits');
    });

    test('formats a fractional amount correctly', () {
      final result = CurrencyFormatter.format(999.50);
      expect(result, contains('999.50'));
    });

    test('formats zero as rupee zero', () {
      final result = CurrencyFormatter.format(0.0);
      expect(result, contains('0.00'));
      expect(result, contains('₹'));
    });

    test('formats a large number with Indian grouping separators', () {
      // Indian notation: 1,00,000 (lakh grouping)
      final result = CurrencyFormatter.format(100000.0);
      expect(result, contains('₹'));
      // The intl library uses Indian grouping (1,00,000)
      expect(result, contains('1,00,000.00'));
    });

    test('formats a negative amount correctly', () {
      final result = CurrencyFormatter.format(-500.0);
      expect(result, contains('₹'));
      // Negative symbol should appear
      expect(result.contains('-') || result.contains('('), isTrue,
          reason: 'Negative amount should have a negative indicator');
    });
  });

  group('CurrencyFormatter.format — USD', () {
    test('uses dollar symbol for USD', () {
      final result = CurrencyFormatter.format(1000.0, currency: 'USD');
      expect(result, contains('\$'));
    });

    test('formats USD with two decimal places', () {
      final result = CurrencyFormatter.format(1234.56, currency: 'USD');
      expect(result, contains('1,234.56'));
    });

    test('USD currency code is case-insensitive', () {
      final lower = CurrencyFormatter.format(100.0, currency: 'usd');
      final upper = CurrencyFormatter.format(100.0, currency: 'USD');
      expect(lower, equals(upper));
    });
  });

  group('CurrencyFormatter.formatCompact', () {
    test('formats a number in the thousands with T suffix for INR (en_IN locale)', () {
      final result = CurrencyFormatter.formatCompact(10000.0);
      expect(result, contains('₹'));
      // en_IN compact abbreviation for thousands is 't' (not 'K')
      expect(result.toLowerCase(), contains('t'),
          reason: 'en_IN compact formatter abbreviates thousands with "t"');
    });

    test('formats a lakh-level number with L suffix', () {
      final result = CurrencyFormatter.formatCompact(500000.0);
      expect(result, contains('₹'));
      // en_IN compact: 5L
      expect(result, contains('L') ,
          reason: 'Compact formatter should abbreviate lakhs');
    });

    test('uses dollar symbol for USD compact formatting', () {
      final result = CurrencyFormatter.formatCompact(5000.0, currency: 'USD');
      expect(result, contains('\$'));
    });
  });

  group('CurrencyFormatter.formatSigned', () {
    test('prefixes a positive amount with a plus sign', () {
      final result = CurrencyFormatter.formatSigned(500.0);
      expect(result, startsWith('+'));
    });

    test('prefixes a negative amount with a minus sign', () {
      final result = CurrencyFormatter.formatSigned(-500.0);
      expect(result, startsWith('-'));
    });

    test('zero is treated as non-negative (plus prefix)', () {
      final result = CurrencyFormatter.formatSigned(0.0);
      expect(result, startsWith('+'));
    });

    test('absolute value is formatted regardless of sign', () {
      final pos = CurrencyFormatter.formatSigned(500.0);
      final neg = CurrencyFormatter.formatSigned(-500.0);
      // Both should contain the same numeric string
      expect(pos.replaceFirst('+', ''), equals(neg.replaceFirst('-', '')));
    });
  });
}
