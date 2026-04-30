import 'package:equatable/equatable.dart';
import '../../domain/goal_model.dart';

abstract class GoalEvent extends Equatable {
  const GoalEvent();
  @override
  List<Object?> get props => [];
}

class LoadGoals extends GoalEvent {
  const LoadGoals();
}

class AddGoal extends GoalEvent {
  final GoalModel goal;
  const AddGoal(this.goal);
  @override
  List<Object?> get props => [goal];
}

class ContributeToGoal extends GoalEvent {
  final String goalId;
  final double amount;
  const ContributeToGoal(this.goalId, this.amount);
  @override
  List<Object?> get props => [goalId, amount];
}

class MarkGoalComplete extends GoalEvent {
  final String goalId;
  const MarkGoalComplete(this.goalId);
  @override
  List<Object?> get props => [goalId];
}

class DeleteGoal extends GoalEvent {
  final String id;
  const DeleteGoal(this.id);
  @override
  List<Object?> get props => [id];
}
