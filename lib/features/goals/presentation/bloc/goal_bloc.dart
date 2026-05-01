import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/goal_repository.dart';
import '../../domain/goal_model.dart';
import 'goal_event.dart';
import 'goal_state.dart';

// Internal events — not part of public API.
class _GoalsUpdated extends GoalEvent {
  final List<GoalModel> goals;
  const _GoalsUpdated(this.goals);
  @override
  List<Object?> get props => [goals];
}

class _GoalStreamError extends GoalEvent {
  final String message;
  const _GoalStreamError(this.message);
  @override
  List<Object?> get props => [message];
}

class GoalBloc extends Bloc<GoalEvent, GoalState> {
  final GoalRepository _repository;
  StreamSubscription<List<GoalModel>>? _sub;

  GoalBloc(this._repository) : super(const GoalInitial()) {
    on<LoadGoals>(_onLoad);
    on<_GoalsUpdated>((e, emit) => emit(GoalLoaded(e.goals)));
    on<_GoalStreamError>((e, emit) => emit(GoalError(e.message)));
    on<AddGoal>(_onAdd);
    on<UpdateGoal>(_onUpdate);
    on<ContributeToGoal>(_onContribute);
    on<MarkGoalComplete>(_onComplete);
    on<DeleteGoal>(_onDelete);
  }

  // Sets up a persistent Firestore listener via a manual StreamSubscription.
  // Avoids emit.forEach which blocks the event queue for the lifetime of the
  // stream — causing mutation events (AddGoal etc.) to be silently queued
  // forever (Firestore stream never closes, so emit.forEach never returns).
  void _onLoad(LoadGoals event, Emitter<GoalState> emit) {
    _sub?.cancel();
    emit(const GoalLoading());
    _sub = _repository.watchGoals().listen(
      (goals) => add(_GoalsUpdated(goals)),
      onError: (Object err, _) => add(_GoalStreamError(err.toString())),
    );
  }

  Future<void> _onAdd(AddGoal event, Emitter<GoalState> emit) async {
    try {
      await _repository.addGoal(event.goal);
    } catch (e) {
      emit(GoalError(e.toString()));
    }
  }

  Future<void> _onUpdate(UpdateGoal event, Emitter<GoalState> emit) async {
    try {
      await _repository.updateGoal(event.goal);
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

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
