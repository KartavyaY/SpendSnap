import 'package:flutter_test/flutter_test.dart';
import 'package:spendsnap/features/categories/domain/category_model.dart';
import 'package:spendsnap/features/insights/domain/insight_engine.dart';
import 'package:spendsnap/features/insights/domain/insight_model.dart';
import 'package:spendsnap/features/transactions/domain/transaction_model.dart';

TransactionModel _txn({
  required double amount,
  required TransactionType type,
  required DateTime date,
  String categoryId = 'cat1',
  String note = '',
}) =>
    TransactionModel(
      id: '${date.millisecondsSinceEpoch}_$amount',
      uid: 'user1',
      amount: amount,
      type: type,
      categoryId: categoryId,
      note: note.isEmpty ? null : note,
      date: date,
    );

CategoryModel _cat({
  String id = 'cat1',
  String name = 'Food',
  double? monthlyLimit,
}) =>
    CategoryModel(
      id: id,
      uid: 'user1',
      name: name,
      icon: '🍔',
      color: '#D85A30',
      monthlyLimit: monthlyLimit,
    );

void main() {
  final engine = InsightEngine();
  // Use a fixed "now" for deterministic tests: 2024-01-15 (Monday, mid-month)
  final now = DateTime(2024, 1, 15);

  group('InsightEngine — Rule 1: Weekend spending', () {
    test('fires when weekend per-day > 1.5x weekday per-day', () {
      final transactions = [
        // Weekend: Jan 6 (Sat) ₹2000, Jan 7 (Sun) ₹2000 → ₹2000/day
        _txn(amount: 2000, type: TransactionType.expense,
            date: DateTime(2024, 1, 6)),
        _txn(amount: 2000, type: TransactionType.expense,
            date: DateTime(2024, 1, 7)),
        // Weekdays: Mon–Fri ₹200 each → ₹200/day
        _txn(amount: 200, type: TransactionType.expense,
            date: DateTime(2024, 1, 8)),
        _txn(amount: 200, type: TransactionType.expense,
            date: DateTime(2024, 1, 9)),
        _txn(amount: 200, type: TransactionType.expense,
            date: DateTime(2024, 1, 10)),
        _txn(amount: 200, type: TransactionType.expense,
            date: DateTime(2024, 1, 11)),
        _txn(amount: 200, type: TransactionType.expense,
            date: DateTime(2024, 1, 12)),
      ];

      final insights = engine.generate(
          transactions: transactions, categories: [], now: now);

      expect(
        insights.any((i) => i.title.contains('weekend')),
        isTrue,
        reason: 'Should fire weekend spending insight',
      );
    });

    test('does not fire when ratio is below 1.5x', () {
      final transactions = [
        _txn(amount: 300, type: TransactionType.expense,
            date: DateTime(2024, 1, 6)),
        _txn(amount: 300, type: TransactionType.expense,
            date: DateTime(2024, 1, 8)),
        _txn(amount: 300, type: TransactionType.expense,
            date: DateTime(2024, 1, 9)),
      ];

      final insights = engine.generate(
          transactions: transactions, categories: [], now: now);

      expect(insights.any((i) => i.title.contains('weekend')), isFalse);
    });
  });

  group('InsightEngine — Rule 2: Category drift', () {
    test('fires when spending increases 50%+ and exceeds ₹1000', () {
      final lastMonthDate = DateTime(2023, 12, 10);
      final thisMonthDate = DateTime(2024, 1, 10);

      final transactions = [
        // Last month: ₹2000
        _txn(amount: 2000, type: TransactionType.expense, date: lastMonthDate),
        // This month: ₹3500 (75% increase)
        _txn(amount: 3500, type: TransactionType.expense, date: thisMonthDate),
      ];

      final insights = engine.generate(
          transactions: transactions, categories: [_cat()], now: now);

      expect(
        insights.any((i) => i.type == InsightType.warning),
        isTrue,
        reason: 'Should fire category drift warning',
      );
    });

    test('does not fire when increase is below 50%', () {
      final transactions = [
        _txn(amount: 2000, type: TransactionType.expense,
            date: DateTime(2023, 12, 10)),
        _txn(amount: 2500, type: TransactionType.expense,
            date: DateTime(2024, 1, 10)),
      ];

      final insights = engine.generate(
          transactions: transactions, categories: [_cat()], now: now);

      expect(insights.any((i) => i.type == InsightType.warning), isFalse);
    });
  });

  group('InsightEngine — Rule 3: Burn rate projection', () {
    test('fires when projected spend exceeds budget by 10%', () {
      // Day 15, ₹1100 spent → projected: 1100/15*31 = ~2273. Budget = 1000. 2273 > 1100.
      final transactions = [
        _txn(amount: 1100, type: TransactionType.expense,
            date: DateTime(2024, 1, 10)),
      ];

      final cat = _cat(monthlyLimit: 1000);
      final insights = engine.generate(
          transactions: transactions, categories: [cat], now: now);

      expect(
        insights.any((i) => i.type == InsightType.projection),
        isTrue,
        reason: 'Should fire burn rate projection',
      );
    });
  });

  group('InsightEngine — Rule 4: Unusual transaction', () {
    test('fires when transaction is more than 2 stddevs above mean', () {
      final transactions = [
        // Baseline: many small expenses
        for (int i = 1; i <= 20; i++)
          _txn(amount: 200, type: TransactionType.expense,
              date: DateTime(2024, 1, 1).add(Duration(days: i - 1))),
        // Unusual: ₹5000 in last 7 days
        _txn(amount: 5000, type: TransactionType.expense,
            date: DateTime(2024, 1, 12)),
      ];

      final insights = engine.generate(
          transactions: transactions, categories: [], now: now);

      expect(
        insights.any((i) => i.title.contains('Unusual')),
        isTrue,
        reason: 'Should detect unusual transaction',
      );
    });
  });

  group('InsightEngine — Rule 5: Savings streak', () {
    test('fires when 2+ consecutive months have income > expense', () {
      final transactions = [
        // Nov 2023: income > expense
        _txn(amount: 5000, type: TransactionType.income,
            date: DateTime(2023, 11, 1)),
        _txn(amount: 3000, type: TransactionType.expense,
            date: DateTime(2023, 11, 15)),
        // Dec 2023: income > expense
        _txn(amount: 5000, type: TransactionType.income,
            date: DateTime(2023, 12, 1)),
        _txn(amount: 3500, type: TransactionType.expense,
            date: DateTime(2023, 12, 15)),
      ];

      final insights = engine.generate(
          transactions: transactions, categories: [], now: now);

      expect(
        insights.any((i) => i.type == InsightType.achievement),
        isTrue,
        reason: 'Should fire savings streak achievement',
      );
    });

    test('does not fire for single-month streak', () {
      final transactions = [
        _txn(amount: 5000, type: TransactionType.income,
            date: DateTime(2023, 12, 1)),
        _txn(amount: 3000, type: TransactionType.expense,
            date: DateTime(2023, 12, 15)),
        // Nov: expense > income (breaks streak)
        _txn(amount: 1000, type: TransactionType.income,
            date: DateTime(2023, 11, 1)),
        _txn(amount: 4000, type: TransactionType.expense,
            date: DateTime(2023, 11, 15)),
      ];

      final insights = engine.generate(
          transactions: transactions, categories: [], now: now);

      expect(insights.any((i) => i.type == InsightType.achievement), isFalse);
    });
  });
}
