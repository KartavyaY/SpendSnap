import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/insight_engine.dart';
import 'insight_event.dart';
import 'insight_state.dart';

class InsightBloc extends Bloc<InsightEvent, InsightState> {
  final InsightEngine _engine;

  InsightBloc(this._engine) : super(const InsightInitial()) {
    on<GenerateInsights>(_onGenerate);
  }

  Future<void> _onGenerate(
    GenerateInsights event,
    Emitter<InsightState> emit,
  ) async {
    emit(const InsightLoading());
    try {
      final insights = _engine.generate(
        transactions: event.transactions,
        categories: event.categories,
        now: DateTime.now(),
      );
      emit(InsightLoaded(insights));
    } catch (e) {
      emit(InsightError(e.toString()));
    }
  }
}
