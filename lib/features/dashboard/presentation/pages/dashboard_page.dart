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
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../categories/domain/category_model.dart';
import '../../../categories/presentation/bloc/category_bloc.dart';
import '../../../categories/presentation/bloc/category_state.dart';
import '../../../goals/domain/goal_model.dart';
import '../../../goals/presentation/bloc/goal_bloc.dart';
import '../../../goals/presentation/bloc/goal_state.dart';
import '../../../insights/presentation/bloc/insight_bloc.dart';
import '../../../insights/presentation/bloc/insight_event.dart';
import '../../../insights/presentation/bloc/insight_state.dart';
import '../../../insights/presentation/widgets/insight_card.dart';
import '../../../transactions/domain/transaction_model.dart';
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
    _triggerInsights();
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
    final authState = context.read<AuthBloc>().state;
    final name = authState is Authenticated
        ? authState.user.displayName.split(' ').first
        : '';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, $name 👋',
              style: AppTypography.headingMedium,
            ),
            Text(
              AppDateUtils.formatMonth(DateTime.now()),
              style: AppTypography.caption
                  .copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
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
          color: AppColors.primary,
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
                  final thisMonth = transactions.where(
                      (t) => t.date.isAfter(monthStart));

                  final income = thisMonth
                      .where((t) => t.type == TransactionType.income)
                      .fold(0.0, (s, t) => s + t.amount);
                  final expense = thisMonth
                      .where((t) => t.type == TransactionType.expense)
                      .fold(0.0, (s, t) => s + t.amount);
                  final net = income - expense;

                  final recent = transactions.take(5).toList();

                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Balance card
                      _BalanceCard(
                          income: income, expense: expense, net: net),
                      const SizedBox(height: 16),

                      // Top insight
                      BlocBuilder<InsightBloc, InsightState>(
                        builder: (context, insightState) {
                          if (insightState is InsightLoaded &&
                              insightState.topInsight != null) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Top Insight',
                                        style: AppTypography.headingMedium),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                InsightCard(
                                    insight: insightState.topInsight!,
                                    compact: false),
                                const SizedBox(height: 16),
                              ],
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),

                      // Recent transactions
                      if (recent.isNotEmpty) ...[
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Recent',
                                style: AppTypography.headingMedium),
                            TextButton(
                              onPressed: () =>
                                  context.go('/transactions'),
                              child: const Text('See all'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border:
                                Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            children: recent.map((txn) {
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
                              return TransactionTile(
                                transaction: txn,
                                category: cat,
                                dense: true,
                                onTap: () => context.go(
                                    '/transactions/edit/${txn.id}'),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Active goals carousel
                      BlocBuilder<GoalBloc, GoalState>(
                        builder: (context, goalState) {
                          if (goalState is GoalLoaded &&
                              goalState.active.isNotEmpty) {
                            return Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Goals',
                                        style:
                                            AppTypography.headingMedium),
                                    TextButton(
                                      onPressed: () =>
                                          context.go('/goals'),
                                      child: const Text('See all'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: 120,
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
          ),
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final double income;
  final double expense;
  final double net;

  const _BalanceCard(
      {required this.income, required this.expense, required this.net});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Net Balance',
            style: AppTypography.label.copyWith(
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 4),
          _AnimatedAmount(amount: net),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _BalanceStat(
                  label: 'Income',
                  amount: income,
                  icon: Icons.arrow_upward,
                  color: Colors.white,
                ),
              ),
              Container(width: 1, height: 40, color: Colors.white24),
              Expanded(
                child: _BalanceStat(
                  label: 'Expense',
                  amount: expense,
                  icon: Icons.arrow_downward,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnimatedAmount extends StatefulWidget {
  final double amount;
  const _AnimatedAmount({required this.amount});

  @override
  State<_AnimatedAmount> createState() => _AnimatedAmountState();
}

class _AnimatedAmountState extends State<_AnimatedAmount> {
  double _oldAmount = 0;

  @override
  void didUpdateWidget(_AnimatedAmount oldWidget) {
    super.didUpdateWidget(oldWidget);
    _oldAmount = oldWidget.amount;
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: _oldAmount, end: widget.amount),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (_, value, __) => Text(
        CurrencyFormatter.format(value),
        style: AppTypography.displayLarge.copyWith(
          color: Colors.white,
          fontSize: 28,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _BalanceStat extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;
  final Color color;

  const _BalanceStat({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTypography.caption
                        .copyWith(color: Colors.white70)),
                Text(
                  CurrencyFormatter.formatCompact(amount),
                  style: AppTypography.label.copyWith(color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalChip extends StatelessWidget {
  final GoalModel goal;
  const _GoalChip({required this.goal});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SpendRing(
            progress: goal.progress,
            size: 52,
            strokeWidth: 5,
            centerLabel: '${(goal.progress * 100).round()}%',
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
    );
  }
}
