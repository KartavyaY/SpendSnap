import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/insight_engine.dart';
import '../../domain/insight_model.dart';
import 'insight_event.dart';
import 'insight_state.dart';

class InsightBloc extends Bloc<InsightEvent, InsightState> {
  final InsightEngine _engine;
  final List<Insight> _dismissed = [];

  InsightBloc(this._engine) : super(const InsightInitial()) {
    on<GenerateInsights>(_onGenerate);
    on<DismissInsight>(_onDismiss);
    on<RestoreInsight>(_onRestore);
  }

  Set<String> get _dismissedIds => _dismissed.map((i) => i.id).toSet();

  Future<void> _onGenerate(
    GenerateInsights event,
    Emitter<InsightState> emit,
  ) async {
    emit(const InsightLoading());
    try {
      final all = _engine.generate(
        transactions: event.transactions,
        categories: event.categories,
        now: DateTime.now(),
      );
      final ids = _dismissedIds;
      final active = all.where((i) => !ids.contains(i.id)).toList();
      emit(InsightLoaded(active, dismissedInsights: List.unmodifiable(_dismissed)));
    } catch (e) {
      emit(InsightError(e.toString()));
    }
  }

  void _onDismiss(DismissInsight event, Emitter<InsightState> emit) {
    final current = state;
    if (current is InsightLoaded) {
      final insight = current.insights.where((i) => i.id == event.id).firstOrNull;
      if (insight != null) _dismissed.add(insight);
      final active = current.insights.where((i) => i.id != event.id).toList();
      emit(InsightLoaded(active, dismissedInsights: List.unmodifiable(_dismissed)));
    }
  }

  void _onRestore(RestoreInsight event, Emitter<InsightState> emit) {
    final current = state;
    if (current is InsightLoaded) {
      final insight = _dismissed.where((i) => i.id == event.id).firstOrNull;
      _dismissed.removeWhere((i) => i.id == event.id);
      final active = [
        ...current.insights,
        if (insight != null) insight,
      ]..sort((a, b) => b.severity.index.compareTo(a.severity.index));
      emit(InsightLoaded(active, dismissedInsights: List.unmodifiable(_dismissed)));
    }
  }
}
