import 'package:equatable/equatable.dart';
import '../../domain/goal_model.dart';

abstract class GoalState extends Equatable {
  const GoalState();
  @override
  List<Object?> get props => [];
}

class GoalInitial extends GoalState {
  const GoalInitial();
}

class GoalLoading extends GoalState {
  const GoalLoading();
}

class GoalLoaded extends GoalState {
  final List<GoalModel> goals;
  const GoalLoaded(this.goals);

  List<GoalModel> get active =>
      goals.where((g) => g.status == GoalStatus.active).toList();
  List<GoalModel> get completed =>
      goals.where((g) => g.status == GoalStatus.completed).toList();

  @override
  List<Object?> get props => [goals];
}

class GoalError extends GoalState {
  final String message;
  const GoalError(this.message);
  @override
  List<Object?> get props => [message];
}
