import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:spendsnap/features/budgets/presentation/bloc/budget_bloc.dart';
import 'package:spendsnap/features/budgets/presentation/bloc/budget_event.dart';
import 'package:spendsnap/features/budgets/presentation/bloc/budget_state.dart';
import 'package:spendsnap/features/categories/data/category_repository.dart';
import 'package:spendsnap/features/categories/domain/category_model.dart';
import 'package:spendsnap/features/transactions/data/transaction_repository.dart';
import 'package:spendsnap/features/transactions/domain/transaction_model.dart';

class _MockCategoryRepo extends Mock implements CategoryRepository {}

class _MockTransactionRepo extends Mock implements TransactionRepository {}

// Factory helpers.
CategoryModel _cat({
  String id = 'cat1',
  String uid = 'user1',
  String name = 'Food',
  String icon = 'food',
  String color = '#D85A30',
  double? monthlyLimit = 5000.0,
  bool isIncome = false,
}) =>
    CategoryModel(
      id: id,
      uid: uid,
      name: name,
      icon: icon,
      color: color,
      monthlyLimit: monthlyLimit,
      isIncome: isIncome,
    );

TransactionModel _txn({
  String id = 'txn1',
  String uid = 'user1',
  double amount = 1000.0,
  TransactionType type = TransactionType.expense,
  String categoryId = 'cat1',
  DateTime? date,
}) =>
    TransactionModel(
      id: id,
      uid: uid,
      amount: amount,
      type: type,
      categoryId: categoryId,
      date: date ?? DateTime(2024, 1, 10),
    );

