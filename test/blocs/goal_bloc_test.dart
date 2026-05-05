import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:spendsnap/features/goals/data/goal_repository.dart';
import 'package:spendsnap/features/goals/domain/goal_model.dart';
import 'package:spendsnap/features/goals/presentation/bloc/goal_bloc.dart';
import 'package:spendsnap/features/goals/presentation/bloc/goal_event.dart';
import 'package:spendsnap/features/goals/presentation/bloc/goal_state.dart';

class _MockGoalRepo extends Mock implements GoalRepository {}

// Fixed reference date.
final _now = DateTime(2024, 1, 15);

// Factory helper.
GoalModel _goal({
  String id = 'goal1',
  String uid = 'user1',
  String title = 'Emergency Fund',
  double targetAmount = 10000.0,
  double currentAmount = 0.0,
  GoalStatus status = GoalStatus.active,
  DateTime? createdAt,
}) =>
    GoalModel(
      id: id,
      uid: uid,
      title: title,
      targetAmount: targetAmount,
      currentAmount: currentAmount,
      status: status,
      createdAt: createdAt ?? _now,
    );

void main() {
  late _MockGoalRepo repo;

  setUpAll(() {
    registerFallbackValue(
      GoalModel(
        id: 'fallback',
        uid: 'user0',
        title: 'Fallback',
        targetAmount: 1.0,
        currentAmount: 0.0,
        status: GoalStatus.active,
        createdAt: DateTime(2024, 1, 1),
      ),
    );
  });

  setUp(() {
    repo = _MockGoalRepo();
  });

  group('GoalBloc — initial state', () {
    test('initial state is GoalInitial', () {
      final bloc = GoalBloc(repo);
      expect(bloc.state, isA<GoalInitial>());
      bloc.close();
    });
  });

  group('GoalBloc — LoadGoals', () {
    blocTest<GoalBloc, GoalState>(
      'emits [GoalLoading, GoalLoaded] when stream delivers goals',
      setUp: () {
        when(() => repo.watchGoals()).thenAnswer(
          (_) => Stream.value([
            _goal(id: 'g1'),
            _goal(id: 'g2', status: GoalStatus.completed),
          ]),
        );
      },
      build: () => GoalBloc(repo),
      act: (bloc) => bloc.add(const LoadGoals()),
      expect: () => [
        isA<GoalLoading>(),
        isA<GoalLoaded>().having(
          (s) => s.goals.length,
          'goals count',
          2,
        ),
      ],
    );

    blocTest<GoalBloc, GoalState>(
      'GoalLoaded active and completed accessors split correctly',
      setUp: () {
        when(() => repo.watchGoals()).thenAnswer(
          (_) => Stream.value([
            _goal(id: 'active1', status: GoalStatus.active),
            _goal(id: 'active2', status: GoalStatus.active),
            _goal(id: 'done1', status: GoalStatus.completed),
          ]),
        );
      },
      build: () => GoalBloc(repo),
      act: (bloc) => bloc.add(const LoadGoals()),
      skip: 1, // skip Loading
      expect: () => [
        isA<GoalLoaded>()
            .having((s) => s.active.length, 'active count', 2)
            .having((s) => s.completed.length, 'completed count', 1),
      ],
    );

    blocTest<GoalBloc, GoalState>(
      'emits [GoalLoading, GoalLoaded] with empty goals list',
      setUp: () {
        when(() => repo.watchGoals())
            .thenAnswer((_) => Stream.value([]));
      },
      build: () => GoalBloc(repo),
      act: (bloc) => bloc.add(const LoadGoals()),
      expect: () => [
        isA<GoalLoading>(),
        isA<GoalLoaded>().having((s) => s.goals, 'empty goals', isEmpty),
      ],
    );

    blocTest<GoalBloc, GoalState>(
      'emits [GoalLoading, GoalError] when stream emits an error',
      setUp: () {
        when(() => repo.watchGoals())
            .thenAnswer((_) => Stream.error(Exception('Network error')));
      },
      build: () => GoalBloc(repo),
      act: (bloc) => bloc.add(const LoadGoals()),
      expect: () => [
        isA<GoalLoading>(),
        isA<GoalError>(),
      ],
    );
  });

  group('GoalBloc — AddGoal', () {
    blocTest<GoalBloc, GoalState>(
      'calls repo.addGoal and emits no extra state on success',
      setUp: () {
        when(() => repo.addGoal(any())).thenAnswer((_) async {});
      },
      build: () => GoalBloc(repo),
      act: (bloc) => bloc.add(AddGoal(_goal(id: 'new-goal'))),
      expect: () => const <GoalState>[],
      verify: (_) {
        verify(() => repo.addGoal(any())).called(1);
      },
    );

    blocTest<GoalBloc, GoalState>(
      'emits GoalError when addGoal throws',
      setUp: () {
        when(() => repo.addGoal(any()))
            .thenAnswer((_) async => throw Exception('Write failed'));
      },
      build: () => GoalBloc(repo),
      act: (bloc) => bloc.add(AddGoal(_goal())),
      expect: () => [isA<GoalError>()],
    );
  });

  group('GoalBloc — ContributeToGoal', () {
    blocTest<GoalBloc, GoalState>(
      'calls repo.contributeToGoal with correct goalId and amount',
      setUp: () {
        when(() => repo.contributeToGoal(any(), any()))
            .thenAnswer((_) async {});
      },
      build: () => GoalBloc(repo),
      act: (bloc) => bloc.add(const ContributeToGoal('goal1', 500.0)),
      expect: () => const <GoalState>[],
      verify: (_) {
        verify(() => repo.contributeToGoal('goal1', 500.0)).called(1);
      },
    );

    blocTest<GoalBloc, GoalState>(
      'emits GoalError when contributeToGoal throws',
      setUp: () {
        when(() => repo.contributeToGoal(any(), any()))
            .thenAnswer((_) async => throw Exception('Transaction failed'));
      },
      build: () => GoalBloc(repo),
      act: (bloc) => bloc.add(const ContributeToGoal('goal1', 200.0)),
      expect: () => [isA<GoalError>()],
    );

    // The clamp-to-remaining and auto-complete logic lives in GoalRepository
    // and is covered by GoalModel.remaining/progress tests.
    // These bloc tests verify the bloc delegates correctly.
    blocTest<GoalBloc, GoalState>(
      'passes overshoot contribution amount to repo without clamping in BLoC',
      setUp: () {
        when(() => repo.contributeToGoal(any(), any()))
            .thenAnswer((_) async {});
      },
      build: () => GoalBloc(repo),
      act: (bloc) =>
          bloc.add(const ContributeToGoal('goal1', 99999.0)),
      expect: () => const <GoalState>[],
      verify: (_) {
        // BLoC passes the raw amount; repo is responsible for clamping.
        verify(() => repo.contributeToGoal('goal1', 99999.0)).called(1);
      },
    );
  });

  group('GoalBloc — MarkGoalComplete', () {
    blocTest<GoalBloc, GoalState>(
      'calls repo.markCompleted with the correct goalId',
      setUp: () {
        when(() => repo.markCompleted(any())).thenAnswer((_) async {});
      },
      build: () => GoalBloc(repo),
      act: (bloc) => bloc.add(const MarkGoalComplete('goal-to-complete')),
      expect: () => const <GoalState>[],
      verify: (_) {
        verify(() => repo.markCompleted('goal-to-complete')).called(1);
      },
    );

    blocTest<GoalBloc, GoalState>(
      'emits GoalError when markCompleted throws',
      setUp: () {
        when(() => repo.markCompleted(any()))
            .thenAnswer((_) async => throw Exception('Completion failed'));
      },
      build: () => GoalBloc(repo),
      act: (bloc) => bloc.add(const MarkGoalComplete('goal1')),
      expect: () => [isA<GoalError>()],
    );
  });

  group('GoalBloc — DeleteGoal', () {
    blocTest<GoalBloc, GoalState>(
      'calls repo.deleteGoal with the correct id',
      setUp: () {
        when(() => repo.deleteGoal(any())).thenAnswer((_) async {});
      },
      build: () => GoalBloc(repo),
      act: (bloc) => bloc.add(const DeleteGoal('goal-to-delete')),
      expect: () => const <GoalState>[],
      verify: (_) {
        verify(() => repo.deleteGoal('goal-to-delete')).called(1);
      },
    );

    blocTest<GoalBloc, GoalState>(
      'emits GoalError when deleteGoal throws',
      setUp: () {
        when(() => repo.deleteGoal(any()))
            .thenAnswer((_) async => throw Exception('Delete failed'));
      },
      build: () => GoalBloc(repo),
      act: (bloc) => bloc.add(const DeleteGoal('bad-id')),
      expect: () => [isA<GoalError>()],
    );
  });
}
