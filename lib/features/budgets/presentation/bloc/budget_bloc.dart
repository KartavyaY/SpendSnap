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
    on<SetBudgetLimit>(_onSetLimit);
  }

  Future<void> _onLoad(LoadBudgets event, Emitter<BudgetState> emit) async {
    emit(const BudgetLoading());
    await _fetchAndEmit(emit);
  }

  Future<void> _onSetLimit(
    SetBudgetLimit event,
    Emitter<BudgetState> emit,
  ) async {
    try {
      await _categoryRepo.updateBudgetLimit(event.categoryId, event.limit);
      await _fetchAndEmit(emit);
    } catch (e) {
      emit(BudgetError(e.toString()));
    }
  }

  Future<void> _fetchAndEmit(Emitter<BudgetState> emit) async {
    try {
      final now = DateTime.now();
      final categories = await _categoryRepo.fetchCategories();
      final transactions = await _transactionRepo.fetchTransactions(
        from: AppDateUtils.startOfMonth(now),
        to: AppDateUtils.endOfMonth(now),
      );

      final budgets = _buildBudgets(categories, transactions);
      emit(BudgetLoaded(
        budgets: budgets,
        totalBudget: budgets.fold(0.0, (s, b) => s + b.limit),
        totalSpent: budgets.fold(0.0, (s, b) => s + b.spent),
        daysLeftInMonth: AppDateUtils.daysInMonth(now) - now.day,
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
      result.add(BudgetModel(category: cat, spent: spent, limit: limit));
    }
    return result;
  }
}
