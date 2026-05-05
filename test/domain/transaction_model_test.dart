import 'package:flutter_test/flutter_test.dart';
import 'package:spendsnap/features/transactions/domain/transaction_model.dart';

// Factory helper — only specify fields relevant to each test.
TransactionModel _txn({
  String id = 'txn1',
  String uid = 'user1',
  double amount = 500.0,
  TransactionType type = TransactionType.expense,
  String categoryId = 'cat1',
  String? note,
  DateTime? date,
  bool isRecurring = false,
  String? recurringFrequency,
}) =>
    TransactionModel(
      id: id,
      uid: uid,
      amount: amount,
      type: type,
      categoryId: categoryId,
      note: note,
      date: date ?? DateTime(2024, 1, 15),
      isRecurring: isRecurring,
      recurringFrequency: recurringFrequency,
    );

void main() {
  // Fixed reference date — never call DateTime.now() in tests.
  final _now = DateTime(2024, 1, 15);

  group('TransactionModel — toFirestore', () {
    test('serialises income type as the string "income"', () {
      final map = _txn(type: TransactionType.income).toFirestore();
      expect(map['type'], 'income',
          reason: 'Income transactions must be stored as the string "income"');
    });

    test('serialises expense type as the string "expense"', () {
      final map = _txn(type: TransactionType.expense).toFirestore();
      expect(map['type'], 'expense');
    });

    test('serialises all required scalar fields correctly', () {
      final txn = _txn(
        uid: 'user42',
        amount: 1234.56,
        categoryId: 'cat-food',
        note: 'Lunch',
        date: _now,
      );
      final map = txn.toFirestore();

      expect(map['uid'], 'user42');
      expect(map['amount'], closeTo(1234.56, 0.001));
      expect(map['categoryId'], 'cat-food');
      expect(map['note'], 'Lunch');
    });

    test('null note is preserved as null in serialisation', () {
      final map = _txn(note: null).toFirestore();
      expect(map.containsKey('note'), isTrue);
      expect(map['note'], isNull);
    });

    test('isRecurring defaults to false when not supplied', () {
      final map = _txn().toFirestore();
      expect(map['isRecurring'], isFalse);
    });

    test('isRecurring and recurringFrequency are serialised when provided', () {
      final map = _txn(
        isRecurring: true,
        recurringFrequency: 'monthly',
      ).toFirestore();
      expect(map['isRecurring'], isTrue);
      expect(map['recurringFrequency'], 'monthly');
    });
  });

  group('TransactionModel — toFirestore round-trip (map equality)', () {
    test('expense transaction survives a manual map round-trip', () {
      final original = _txn(
        id: 'round1',
        uid: 'user1',
        amount: 750.0,
        type: TransactionType.expense,
        categoryId: 'cat-transport',
        note: 'Uber',
        date: _now,
        isRecurring: false,
      );

      final map = original.toFirestore();

      // Reconstruct manually (mirrors fromFirestore field-by-field logic).
      final restored = TransactionModel(
        id: original.id,
        uid: map['uid'] as String,
        amount: (map['amount'] as num).toDouble(),
        type: map['type'] == 'income'
            ? TransactionType.income
            : TransactionType.expense,
        categoryId: map['categoryId'] as String,
        note: map['note'] as String?,
        date: original.date, // Timestamp skipped — pure-Dart test
        isRecurring: map['isRecurring'] as bool,
        recurringFrequency: map['recurringFrequency'] as String?,
      );

      expect(restored.uid, original.uid);
      expect(restored.amount, closeTo(original.amount, 0.001));
      expect(restored.type, original.type);
      expect(restored.categoryId, original.categoryId);
      expect(restored.note, original.note);
      expect(restored.isRecurring, original.isRecurring);
    });

    test('income transaction round-trips correctly', () {
      final original = _txn(
        type: TransactionType.income,
        amount: 50000.0,
        note: 'Salary',
      );
      final map = original.toFirestore();
      expect(map['type'], 'income');
      expect((map['amount'] as num).toDouble(), closeTo(50000.0, 0.001));
    });
  });

  group('TransactionModel — copyWith', () {
    test('creates a new instance with updated amount', () {
      final original = _txn(amount: 100.0);
      final updated = original.copyWith(amount: 200.0);
      expect(updated.amount, closeTo(200.0, 0.001));
      expect(updated.id, original.id,
          reason: 'Unspecified fields must remain unchanged');
    });

    test('changing type does not mutate the original', () {
      final original = _txn(type: TransactionType.expense);
      final updated = original.copyWith(type: TransactionType.income);
      expect(updated.type, TransactionType.income);
      expect(original.type, TransactionType.expense,
          reason: 'copyWith must not mutate the source instance');
    });

    test('note can be overridden via copyWith', () {
      final original = _txn(note: 'Old note');
      final updated = original.copyWith(note: 'New note');
      expect(updated.note, 'New note');
    });
  });

  group('TransactionModel — equatable identity', () {
    test('two instances with identical props are equal', () {
      final a = _txn(id: 'x', date: _now);
      final b = _txn(id: 'x', date: _now);
      expect(a, equals(b));
    });

    test('instances with different ids are not equal', () {
      final a = _txn(id: 'x');
      final b = _txn(id: 'y');
      expect(a, isNot(equals(b)));
    });
  });
}
