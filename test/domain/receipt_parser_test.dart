import 'package:flutter_test/flutter_test.dart';
import 'package:spendsnap/features/scan/domain/receipt_parser.dart';

void main() {
  late ReceiptParser parser;

  setUp(() {
    parser = ReceiptParser();
  });

  group('ReceiptParser — Amount Extraction', () {
    test('extracts amount using priority keywords', () {
      const text = '''
Welcome to Store
Some Item 10.00
Total Due: 15.50
Thank you
''';
      final result = parser.parse(text);
      expect(result.amount, 15.50);
    });

    test('ignores exclude keywords (e.g. subtotal, tax)', () {
      const text = '''
Subtotal 100.00
Tax 5.00
Grand Total 105.00
''';
      final result = parser.parse(text);
      expect(result.amount, 105.00);
    });

    test('falls back to largest 2-decimal number', () {
      const text = '''
Just a random text
Cost: 45.99
Another number 12.00
A whole number 200
''';
      final result = parser.parse(text);
      expect(result.amount, 45.99);
    });

    test('handles currency symbols', () {
      const text = '''
Amount ₹1,234.50
''';
      final result = parser.parse(text);
      expect(result.amount, 1234.50);
    });

    test('returns null if no valid amount found', () {
      const text = 'No numbers here';
      final result = parser.parse(text);
      expect(result.amount, isNull);
    });
  });

  group('ReceiptParser — Date Extraction', () {
    test('extracts ISO date (YYYY-MM-DD)', () {
      final now = DateTime.now();
      final year = now.year;
      final text = 'Date: $year-01-15';
      final result = parser.parse(text);
      expect(result.date, DateTime(year, 1, 15));
    });

    test('extracts DD/MM/YYYY', () {
      final now = DateTime.now();
      final year = now.year;
      final text = 'Purchased on 15/01/$year';
      final result = parser.parse(text);
      expect(result.date, DateTime(year, 1, 15));
    });

    test('extracts DD MMM YYYY', () {
      final now = DateTime.now();
      final year = now.year;
      final text = '15 Jan $year';
      final result = parser.parse(text);
      expect(result.date, DateTime(year, 1, 15));
    });

    test('extracts MMM DD YYYY', () {
      final now = DateTime.now();
      final year = now.year;
      final text = 'Jan 15, $year';
      final result = parser.parse(text);
      expect(result.date, DateTime(year, 1, 15));
    });

    test('ignores future dates', () {
      final futureYear = DateTime.now().year + 5;
      final text = 'Date: 15/10/$futureYear';
      final result = parser.parse(text);
      expect(result.date, isNull);
    });

    test('ignores dates older than 5 years', () {
      final oldYear = DateTime.now().year - 10;
      final text = 'Date: 15/10/$oldYear';
      final result = parser.parse(text);
      expect(result.date, isNull);
    });
  });

  group('ReceiptParser — Merchant Extraction', () {
    test('extracts longest valid candidate line as merchant', () {
      const text = '''
Store Name
123 Main Street
Tel: 555-1234
''';
      final result = parser.parse(text);
      expect(result.merchant, '123 Main Street'); 
      // Wait, 123 Main Street is 15 chars, Store Name is 10 chars. 
      // The parser takes the longest valid line. So 123 Main Street is extracted.
    });

    test('ignores blocklist keywords (e.g. tel, gst, www)', () {
      const text = '''
My Favorite Shop
www.myfavoriteshop.com
GST: 123456789
Tel: 1234567890
''';
      final result = parser.parse(text);
      expect(result.merchant, 'My Favorite Shop');
    });

    test('title cases the merchant name', () {
      const text = 'starbucks coffee\nOther lines';
      final result = parser.parse(text);
      expect(result.merchant, 'Starbucks Coffee');
    });
  });

  group('ReceiptParser — Category Hint', () {
    test('maps keywords to category hint', () {
      const text = 'Had a great coffee at Starbucks.';
      final result = parser.parse(text);
      expect(result.categoryHint, 'coffee');
    });

    test('returns null if no keyword matches', () {
      const text = 'Bought some unknown item.';
      final result = parser.parse(text);
      expect(result.categoryHint, isNull);
    });
  });

  group('ReceiptParser — Confidence Score', () {
    test('calculates 1.0 when all fields are extracted', () {
      final now = DateTime.now();
      final year = now.year;
      final text = '''
Starbucks Coffee
Date: 15/01/$year
Total: 5.50
''';
      final result = parser.parse(text);
      expect(result.amount, 5.50);
      expect(result.date, isNotNull);
      expect(result.merchant, 'Starbucks Coffee');
      expect(result.categoryHint, 'coffee');
      expect(result.confidence, 1.0);
    });

    test('calculates 0.5 when 2 fields are extracted', () {
      const text = 'Starbucks Coffee';
      final result = parser.parse(text);
      // Extracts merchant and categoryHint
      expect(result.amount, isNull);
      expect(result.date, isNull);
      expect(result.merchant, 'Starbucks Coffee');
      expect(result.categoryHint, 'coffee');
      expect(result.confidence, 0.5);
    });
  });
}
