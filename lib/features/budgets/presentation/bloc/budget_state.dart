import 'package:equatable/equatable.dart';
import '../../../budgets/domain/budget_model.dart';

abstract class BudgetState extends Equatable {
  const BudgetState();
  @override
  List<Object?> get props => [];
}

class BudgetInitial extends BudgetState {
  const BudgetInitial();
}

class BudgetLoading extends BudgetState {
  const BudgetLoading();
}

class BudgetLoaded extends BudgetState {
  final List<BudgetModel> budgets;
  final double totalBudget;
  final double totalSpent;
  final int daysLeftInMonth;

  const BudgetLoaded({
    required this.budgets,
    required this.totalBudget,
    required this.totalSpent,
    required this.daysLeftInMonth,
  });

  @override
  List<Object?> get props =>
      [budgets, totalBudget, totalSpent, daysLeftInMonth];
}

class BudgetError extends BudgetState {
  final String message;
  const BudgetError(this.message);
  @override
  List<Object?> get props => [message];
}
