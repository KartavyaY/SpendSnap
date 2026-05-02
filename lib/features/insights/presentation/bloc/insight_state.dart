import 'package:equatable/equatable.dart';
import '../../domain/insight_model.dart';

abstract class InsightState extends Equatable {
  const InsightState();
  @override
  List<Object?> get props => [];
}

class InsightInitial extends InsightState {
  const InsightInitial();
}

class InsightLoading extends InsightState {
  const InsightLoading();
}

class InsightLoaded extends InsightState {
  final List<Insight> insights;
  final List<Insight> dismissedInsights;

  const InsightLoaded(this.insights,
      {this.dismissedInsights = const []});

  Insight? get topInsight => insights.isNotEmpty ? insights.first : null;

  @override
  List<Object?> get props => [insights, dismissedInsights];
}

class InsightError extends InsightState {
  final String message;
  const InsightError(this.message);
  @override
  List<Object?> get props => [message];
}
