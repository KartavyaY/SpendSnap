import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../budgets/domain/budget_model.dart';
import '../../../categories/data/category_repository.dart';
import '../../../categories/domain/category_model.dart';
import '../../../transactions/data/transaction_repository.dart';
import '../../../transactions/domain/transaction_model.dart';
import '../../../../core/utils/date_utils.dart';
import 'budget_event.dart';
import 'budget_state.dart';

class BudgetBloc extends Bloc<BudgetEvent, BudgetState> {
  final CategoryRepository _categoryRepo;
  final TransactionRepository _transactionRepo;

  BudgetBloc(this._categoryRepo, this._transactionRepo)
      : super(const BudgetInitial()) {
    on<LoadBudgets>(_onLoad);
  }

  Future<void> _onLoad(LoadBudgets event, Emitter<BudgetState> emit) async {
    emit(const BudgetLoading());
    try {
      final now = DateTime.now();
      final monthStart = AppDateUtils.startOfMonth(now);
      final monthEnd = AppDateUtils.endOfMonth(now);

      final categories = await _categoryRepo.fetchCategories();
      final transactions = await _transactionRepo.fetchTransactions(
        from: monthStart,
        to: monthEnd,
      );

      final budgets = _buildBudgets(categories, transactions);
      final totalBudget =
          budgets.fold(0.0, (sum, b) => sum + b.limit);
      final totalSpent = budgets.fold(0.0, (sum, b) => sum + b.spent);
      final daysLeft = AppDateUtils.daysInMonth(now) - now.day;

      emit(BudgetLoaded(
        budgets: budgets,
        totalBudget: totalBudget,
        totalSpent: totalSpent,
        daysLeftInMonth: daysLeft,
      ));
    } catch (e) {
      emit(BudgetError(e.toString()));
    }
  }

  List<BudgetModel> _buildBudgets(
    List<CategoryModel> categories,
    List<TransactionModel> transactions,
  ) {
    final result = <BudgetModel>[];
    for (final cat in categories) {
      final limit = cat.monthlyLimit;
      if (limit == null || limit <= 0) continue;

      final spent = transactions
          .where((t) =>
              t.categoryId == cat.id && t.type == TransactionType.expense)
          .fold(0.0, (sum, t) => sum + t.amount);

      result.add(BudgetModel(
        category: cat,
        spent: spent,
        limit: limit,
      ));
    }
    return result;
  }
}
