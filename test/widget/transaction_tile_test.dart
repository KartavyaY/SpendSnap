import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendsnap/features/categories/domain/category_model.dart';
import 'package:spendsnap/features/transactions/domain/transaction_model.dart';
import 'package:spendsnap/shared/widgets/transaction_tile.dart';
import 'package:spendsnap/core/theme/app_colors.dart';

const _category = CategoryModel(
  id: 'cat1',
  uid: 'user1',
  name: 'Food',
  icon: '🍔',
  color: '#D85A30',
);

TransactionModel _makeTransaction({
  TransactionType type = TransactionType.expense,
  double amount = 500,
  String? note,
}) =>
    TransactionModel(
      id: 'txn1',
      uid: 'user1',
      amount: amount,
      type: type,
      categoryId: 'cat1',
      note: note,
      date: DateTime.now(),
    );

void main() {
  group('TransactionTile', () {
    testWidgets('shows + sign and green color for income', (tester) async {
      final txn = _makeTransaction(type: TransactionType.income, amount: 1000);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransactionTile(
              transaction: txn,
              category: _category,
            ),
          ),
        ),
      );

      expect(find.textContaining('+'), findsOneWidget);
      final amountText = tester.widget<Text>(find.textContaining('+'));
      expect(amountText.style?.color, AppColors.success);
    });

    testWidgets('shows - sign and red color for expense', (tester) async {
      final txn = _makeTransaction(type: TransactionType.expense, amount: 500);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransactionTile(
              transaction: txn,
              category: _category,
            ),
          ),
        ),
      );

      expect(find.textContaining('-'), findsOneWidget);
      final amountText = tester.widget<Text>(find.textContaining('-'));
      expect(amountText.style?.color, AppColors.ink);
    });

    testWidgets('tap callback fires on tile tap', (tester) async {
      bool tapped = false;
      final txn = _makeTransaction();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransactionTile(
              transaction: txn,
              category: _category,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(InkWell).first);
      expect(tapped, isTrue);
    });

    testWidgets('shows note when provided', (tester) async {
      final txn = _makeTransaction(note: 'Lunch with team');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransactionTile(
              transaction: txn,
              category: _category,
            ),
          ),
        ),
      );

      expect(find.text('Lunch with team'), findsOneWidget);
    });

    testWidgets('shows category name', (tester) async {
      final txn = _makeTransaction();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransactionTile(
              transaction: txn,
              category: _category,
            ),
          ),
        ),
      );

      expect(find.text('Food'), findsOneWidget);
    });
  });
}
