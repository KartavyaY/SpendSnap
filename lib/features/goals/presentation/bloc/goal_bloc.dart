import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/goal_repository.dart';
import '../../domain/goal_model.dart';
import 'goal_event.dart';
import 'goal_state.dart';

class GoalBloc extends Bloc<GoalEvent, GoalState> {
  final GoalRepository _repository;

  GoalBloc(this._repository) : super(const GoalInitial()) {
    on<LoadGoals>(_onLoad);
    on<AddGoal>(_onAdd);
    on<ContributeToGoal>(_onContribute);
    on<MarkGoalComplete>(_onComplete);
    on<DeleteGoal>(_onDelete);
  }

  Future<void> _onLoad(LoadGoals event, Emitter<GoalState> emit) async {
    emit(const GoalLoading());
    await emit.forEach<List<GoalModel>>(
      _repository.watchGoals(),
      onData: GoalLoaded.new,
      onError: (err, _) => GoalError(err.toString()),
    );
  }

  Future<void> _onAdd(AddGoal event, Emitter<GoalState> emit) async {
    try {
      await _repository.addGoal(event.goal);
    } catch (e) {
      emit(GoalError(e.toString()));
    }
  }

  Future<void> _onContribute(
    ContributeToGoal event,
    Emitter<GoalState> emit,
  ) async {
    try {
      await _repository.contributeToGoal(event.goalId, event.amount);
    } catch (e) {
      emit(GoalError(e.toString()));
    }
  }

  Future<void> _onComplete(
    MarkGoalComplete event,
    Emitter<GoalState> emit,
  ) async {
    try {
      await _repository.markCompleted(event.goalId);
    } catch (e) {
      emit(GoalError(e.toString()));
    }
  }

  Future<void> _onDelete(DeleteGoal event, Emitter<GoalState> emit) async {
    try {
      await _repository.deleteGoal(event.id);
    } catch (e) {
      emit(GoalError(e.toString()));
    }
  }
}
