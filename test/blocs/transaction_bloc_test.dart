import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:spendsnap/features/transactions/data/transaction_repository.dart';
import 'package:spendsnap/features/transactions/domain/transaction_model.dart';
import 'package:spendsnap/features/transactions/presentation/bloc/transaction_bloc.dart';
import 'package:spendsnap/features/transactions/presentation/bloc/transaction_event.dart';
import 'package:spendsnap/features/transactions/presentation/bloc/transaction_state.dart';

class _MockTransactionRepo extends Mock implements TransactionRepository {}

// Fixed reference date — never call DateTime.now() in tests.
final _now = DateTime(2024, 1, 15);

TransactionModel _txn({
  String id = 'txn1',
  String uid = 'user1',
  double amount = 500.0,
  TransactionType type = TransactionType.expense,
  String categoryId = 'cat1',
  String? note,
  DateTime? date,
}) =>
    TransactionModel(
      id: id,
      uid: uid,
      amount: amount,
      type: type,
      categoryId: categoryId,
      note: note,
      date: date ?? _now,
    );

void main() {
  late _MockTransactionRepo repo;

  setUpAll(() {
    registerFallbackValue(
      TransactionModel(
        id: 'fallback',
        uid: 'user0',
        amount: 0.0,
        type: TransactionType.expense,
        categoryId: 'cat0',
        date: DateTime(2024, 1, 1),
      ),
    );
  });

  setUp(() {
    repo = _MockTransactionRepo();
  });

  group('TransactionBloc — initial state', () {
    test('initial state is TransactionInitial', () {
      final bloc = TransactionBloc(repo);
      expect(bloc.state, isA<TransactionInitial>());
      bloc.close();
    });
  });

  group('TransactionBloc — LoadTransactions', () {
    blocTest<TransactionBloc, TransactionState>(
      'emits [TransactionLoading, TransactionLoaded] when stream delivers items',
      setUp: () {
        when(() => repo.watchTransactions()).thenAnswer(
          (_) => Stream.value([
            _txn(id: 'a', amount: 100),
            _txn(id: 'b', amount: 200),
          ]),
        );
      },
      build: () => TransactionBloc(repo),
      act: (bloc) => bloc.add(const LoadTransactions()),
      expect: () => [
        isA<TransactionLoading>(),
        isA<TransactionLoaded>().having(
          (s) => s.transactions.length,
          'transactions count',
          2,
        ),
      ],
    );

    blocTest<TransactionBloc, TransactionState>(
      'emits [TransactionLoading, TransactionLoaded] with empty list on empty stream',
      setUp: () {
        when(() => repo.watchTransactions())
            .thenAnswer((_) => Stream.value([]));
      },
      build: () => TransactionBloc(repo),
      act: (bloc) => bloc.add(const LoadTransactions()),
      expect: () => [
        isA<TransactionLoading>(),
        isA<TransactionLoaded>().having(
          (s) => s.transactions,
          'transactions',
          isEmpty,
        ),
      ],
    );

    blocTest<TransactionBloc, TransactionState>(
      'emits [TransactionLoading, TransactionError] when stream emits an error',
      setUp: () {
        when(() => repo.watchTransactions()).thenAnswer(
          (_) => Stream.error(Exception('Firestore unavailable')),
        );
      },
      build: () => TransactionBloc(repo),
      act: (bloc) => bloc.add(const LoadTransactions()),
      expect: () => [
        isA<TransactionLoading>(),
        isA<TransactionError>(),
      ],
    );

    blocTest<TransactionBloc, TransactionState>(
      'loaded state has filtered list equal to all transactions on initial load',
      setUp: () {
        final txns = [_txn(id: 'x'), _txn(id: 'y')];
        when(() => repo.watchTransactions())
            .thenAnswer((_) => Stream.value(txns));
      },
      build: () => TransactionBloc(repo),
      act: (bloc) => bloc.add(const LoadTransactions()),
      expect: () => [
        isA<TransactionLoading>(),
        isA<TransactionLoaded>().having(
          (s) => s.filtered.length,
          'filtered equals all',
          2,
        ),
      ],
    );
  });

  group('TransactionBloc — AddTransaction', () {
    blocTest<TransactionBloc, TransactionState>(
      'calls repo.addTransaction and emits no new state on success',
      setUp: () {
        when(() => repo.addTransaction(any()))
            .thenAnswer((_) async {});
      },
      build: () => TransactionBloc(repo),
      act: (bloc) => bloc.add(AddTransaction(_txn())),
      expect: () => const <TransactionState>[],
      verify: (_) {
        verify(() => repo.addTransaction(any())).called(1);
      },
    );

    blocTest<TransactionBloc, TransactionState>(
      'emits TransactionError when addTransaction throws',
      setUp: () {
        when(() => repo.addTransaction(any()))
            .thenAnswer((_) async => throw Exception('Write failed'));
      },
      build: () => TransactionBloc(repo),
      act: (bloc) => bloc.add(AddTransaction(_txn())),
      expect: () => [isA<TransactionError>()],
    );
  });

  group('TransactionBloc — UpdateTransaction', () {
    blocTest<TransactionBloc, TransactionState>(
      'calls repo.updateTransaction and emits no new state on success',
      setUp: () {
        when(() => repo.updateTransaction(any()))
            .thenAnswer((_) async {});
      },
      build: () => TransactionBloc(repo),
      act: (bloc) => bloc.add(UpdateTransaction(_txn(id: 'txn-update'))),
      expect: () => const <TransactionState>[],
      verify: (_) {
        verify(() => repo.updateTransaction(any())).called(1);
      },
    );

    blocTest<TransactionBloc, TransactionState>(
      'emits TransactionError when updateTransaction throws',
      setUp: () {
        when(() => repo.updateTransaction(any()))
            .thenAnswer((_) async => throw Exception('Update failed'));
      },
      build: () => TransactionBloc(repo),
      act: (bloc) => bloc.add(UpdateTransaction(_txn())),
      expect: () => [isA<TransactionError>()],
    );
  });

  group('TransactionBloc — DeleteTransaction', () {
    blocTest<TransactionBloc, TransactionState>(
      'calls repo.deleteTransaction with the correct id on success',
      setUp: () {
        when(() => repo.deleteTransaction(any()))
            .thenAnswer((_) async {});
      },
      build: () => TransactionBloc(repo),
      act: (bloc) => bloc.add(const DeleteTransaction('txn-to-delete')),
      expect: () => const <TransactionState>[],
      verify: (_) {
        verify(() => repo.deleteTransaction('txn-to-delete')).called(1);
      },
    );

    blocTest<TransactionBloc, TransactionState>(
      'emits TransactionError when deleteTransaction throws',
      setUp: () {
        when(() => repo.deleteTransaction(any()))
            .thenAnswer((_) async => throw Exception('Delete failed'));
      },
      build: () => TransactionBloc(repo),
      act: (bloc) => bloc.add(const DeleteTransaction('bad-id')),
      expect: () => [isA<TransactionError>()],
    );
  });

  group('TransactionBloc — FilterTransactions (type filter)', () {
    // Seed the BLoC with two expense + one income before each filter test.
    final _seedTxns = [
      _txn(id: 'e1', type: TransactionType.expense, categoryId: 'cat1'),
      _txn(id: 'e2', type: TransactionType.expense, categoryId: 'cat2'),
      _txn(id: 'i1', type: TransactionType.income, categoryId: 'cat3'),
    ];

    TransactionBloc _buildSeeded() {
      when(() => repo.watchTransactions())
          .thenAnswer((_) => Stream.value(_seedTxns));
      return TransactionBloc(repo);
    }

    blocTest<TransactionBloc, TransactionState>(
      'filters to only expense transactions when typeFilter is expense',
      build: _buildSeeded,
      act: (bloc) async {
        bloc.add(const LoadTransactions());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const FilterTransactions(
          typeFilter: TransactionType.expense,
        ));
      },
      skip: 2, // skip Loading + initial Loaded
      expect: () => [
        isA<TransactionLoaded>().having(
          (s) => s.filtered.every((t) => t.type == TransactionType.expense),
          'all filtered are expenses',
          isTrue,
        ),
      ],
    );

    blocTest<TransactionBloc, TransactionState>(
      'filters to only income transactions when typeFilter is income',
      build: _buildSeeded,
      act: (bloc) async {
        bloc.add(const LoadTransactions());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const FilterTransactions(
          typeFilter: TransactionType.income,
        ));
      },
      skip: 2,
      expect: () => [
        isA<TransactionLoaded>().having(
          (s) => s.filtered.length,
          'filtered count',
          1,
        ),
      ],
    );

    blocTest<TransactionBloc, TransactionState>(
      'clearing a filter with FilterTransactions() shows all transactions again',
      build: _buildSeeded,
      act: (bloc) async {
        bloc.add(const LoadTransactions());
        await Future<void>.delayed(const Duration(milliseconds: 50));
        // Apply an expense-only filter first
        bloc.add(const FilterTransactions(typeFilter: TransactionType.expense));
        await Future<void>.delayed(const Duration(milliseconds: 50));
        // Clear the filter — should restore all 3
        bloc.add(const FilterTransactions());
        await Future<void>.delayed(const Duration(milliseconds: 50));
      },
      wait: const Duration(milliseconds: 200),
      skip: 2, // skip Loading + first Loaded (from stream)
      expect: () => [
        // After expense filter: 2 items
        isA<TransactionLoaded>().having(
          (s) => s.filtered.length,
          'filtered to expenses only',
          2,
        ),
        // After clear: all 3 restored
        isA<TransactionLoaded>().having(
          (s) => s.filtered.length,
          'all 3 transactions restored after filter cleared',
          3,
        ),
      ],
    );
  });

  group('TransactionBloc — FilterTransactions (category filter)', () {
    final _seedTxns = [
      _txn(id: 't1', categoryId: 'cat-food'),
      _txn(id: 't2', categoryId: 'cat-transport'),
      _txn(id: 't3', categoryId: 'cat-food'),
    ];

    TransactionBloc _buildSeeded() {
      when(() => repo.watchTransactions())
          .thenAnswer((_) => Stream.value(_seedTxns));
      return TransactionBloc(repo);
    }

    blocTest<TransactionBloc, TransactionState>(
      'filters to transactions matching the category filter list',
      build: _buildSeeded,
      act: (bloc) async {
        bloc.add(const LoadTransactions());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const FilterTransactions(
          categoryFilters: ['cat-food'],
        ));
      },
      skip: 2,
      expect: () => [
        isA<TransactionLoaded>().having(
          (s) => s.filtered.length,
          'food transactions only',
          2,
        ),
      ],
    );
  });

  group('TransactionBloc — FilterTransactions (date range filter)', () {
    final early = DateTime(2024, 1, 5);
    final mid = DateTime(2024, 1, 10);
    final late_ = DateTime(2024, 1, 20);

    final _seedTxns = [
      _txn(id: 'd1', date: early),
      _txn(id: 'd2', date: mid),
      _txn(id: 'd3', date: late_),
    ];

    TransactionBloc _buildSeeded() {
      when(() => repo.watchTransactions())
          .thenAnswer((_) => Stream.value(_seedTxns));
      return TransactionBloc(repo);
    }

    blocTest<TransactionBloc, TransactionState>(
      'filters out transactions before the "from" date',
      build: _buildSeeded,
      act: (bloc) async {
        bloc.add(const LoadTransactions());
        await Future<void>.delayed(Duration.zero);
        bloc.add(FilterTransactions(
          from: DateTime(2024, 1, 7),
        ));
      },
      skip: 2,
      expect: () => [
        isA<TransactionLoaded>().having(
          (s) => s.filtered.map((t) => t.id).toList(),
          'only mid and late',
          containsAll(['d2', 'd3']),
        ),
      ],
    );

    blocTest<TransactionBloc, TransactionState>(
      'filters out transactions after the "to" date',
      build: _buildSeeded,
      act: (bloc) async {
        bloc.add(const LoadTransactions());
        await Future<void>.delayed(Duration.zero);
        bloc.add(FilterTransactions(
          to: DateTime(2024, 1, 12),
        ));
      },
      skip: 2,
      expect: () => [
        isA<TransactionLoaded>().having(
          (s) => s.filtered.map((t) => t.id).toList(),
          'only early and mid',
          containsAll(['d1', 'd2']),
        ),
      ],
    );
  });

  group('TransactionBloc — FilterTransactions (search filter)', () {
    final _seedTxns = [
      _txn(id: 's1', note: 'Lunch at Cafe', categoryId: 'cat-food'),
      _txn(id: 's2', note: 'Uber ride', categoryId: 'cat-transport'),
      _txn(id: 's3', amount: 123.0, categoryId: 'cat-other'),
    ];

    TransactionBloc _buildSeeded() {
      when(() => repo.watchTransactions())
          .thenAnswer((_) => Stream.value(_seedTxns));
      return TransactionBloc(repo);
    }

    blocTest<TransactionBloc, TransactionState>(
      'filters by note substring (case-insensitive)',
      build: _buildSeeded,
      act: (bloc) async {
        bloc.add(const LoadTransactions());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const FilterTransactions(searchQuery: 'lunch'));
      },
      skip: 2,
      expect: () => [
        isA<TransactionLoaded>().having(
          (s) => s.filtered.length,
          'matched note count',
          1,
        ),
      ],
    );

    blocTest<TransactionBloc, TransactionState>(
      'filters by amount substring',
      build: _buildSeeded,
      act: (bloc) async {
        bloc.add(const LoadTransactions());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const FilterTransactions(searchQuery: '123'));
      },
      skip: 2,
      expect: () => [
        isA<TransactionLoaded>().having(
          (s) => s.filtered.any((t) => t.id == 's3'),
          'matched amount transaction found',
          isTrue,
        ),
      ],
    );

    blocTest<TransactionBloc, TransactionState>(
      'filters by category name when categoryNames map is provided',
      build: _buildSeeded,
      act: (bloc) async {
        bloc.add(const LoadTransactions());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const FilterTransactions(
          searchQuery: 'transport',
          categoryNames: {
            'cat-food': 'Food',
            'cat-transport': 'Transport',
            'cat-other': 'Other',
          },
        ));
      },
      skip: 2,
      expect: () => [
        isA<TransactionLoaded>().having(
          (s) => s.filtered.map((t) => t.id).toList(),
          'transport category matched',
          contains('s2'),
        ),
      ],
    );

    blocTest<TransactionBloc, TransactionState>(
      'returns empty filtered list when search query matches nothing',
      build: _buildSeeded,
      act: (bloc) async {
        bloc.add(const LoadTransactions());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const FilterTransactions(searchQuery: 'zzznomatch'));
      },
      skip: 2,
      expect: () => [
        isA<TransactionLoaded>().having(
          (s) => s.filtered,
          'filtered is empty',
          isEmpty,
        ),
      ],
    );
  });

  group('TransactionBloc — FilterTransactions (persists state after filter)', () {
    blocTest<TransactionBloc, TransactionState>(
      'retains all transactions in state.transactions while narrowing state.filtered',
      setUp: () {
        when(() => repo.watchTransactions()).thenAnswer(
          (_) => Stream.value([
            _txn(id: 'e1', type: TransactionType.expense),
            _txn(id: 'i1', type: TransactionType.income),
          ]),
        );
      },
      build: () => TransactionBloc(repo),
      act: (bloc) async {
        bloc.add(const LoadTransactions());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const FilterTransactions(
          typeFilter: TransactionType.expense,
        ));
      },
      skip: 2,
      expect: () => [
        isA<TransactionLoaded>()
            .having((s) => s.transactions.length, 'all transactions', 2)
            .having((s) => s.filtered.length, 'filtered transactions', 1),
      ],
    );
  });
}