void main() {
  late _MockCategoryRepo catRepo;
  late _MockTransactionRepo txnRepo;

  setUp(() {
    catRepo = _MockCategoryRepo();
    txnRepo = _MockTransactionRepo();
  });

  group('BudgetBloc — initial state', () {
    test('initial state is BudgetInitial', () {
      final bloc = BudgetBloc(catRepo, txnRepo);
      expect(bloc.state, isA<BudgetInitial>());
      bloc.close();
    });
  });

  group('BudgetBloc — LoadBudgets', () {
    blocTest<BudgetBloc, BudgetState>(
      'emits [BudgetLoading, BudgetLoaded] for categories with limits',
      setUp: () {
        when(() => catRepo.fetchCategories()).thenAnswer(
          (_) async => [_cat(id: 'cat-food', monthlyLimit: 5000.0)],
        );
        when(() => txnRepo.fetchTransactions(
            from: any(named: 'from'), to: any(named: 'to'))).thenAnswer(
          (_) async => [_txn(id: 't1', categoryId: 'cat-food', amount: 1500.0)],
        );
      },
      build: () => BudgetBloc(catRepo, txnRepo),
      act: (bloc) => bloc.add(const LoadBudgets()),
      expect: () => [
        isA<BudgetLoading>(),
        isA<BudgetLoaded>().having(
          (s) => s.budgets.length,
          'budget count',
          1,
        ),
      ],
    );

    blocTest<BudgetBloc, BudgetState>(
      'computes totalBudget as sum of all limits',
      setUp: () {
        when(() => catRepo.fetchCategories()).thenAnswer(
          (_) async => [
            _cat(id: 'cat-a', monthlyLimit: 3000.0),
            _cat(id: 'cat-b', monthlyLimit: 2000.0),
          ],
        );
        when(() => txnRepo.fetchTransactions(
            from: any(named: 'from'),
            to: any(named: 'to'))).thenAnswer((_) async => []);
      },
      build: () => BudgetBloc(catRepo, txnRepo),
      act: (bloc) => bloc.add(const LoadBudgets()),
      skip: 1,
      expect: () => [
        isA<BudgetLoaded>().having(
          (s) => s.totalBudget,
          'totalBudget',
          closeTo(5000.0, 0.001),
        ),
      ],
    );

    blocTest<BudgetBloc, BudgetState>(
      'computes totalSpent as sum of expenses in budget categories',
      setUp: () {
        when(() => catRepo.fetchCategories()).thenAnswer(
          (_) async => [_cat(id: 'cat-food', monthlyLimit: 5000.0)],
        );
        when(() => txnRepo.fetchTransactions(
            from: any(named: 'from'), to: any(named: 'to'))).thenAnswer(
          (_) async => [
            _txn(id: 't1', categoryId: 'cat-food', amount: 1200.0),
            _txn(id: 't2', categoryId: 'cat-food', amount: 800.0),
          ],
        );
      },
      build: () => BudgetBloc(catRepo, txnRepo),
      act: (bloc) => bloc.add(const LoadBudgets()),
      skip: 1,
      expect: () => [
        isA<BudgetLoaded>().having(
          (s) => s.totalSpent,
          'totalSpent',
          closeTo(2000.0, 0.001),
        ),
      ],
    );

    blocTest<BudgetBloc, BudgetState>(
      'excludes categories without a monthlyLimit from budget list',
      setUp: () {
        when(() => catRepo.fetchCategories()).thenAnswer(
          (_) async => [
            _cat(id: 'cat-budgeted', monthlyLimit: 3000.0),
            // This category has no limit and should not appear in budgets.
            _cat(id: 'cat-unlimited', monthlyLimit: null),
          ],
        );
        when(() => txnRepo.fetchTransactions(
            from: any(named: 'from'),
            to: any(named: 'to'))).thenAnswer((_) async => []);
      },
      build: () => BudgetBloc(catRepo, txnRepo),
      act: (bloc) => bloc.add(const LoadBudgets()),
      skip: 1,
      expect: () => [
        isA<BudgetLoaded>().having(
          (s) => s.budgets.length,
          'only budgeted categories',
          1,
        ),
      ],
    );

    blocTest<BudgetBloc, BudgetState>(
      'excludes income transactions from spent calculation',
      setUp: () {
        when(() => catRepo.fetchCategories()).thenAnswer(
          (_) async => [_cat(id: 'cat-food', monthlyLimit: 5000.0)],
        );
        when(() => txnRepo.fetchTransactions(
            from: any(named: 'from'), to: any(named: 'to'))).thenAnswer(
          (_) async => [
            _txn(
                id: 'expense',
                categoryId: 'cat-food',
                amount: 500.0,
                type: TransactionType.expense),
            _txn(
                id: 'income',
                categoryId: 'cat-food',
                amount: 2000.0,
                type: TransactionType.income),
          ],
        );
      },
      build: () => BudgetBloc(catRepo, txnRepo),
      act: (bloc) => bloc.add(const LoadBudgets()),
      skip: 1,
      expect: () => [
        isA<BudgetLoaded>().having(
          (s) => s.totalSpent,
          'only expenses counted',
          closeTo(500.0, 0.001),
        ),
      ],
    );

    blocTest<BudgetBloc, BudgetState>(
      'emits BudgetLoaded with empty budgets when no categories have limits',
      setUp: () {
        when(() => catRepo.fetchCategories()).thenAnswer(
          (_) async => [_cat(monthlyLimit: null)],
        );
        when(() => txnRepo.fetchTransactions(
            from: any(named: 'from'),
            to: any(named: 'to'))).thenAnswer((_) async => []);
      },
      build: () => BudgetBloc(catRepo, txnRepo),
      act: (bloc) => bloc.add(const LoadBudgets()),
      expect: () => [
        isA<BudgetLoading>(),
        isA<BudgetLoaded>().having(
          (s) => s.budgets,
          'no budgets',
          isEmpty,
        ),
      ],
    );

    blocTest<BudgetBloc, BudgetState>(
      'emits BudgetError when fetchCategories throws',
      setUp: () {
        when(() => catRepo.fetchCategories())
            .thenAnswer((_) async => throw Exception('Firestore error'));
        when(() => txnRepo.fetchTransactions(
            from: any(named: 'from'),
            to: any(named: 'to'))).thenAnswer((_) async => []);
      },
      build: () => BudgetBloc(catRepo, txnRepo),
      act: (bloc) => bloc.add(const LoadBudgets()),
      expect: () => [
        isA<BudgetLoading>(),
        isA<BudgetError>(),
      ],
    );

    blocTest<BudgetBloc, BudgetState>(
      'emits BudgetError when fetchTransactions throws',
      setUp: () {
        when(() => catRepo.fetchCategories()).thenAnswer((_) async => [_cat()]);
        when(() => txnRepo.fetchTransactions(
                from: any(named: 'from'), to: any(named: 'to')))
            .thenAnswer(
                (_) async => throw Exception('Transaction fetch failed'));
      },
      build: () => BudgetBloc(catRepo, txnRepo),
      act: (bloc) => bloc.add(const LoadBudgets()),
      expect: () => [
        isA<BudgetLoading>(),
        isA<BudgetError>(),
      ],
    );
  });

  group('BudgetBloc — SetBudgetLimit', () {
    blocTest<BudgetBloc, BudgetState>(
      'calls updateBudgetLimit then re-fetches and emits BudgetLoaded',
      setUp: () {
        when(() => catRepo.updateBudgetLimit(any(), any()))
            .thenAnswer((_) async {});
        when(() => catRepo.fetchCategories()).thenAnswer(
          (_) async => [_cat(id: 'cat-food', monthlyLimit: 7000.0)],
        );
        when(() => txnRepo.fetchTransactions(
            from: any(named: 'from'),
            to: any(named: 'to'))).thenAnswer((_) async => []);
      },
      build: () => BudgetBloc(catRepo, txnRepo),
      act: (bloc) => bloc.add(const SetBudgetLimit('cat-food', 7000.0)),
      expect: () => [
        isA<BudgetLoaded>(),
      ],
      verify: (_) {
        verify(() => catRepo.updateBudgetLimit('cat-food', 7000.0)).called(1);
        verify(() => catRepo.fetchCategories()).called(1);
      },
    );

    blocTest<BudgetBloc, BudgetState>(
      'passes null to updateBudgetLimit when removing a limit',
      setUp: () {
        when(() => catRepo.updateBudgetLimit(any(), any()))
            .thenAnswer((_) async {});
        when(() => catRepo.fetchCategories())
            .thenAnswer((_) async => [_cat(monthlyLimit: null)]);
        when(() => txnRepo.fetchTransactions(
            from: any(named: 'from'),
            to: any(named: 'to'))).thenAnswer((_) async => []);
      },
      build: () => BudgetBloc(catRepo, txnRepo),
      act: (bloc) => bloc.add(const SetBudgetLimit('cat-food', null)),
      expect: () => [isA<BudgetLoaded>()],
      verify: (_) {
        verify(() => catRepo.updateBudgetLimit('cat-food', null)).called(1);
      },
    );

    blocTest<BudgetBloc, BudgetState>(
      'emits BudgetError when updateBudgetLimit throws',
      setUp: () {
        when(() => catRepo.updateBudgetLimit(any(), any()))
            .thenAnswer((_) async => throw Exception('Update failed'));
      },
      build: () => BudgetBloc(catRepo, txnRepo),
      act: (bloc) => bloc.add(const SetBudgetLimit('cat-food', 3000.0)),
      expect: () => [isA<BudgetError>()],
    );
  });
}
