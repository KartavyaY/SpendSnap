import 'package:flutter_test/flutter_test.dart';
import 'package:spendsnap/features/goals/domain/goal_model.dart';

// Factory helper with sensible defaults.
GoalModel _goal({
  String id = 'goal1',
  String uid = 'user1',
  String title = 'Emergency Fund',
  double targetAmount = 10000.0,
  double currentAmount = 0.0,
  DateTime? deadline,
  GoalStatus status = GoalStatus.active,
  DateTime? createdAt,
}) =>
    GoalModel(
      id: id,
      uid: uid,
      title: title,
      targetAmount: targetAmount,
      currentAmount: currentAmount,
      deadline: deadline,
      status: status,
      createdAt: createdAt ?? DateTime(2024, 1, 1),
    );

void main() {
  group('GoalModel — progress getter', () {
    test('returns 0.0 when no amount has been contributed', () {
      final goal = _goal(targetAmount: 10000.0, currentAmount: 0.0);
      expect(goal.progress, closeTo(0.0, 0.001));
    });

    test('returns 0.5 when half the target has been contributed', () {
      final goal = _goal(targetAmount: 10000.0, currentAmount: 5000.0);
      expect(goal.progress, closeTo(0.5, 0.001));
    });

    test('returns 1.0 when target is exactly met', () {
      final goal = _goal(targetAmount: 10000.0, currentAmount: 10000.0);
      expect(goal.progress, closeTo(1.0, 0.001));
    });

    test('clamps to 1.0 when currentAmount exceeds targetAmount', () {
      final goal = _goal(targetAmount: 10000.0, currentAmount: 12000.0);
      expect(goal.progress, closeTo(1.0, 0.001),
          reason: 'Progress should be clamped to 1.0 when over-contributed');
    });

    test('returns 0.0 when targetAmount is zero to prevent division by zero', () {
      final goal = _goal(targetAmount: 0.0, currentAmount: 0.0);
      expect(goal.progress, closeTo(0.0, 0.001));
    });
  });

  group('GoalModel — remaining getter', () {
    test('returns the difference between target and current', () {
      final goal = _goal(targetAmount: 10000.0, currentAmount: 3000.0);
      expect(goal.remaining, closeTo(7000.0, 0.001));
    });

    test('returns 0.0 when target is exactly met', () {
      final goal = _goal(targetAmount: 10000.0, currentAmount: 10000.0);
      expect(goal.remaining, closeTo(0.0, 0.001));
    });

    test('clamps to 0.0 and does not go negative when over-contributed', () {
      final goal = _goal(targetAmount: 10000.0, currentAmount: 15000.0);
      expect(goal.remaining, closeTo(0.0, 0.001),
          reason: 'remaining must never be negative');
    });

    test('returns the full targetAmount when nothing has been contributed', () {
      final goal = _goal(targetAmount: 5000.0, currentAmount: 0.0);
      expect(goal.remaining, closeTo(5000.0, 0.001));
    });
  });

  group('GoalModel — isCompleted getter', () {
    test('returns false for an active goal', () {
      final goal = _goal(status: GoalStatus.active);
      expect(goal.isCompleted, isFalse);
    });

    test('returns true for a completed goal', () {
      final goal = _goal(status: GoalStatus.completed);
      expect(goal.isCompleted, isTrue);
    });

    test('returns false for an abandoned goal', () {
      final goal = _goal(status: GoalStatus.abandoned);
      expect(goal.isCompleted, isFalse);
    });
  });

  group('GoalModel — toFirestore', () {
    test('serialises status as its enum name string', () {
      final map = _goal(status: GoalStatus.active).toFirestore();
      expect(map['status'], 'active');
    });

    test('serialises completed status correctly', () {
      final map = _goal(status: GoalStatus.completed).toFirestore();
      expect(map['status'], 'completed');
    });

    test('serialises all scalar numeric fields', () {
      final map = _goal(
        targetAmount: 25000.0,
        currentAmount: 12500.0,
      ).toFirestore();
      expect(map['targetAmount'], closeTo(25000.0, 0.001));
      expect(map['currentAmount'], closeTo(12500.0, 0.001));
    });

    test('deadline is null when not provided', () {
      final map = _goal(deadline: null).toFirestore();
      expect(map['deadline'], isNull);
    });
  });

  group('GoalModel — toFirestore round-trip (map equality)', () {
    test('goal survives manual map round-trip', () {
      final original = _goal(
        id: 'g-rt',
        uid: 'user1',
        title: 'Vacation',
        targetAmount: 20000.0,
        currentAmount: 8000.0,
        status: GoalStatus.active,
      );

      final map = original.toFirestore();

      final restored = GoalModel(
        id: original.id,
        uid: map['uid'] as String,
        title: map['title'] as String,
        targetAmount: (map['targetAmount'] as num).toDouble(),
        currentAmount: (map['currentAmount'] as num).toDouble(),
        deadline: null, // Timestamp skipped — pure-Dart test
        status: GoalStatus.values.firstWhere(
          (s) => s.name == map['status'],
        ),
        createdAt: original.createdAt,
      );

      expect(restored.title, original.title);
      expect(restored.targetAmount, closeTo(original.targetAmount, 0.001));
      expect(restored.currentAmount, closeTo(original.currentAmount, 0.001));
      expect(restored.status, original.status);
    });
  });

  group('GoalModel — copyWith', () {
    test('updating currentAmount does not mutate the original', () {
      final original = _goal(currentAmount: 1000.0);
      final updated = original.copyWith(currentAmount: 5000.0);
      expect(updated.currentAmount, closeTo(5000.0, 0.001));
      expect(original.currentAmount, closeTo(1000.0, 0.001),
          reason: 'copyWith must not mutate the source instance');
    });

    test('status can be changed to completed via copyWith', () {
      final active = _goal(status: GoalStatus.active);
      final completed = active.copyWith(status: GoalStatus.completed);
      expect(completed.status, GoalStatus.completed);
    });
  });

  group('GoalModel — equatable identity', () {
    test('two instances with identical props are equal', () {
      final createdAt = DateTime(2024, 1, 1);
      final a = _goal(id: 'same', createdAt: createdAt);
      final b = _goal(id: 'same', createdAt: createdAt);
      expect(a, equals(b));
    });

    test('instances with different ids are not equal', () {
      final a = _goal(id: 'g-a');
      final b = _goal(id: 'g-b');
      expect(a, isNot(equals(b)));
    });
  });
}
