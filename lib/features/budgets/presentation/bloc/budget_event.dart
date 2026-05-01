import 'package:equatable/equatable.dart';

abstract class BudgetEvent extends Equatable {
  const BudgetEvent();
  @override
  List<Object?> get props => [];
}

class LoadBudgets extends BudgetEvent {
  const LoadBudgets();
}

class SetBudgetLimit extends BudgetEvent {
  final String categoryId;
  final double? limit; // null = remove limit
  const SetBudgetLimit(this.categoryId, this.limit);
  @override
  List<Object?> get props => [categoryId, limit];
}
