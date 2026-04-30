import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../shared/widgets/spend_ring.dart';
import '../../../budgets/domain/budget_model.dart';
import '../bloc/budget_bloc.dart';
import '../bloc/budget_event.dart';
import '../bloc/budget_state.dart';

class BudgetPage extends StatefulWidget {
  const BudgetPage({super.key});

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  @override
  void initState() {
    super.initState();
    context.read<BudgetBloc>().add(const LoadBudgets());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Budgets')),
      body: BlocBuilder<BudgetBloc, BudgetState>(
        builder: (context, state) {
          if (state is BudgetLoading) return const LoadingIndicator();

          if (state is BudgetError) {
            return EmptyState(
              title: 'Error loading budgets',
              description: state.message,
              icon: Icons.error_outline,
            );
          }

          if (state is BudgetLoaded) {
            if (state.budgets.isEmpty) {
              return const EmptyState(
                title: 'No budgets set',
                description:
                    'Set monthly limits on categories to track your budget.',
                icon: Icons.account_balance_wallet_outlined,
              );
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Overall summary card
                _OverallBudgetCard(state: state),
                const SizedBox(height: 16),

                // Days left
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 14, color: AppColors.textTertiary),
                    const SizedBox(width: 4),
                    Text(
                      '${state.daysLeftInMonth} days left this month',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Text('By Category', style: AppTypography.headingMedium),
                const SizedBox(height: 12),

                ...state.budgets.map((b) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _BudgetCard(budget: b),
                    )),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _OverallBudgetCard extends StatelessWidget {
  final BudgetLoaded state;
  const _OverallBudgetCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final progress = state.totalBudget > 0
        ? (state.totalSpent / state.totalBudget).clamp(0.0, 1.0)
        : 0.0;
    final color = progress >= 1.0
        ? AppColors.danger
        : progress >= 0.7
            ? AppColors.warning
            : AppColors.success;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          SpendRing(
            progress: progress,
            size: 80,
            color: color,
            centerLabel: '${(progress * 100).round()}%',
            centerSubLabel: 'used',
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Overall Budget',
                    style: AppTypography.label.copyWith(
                      color: AppColors.textSecondary,
                    )),
                const SizedBox(height: 4),
                Text(
                  CurrencyFormatter.format(state.totalSpent),
                  style: AppTypography.headingLarge,
                ),
                Text(
                  'of ${CurrencyFormatter.format(state.totalBudget)}',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${CurrencyFormatter.format(
                    (state.totalBudget - state.totalSpent)
                        .clamp(0, double.infinity),
                  )} remaining',
                  style: AppTypography.caption.copyWith(color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  final BudgetModel budget;
  const _BudgetCard({required this.budget});

  Color get _progressColor {
    if (budget.isOverBudget) return AppColors.danger;
    if (budget.isNearLimit) return AppColors.warning;
    return AppColors.success;
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(budget.category.color);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(budget.category.icon,
                      style: const TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(budget.category.name,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w500,
                        )),
                    Text(
                      '${CurrencyFormatter.format(budget.spent)} / ${CurrencyFormatter.format(budget.limit)}',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                budget.isOverBudget ? 'Over!' : '${(budget.progress * 100).round()}%',
                style: AppTypography.label.copyWith(
                  color: _progressColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: budget.progress.clamp(0.0, 1.0),
              backgroundColor: _progressColor.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(_progressColor),
              minHeight: 8,
            ),
          ),
          if (budget.isOverBudget) ...[
            const SizedBox(height: 6),
            Text(
              'Over by ${CurrencyFormatter.format(budget.spent - budget.limit)}',
              style: AppTypography.caption.copyWith(color: AppColors.danger),
            ),
          ],
        ],
      ),
    );
  }
}
