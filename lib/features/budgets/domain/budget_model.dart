import 'package:equatable/equatable.dart';
import '../../categories/domain/category_model.dart';

class BudgetModel extends Equatable {
  final CategoryModel category;
  final double spent;
  final double limit;

  const BudgetModel({
    required this.category,
    required this.spent,
    required this.limit,
  });

  double get progress => limit > 0 ? (spent / limit).clamp(0.0, 2.0) : 0.0;
  double get remaining => (limit - spent).clamp(0.0, double.infinity);
  bool get isOverBudget => spent > limit;
  bool get isNearLimit => progress >= 0.7 && !isOverBudget;

  @override
  List<Object?> get props => [category.id, spent, limit];
}
