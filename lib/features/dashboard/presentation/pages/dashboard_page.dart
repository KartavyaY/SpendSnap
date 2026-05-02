import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../shared/widgets/spend_ring.dart';
import '../../../../shared/widgets/transaction_tile.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../categories/domain/category_model.dart';
import '../../../categories/presentation/bloc/category_bloc.dart';
import '../../../categories/presentation/bloc/category_state.dart';
import '../../../goals/domain/goal_model.dart';
import '../../../goals/presentation/bloc/goal_bloc.dart';
import '../../../goals/presentation/bloc/goal_event.dart';
import '../../../goals/presentation/bloc/goal_state.dart';
import '../../../insights/presentation/bloc/insight_bloc.dart';
import '../../../insights/presentation/bloc/insight_event.dart';
import '../../../insights/presentation/bloc/insight_state.dart';
import '../../../insights/presentation/widgets/insight_card.dart';
import '../../../transactions/domain/transaction_model.dart';
import '../../../budgets/presentation/bloc/budget_bloc.dart';
import '../../../budgets/presentation/bloc/budget_event.dart';
import '../../../budgets/presentation/bloc/budget_state.dart';
import '../../../transactions/presentation/bloc/transaction_bloc.dart';
import '../../../transactions/presentation/bloc/transaction_state.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    _loadBudgets();
    _triggerInsights();
  }

  void _loadBudgets() {
    context.read<BudgetBloc>().add(const LoadBudgets());
  }

  void _triggerInsights() {
    final txnState = context.read<TransactionBloc>().state;
    final catState = context.read<CategoryBloc>().state;
    if (txnState is TransactionLoaded && catState is CategoryLoaded) {
      context.read<InsightBloc>().add(GenerateInsights(
            transactions: txnState.transactions,
            categories: catState.categories,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'SpendSnap',
          style: AppTypography.headingLarge,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'logout', child: Text('Log out')),
            ],
            onSelected: (v) {
              if (v == 'logout') {
                context.read<AuthBloc>().add(const LogoutRequested());
              }
            },
          ),
        ],
      ),
      body: BlocListener<TransactionBloc, TransactionState>(
        listener: (context, state) {
          if (state is TransactionLoaded) _triggerInsights();
        },
        child: RefreshIndicator(
          onRefresh: () async => _triggerInsights(),
          color: AppColors.orange,
          child: BlocBuilder<TransactionBloc, TransactionState>(
            builder: (context, txnState) {
              if (txnState is TransactionLoading) {
                return const LoadingIndicator();
              }

              final transactions = txnState is TransactionLoaded
                  ? txnState.transactions
                  : <TransactionModel>[];

              return BlocBuilder<CategoryBloc, CategoryState>(
                builder: (context, catState) {
                  final categories = catState is CategoryLoaded
                      ? catState.categories
                      : <CategoryModel>[];

                  final now = DateTime.now();
                  final monthStart = AppDateUtils.startOfMonth(now);
                  final thisMonth =
                      transactions.where((t) => t.date.isAfter(monthStart));

                  final income = thisMonth
                      .where((t) => t.type == TransactionType.income)
                      .fold(0.0, (s, t) => s + t.amount);
                  final expense = thisMonth
                      .where((t) => t.type == TransactionType.expense)
                      .fold(0.0, (s, t) => s + t.amount);

                  // Days left in month
                  final daysInMonth = AppDateUtils.daysInMonth(now);
                  final daysLeft = daysInMonth - now.day;

                  return BlocBuilder<BudgetBloc, BudgetState>(
                    builder: (context, budgetState) {
                      // Use real budget remaining; fall back to income-expense
                      // if no budgets configured yet.
                      final budgetLeft = budgetState is BudgetLoaded &&
                              budgetState.totalBudget > 0
                          ? (budgetState.totalBudget - budgetState.totalSpent)
                              .clamp(0.0, double.infinity)
                          : (income - expense).clamp(0.0, double.infinity);

                  // Month label
                  final monthLabel =
                      '${_monthName(now.month).toUpperCase()}, SO FAR';

                  final recent = transactions.take(5).toList();

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    children: [
                      // Hero ink card
                      _HeroCard(
                        expense: expense,
                        budgetLeft: budgetLeft,
                        daysLeft: daysLeft,
                        monthLabel: monthLabel,
                      ),
                      const SizedBox(height: 24),

                      // Top insight
                      BlocBuilder<InsightBloc, InsightState>(
                        builder: (context, insightState) {
                          if (insightState is InsightLoaded &&
                              insightState.topInsight != null) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Top Insight',
                                    style: AppTypography.headingMedium),
                                const SizedBox(height: 8),
                                InsightCard(
                                    insight: insightState.topInsight!,
                                    compact: false),
                                const SizedBox(height: 24),
                              ],
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),

                      // This week section
                      if (recent.isNotEmpty) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'THIS WEEK',
                              style: AppTypography.eyebrow,
                            ),
                            TextButton(
                              onPressed: () => context.go('/transactions'),
                              child: const Text('See all'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.cream50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.borderHair),
                          ),
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: List.generate(recent.length, (i) {
                              final txn = recent[i];
                              final cat = categories.firstWhere(
                                (c) => c.id == txn.categoryId,
                                orElse: () => categories.isEmpty
                                    ? const CategoryModel(
                                        id: '',
                                        uid: '',
                                        name: 'Unknown',
                                        icon: '📦',
                                        color: '#888780',
                                      )
                                    : categories.first,
                              );
                              final isLast = i == recent.length - 1;
                              return DecoratedBox(
                                decoration: BoxDecoration(
                                  border: isLast
                                      ? null
                                      : const Border(
                                          bottom: BorderSide(
                                            color: AppColors.borderHair,
                                            width: 1,
                                          ),
                                        ),
                                ),
                                child: TransactionTile(
                                  transaction: txn,
                                  category: cat,
                                  onTap: () => context
                                      .go('/transactions/edit/${txn.id}'),
                                ),
                              );
                            }),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Active goals carousel
                      BlocBuilder<GoalBloc, GoalState>(
                        builder: (context, goalState) {
                          if (goalState is GoalLoaded &&
                              goalState.active.isNotEmpty) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Goals',
                                        style: AppTypography.headingMedium),
                                    TextButton(
                                      onPressed: () =>
                                          context.go('/budgets?tab=1'),
                                      child: const Text('See all'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: 140,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: goalState.active.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(width: 12),
                                    itemBuilder: (_, i) => _GoalChip(
                                        goal: goalState.active[i]),
                                  ),
                                ),
                              ],
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  );
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  static String _monthName(int month) {
    const names = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return names[month - 1];
  }
}

class _HeroCard extends StatelessWidget {
  final double expense;
  final double budgetLeft;
  final int daysLeft;
  final String monthLabel;

  const _HeroCard({
    required this.expense,
    required this.budgetLeft,
    required this.daysLeft,
    required this.monthLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Eyebrow
          Text(
            monthLabel,
            style: AppTypography.eyebrow
                .copyWith(color: AppColors.cream300),
          ),
          const SizedBox(height: 10),
          // Big amount
          Text(
            CurrencyFormatter.format(expense),
            style: AppTypography.moneyDisplay(52, color: AppColors.paper),
          ),
          const SizedBox(height: 24),
          const Divider(
            color: Color(0x1FFDFBF7),
            height: 1,
            thickness: 1,
          ),
          const SizedBox(height: 20),
          // Stats row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Budget left',
                      style: AppTypography.caption
                          .copyWith(color: AppColors.cream300),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyFormatter.format(budgetLeft),
                      style: AppTypography.moneyBody
                          .copyWith(color: AppColors.paper),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Days left',
                      style: AppTypography.caption
                          .copyWith(color: AppColors.cream300),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$daysLeft',
                      style: AppTypography.headingLarge
                          .copyWith(color: AppColors.paper),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GoalChip extends StatelessWidget {
  final GoalModel goal;
  const _GoalChip({required this.goal});

  Color get _ringColor {
    final p = goal.progress;
    if (p >= 0.7) return AppColors.success;
    if (p >= 0.3) return AppColors.warn;
    return AppColors.danger;
  }

  void _showContributeSheet(BuildContext context) {
    final ctrl = TextEditingController();
    final remaining = goal.remaining;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => BlocProvider.value(
        value: context.read<GoalBloc>(),
        child: StatefulBuilder(
          builder: (ctx, setSheet) {
            String? errorText;
            void submit() {
              final amount = double.tryParse(ctrl.text.trim());
              if (amount == null || amount <= 0) {
                setSheet(() => errorText = 'Enter a valid amount');
                return;
              }
              context.read<GoalBloc>().add(ContributeToGoal(goal.id, amount));
              Navigator.pop(ctx);
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                  24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Add to ${goal.title}',
                      style: AppTypography.headingMedium),
                  const SizedBox(height: 4),
                  Text(
                    '${CurrencyFormatter.format(remaining)} remaining',
                    style: AppTypography.caption
                        .copyWith(color: AppColors.stone500),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: ctrl,
                    autofocus: true,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onSubmitted: (_) => submit(),
                    onChanged: (_) {
                      if (errorText != null) setSheet(() => errorText = null);
                    },
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      prefixText: '₹ ',
                      errorText: errorText,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: submit,
                      child: const Text('Add'),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: goal.isCompleted ? null : () => _showContributeSheet(context),
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cream50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderHair),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SpendRing(
              progress: goal.progress,
              size: 72,
              strokeWidth: 8,
              centerLabel: '${(goal.progress * 100).round()}%',
              color: _ringColor,
            ),
            const SizedBox(height: 8),
            Text(
              goal.title,
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
