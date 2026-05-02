import 'package:equatable/equatable.dart';
import '../../../categories/domain/category_model.dart';
import '../../../transactions/domain/transaction_model.dart';

abstract class InsightEvent extends Equatable {
  const InsightEvent();
  @override
  List<Object?> get props => [];
}

class GenerateInsights extends InsightEvent {
  final List<TransactionModel> transactions;
  final List<CategoryModel> categories;
  const GenerateInsights({
    required this.transactions,
    required this.categories,
  });
  @override
  List<Object?> get props => [transactions, categories];
}

class DismissInsight extends InsightEvent {
  final String id;
  const DismissInsight(this.id);
  @override
  List<Object?> get props => [id];
}

class RestoreInsight extends InsightEvent {
  final String id;
  const RestoreInsight(this.id);
  @override
  List<Object?> get props => [id];
}
