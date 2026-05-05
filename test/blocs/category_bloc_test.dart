import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:spendsnap/features/categories/data/category_repository.dart';
import 'package:spendsnap/features/categories/domain/category_model.dart';
import 'package:spendsnap/features/categories/presentation/bloc/category_bloc.dart';
import 'package:spendsnap/features/categories/presentation/bloc/category_event.dart';
import 'package:spendsnap/features/categories/presentation/bloc/category_state.dart';

class _MockCategoryRepo extends Mock implements CategoryRepository {}

// Factory helper.
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
  late _MockCategoryRepo repo;

  setUpAll(() {
    registerFallbackValue(
      const CategoryModel(
        id: 'fallback',
        uid: 'user0',
        name: 'Fallback',
        icon: 'other',
        color: '#888780',
      ),
    );
  });

  setUp(() {
    repo = _MockCategoryRepo();
  });

  group('CategoryBloc — initial state', () {
    test('initial state is CategoryInitial', () {
      final bloc = CategoryBloc(repo);
      expect(bloc.state, isA<CategoryInitial>());
      bloc.close();
    });
  });

  group('CategoryBloc — LoadCategories', () {
    blocTest<CategoryBloc, CategoryState>(
      'emits [CategoryLoading, CategoryLoaded] when stream delivers categories',
      setUp: () {
        when(() => repo.watchCategories()).thenAnswer(
          (_) => Stream.value([_cat(id: 'c1'), _cat(id: 'c2')]),
        );
      },
      build: () => CategoryBloc(repo),
      act: (bloc) => bloc.add(const LoadCategories()),
      expect: () => [
        isA<CategoryLoading>(),
        isA<CategoryLoaded>().having(
          (s) => s.categories.length,
          'category count',
          2,
        ),
      ],
    );

    blocTest<CategoryBloc, CategoryState>(
      'calls seedDefaultCategories and does NOT emit CategoryLoaded when stream delivers empty list',
      setUp: () {
        when(() => repo.watchCategories())
            .thenAnswer((_) => Stream.value([]));
        when(() => repo.seedDefaultCategories()).thenAnswer((_) async {});
      },
      build: () => CategoryBloc(repo),
      act: (bloc) => bloc.add(const LoadCategories()),
      // The bloc only emits Loading, then skips the loaded emission for the
      // empty case to wait for the seeded data to arrive via the stream.
      expect: () => [isA<CategoryLoading>()],
      verify: (_) {
        verify(() => repo.seedDefaultCategories()).called(1);
      },
    );

    blocTest<CategoryBloc, CategoryState>(
      'emits [CategoryLoading, CategoryError] when stream emits an error',
      setUp: () {
        when(() => repo.watchCategories())
            .thenAnswer((_) => Stream.error(Exception('Permission denied')));
      },
      build: () => CategoryBloc(repo),
      act: (bloc) => bloc.add(const LoadCategories()),
      expect: () => [
        isA<CategoryLoading>(),
        isA<CategoryError>(),
      ],
    );
  });

  group('CategoryBloc — AddCategory', () {
    blocTest<CategoryBloc, CategoryState>(
      'calls repo.addCategory and emits no extra state on success',
      setUp: () {
        when(() => repo.addCategory(any())).thenAnswer((_) async {});
      },
      build: () => CategoryBloc(repo),
      act: (bloc) => bloc.add(AddCategory(_cat(id: 'new-cat'))),
      expect: () => const <CategoryState>[],
      verify: (_) {
        verify(() => repo.addCategory(any())).called(1);
      },
    );

    blocTest<CategoryBloc, CategoryState>(
      'emits CategoryError when addCategory throws',
      setUp: () {
        when(() => repo.addCategory(any()))
            .thenAnswer((_) async => throw Exception('Firestore write error'));
      },
      build: () => CategoryBloc(repo),
      act: (bloc) => bloc.add(AddCategory(_cat())),
      expect: () => [isA<CategoryError>()],
    );

    blocTest<CategoryBloc, CategoryState>(
      'forwards AddCategory event to repo unconditionally (no duplicate-name guard in bloc)',
      setUp: () {
        when(() => repo.addCategory(any())).thenAnswer((_) async {});
      },
      build: () => CategoryBloc(repo),
      act: (bloc) => bloc.add(AddCategory(_cat(name: 'Food'))),
      expect: () => const <CategoryState>[],
      verify: (_) {
        // Bloc must call addCategory exactly once — no silent drops.
        verify(() => repo.addCategory(any())).called(1);
      },
    );
  });

  group('CategoryBloc — UpdateCategory', () {
    blocTest<CategoryBloc, CategoryState>(
      'calls repo.updateCategory on success',
      setUp: () {
        when(() => repo.updateCategory(any())).thenAnswer((_) async {});
      },
      build: () => CategoryBloc(repo),
      act: (bloc) =>
          bloc.add(UpdateCategory(_cat(id: 'cat-upd', name: 'Updated'))),
      expect: () => const <CategoryState>[],
      verify: (_) {
        verify(() => repo.updateCategory(any())).called(1);
      },
    );

    blocTest<CategoryBloc, CategoryState>(
      'emits CategoryError when updateCategory throws',
      setUp: () {
        when(() => repo.updateCategory(any()))
            .thenAnswer((_) async => throw Exception('Update failed'));
      },
      build: () => CategoryBloc(repo),
      act: (bloc) => bloc.add(UpdateCategory(_cat())),
      expect: () => [isA<CategoryError>()],
    );
  });

  group('CategoryBloc — DeleteCategory', () {
    blocTest<CategoryBloc, CategoryState>(
      'calls repo.deleteCategory with the correct id',
      setUp: () {
        when(() => repo.deleteCategory(any())).thenAnswer((_) async {});
      },
      build: () => CategoryBloc(repo),
      act: (bloc) => bloc.add(const DeleteCategory('cat-to-delete')),
      expect: () => const <CategoryState>[],
      verify: (_) {
        verify(() => repo.deleteCategory('cat-to-delete')).called(1);
      },
    );

    blocTest<CategoryBloc, CategoryState>(
      'emits CategoryError when deleteCategory throws',
      setUp: () {
        when(() => repo.deleteCategory(any()))
            .thenAnswer((_) async => throw Exception('Delete failed'));
      },
      build: () => CategoryBloc(repo),
      act: (bloc) => bloc.add(const DeleteCategory('bad-id')),
      expect: () => [isA<CategoryError>()],
    );
  });

  group('CategoryBloc — UpdateBudgetLimit', () {
    blocTest<CategoryBloc, CategoryState>(
      'calls repo.updateBudgetLimit with the correct id and limit value',
      setUp: () {
        when(() => repo.updateBudgetLimit(any(), any()))
            .thenAnswer((_) async {});
      },
      build: () => CategoryBloc(repo),
      act: (bloc) =>
          bloc.add(const UpdateBudgetLimit('cat-food', 3000.0)),
      expect: () => const <CategoryState>[],
      verify: (_) {
        verify(() => repo.updateBudgetLimit('cat-food', 3000.0)).called(1);
      },
    );

    blocTest<CategoryBloc, CategoryState>(
      'passes null to repo.updateBudgetLimit when removing a limit',
      setUp: () {
        when(() => repo.updateBudgetLimit(any(), any()))
            .thenAnswer((_) async {});
      },
      build: () => CategoryBloc(repo),
      act: (bloc) => bloc.add(const UpdateBudgetLimit('cat-food', null)),
      expect: () => const <CategoryState>[],
      verify: (_) {
        verify(() => repo.updateBudgetLimit('cat-food', null)).called(1);
      },
    );

    blocTest<CategoryBloc, CategoryState>(
      'emits CategoryError when updateBudgetLimit throws',
      setUp: () {
        when(() => repo.updateBudgetLimit(any(), any()))
            .thenAnswer((_) async => throw Exception('Limit update failed'));
      },
      build: () => CategoryBloc(repo),
      act: (bloc) =>
          bloc.add(const UpdateBudgetLimit('cat-food', 1000.0)),
      expect: () => [isA<CategoryError>()],
    );
  });
}
