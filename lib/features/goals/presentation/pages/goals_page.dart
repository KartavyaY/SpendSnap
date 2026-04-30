import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../shared/widgets/spend_ring.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../domain/goal_model.dart';
import '../bloc/goal_bloc.dart';
import '../bloc/goal_event.dart';
import '../bloc/goal_state.dart';

class GoalsPage extends StatelessWidget {
  const GoalsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Savings Goals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddGoalSheet(context),
          ),
        ],
      ),
      body: BlocBuilder<GoalBloc, GoalState>(
        builder: (context, state) {
          if (state is GoalLoading) return const LoadingIndicator();

          if (state is GoalError) {
            return EmptyState(
              title: 'Create a Savings Plan',
              description: 'Set a goal, track your progress, and reach it faster.',
              icon: Icons.savings_outlined,
              actionLabel: 'Create Savings Plan',
              onAction: () => _showAddGoalSheet(context),
            );
          }

          if (state is GoalLoaded) {
            if (state.goals.isEmpty) {
              return EmptyState(
                title: 'Create a Savings Plan',
                description:
                    'Set a goal, track your progress, and reach it faster.',
                icon: Icons.savings_outlined,
                actionLabel: 'Create Savings Plan',
                onAction: () => _showAddGoalSheet(context),
              );
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (state.active.isNotEmpty) ...[
                  const Text('Active', style: AppTypography.headingMedium),
                  const SizedBox(height: 12),
                  ...state.active.map((g) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _GoalCard(goal: g),
                      )),
                ],
                if (state.completed.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text('Achieved 🎉', style: AppTypography.headingMedium),
                  const SizedBox(height: 12),
                  ...state.completed.map((g) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _GoalCard(goal: g),
                      )),
                ],
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  void _showAddGoalSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: context.read<GoalBloc>(),
        child: BlocProvider.value(
          value: context.read<AuthBloc>(),
          child: const _AddGoalSheet(),
        ),
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final GoalModel goal;
  const _GoalCard({required this.goal});

  Color get _ringColor {
    if (goal.isCompleted) return AppColors.success;
    if (goal.progress >= 0.75) return AppColors.primaryLight;
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          SpendRing(
            progress: goal.progress,
            size: 72,
            color: _ringColor,
            centerLabel: '${(goal.progress * 100).round()}%',
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  goal.title,
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${CurrencyFormatter.format(goal.currentAmount)} / ${CurrencyFormatter.format(goal.targetAmount)}',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (goal.deadline != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'By ${AppDateUtils.formatDay(goal.deadline!)}',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
                if (!goal.isCompleted) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${CurrencyFormatter.format(goal.remaining)} to go',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.primaryLight,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!goal.isCompleted)
            PopupMenuButton(
              itemBuilder: (_) => [
                const PopupMenuItem(
                    value: 'contribute', child: Text('Add contribution')),
                const PopupMenuItem(
                    value: 'complete', child: Text('Mark complete')),
                const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete',
                        style: TextStyle(color: AppColors.danger))),
              ],
              onSelected: (v) {
                switch (v) {
                  case 'contribute':
                    _showContributeSheet(context, goal);
                  case 'complete':
                    context
                        .read<GoalBloc>()
                        .add(MarkGoalComplete(goal.id));
                  case 'delete':
                    context.read<GoalBloc>().add(DeleteGoal(goal.id));
                }
              },
            ),
        ],
      ),
    );
  }

  void _showContributeSheet(BuildContext context, GoalModel goal) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => BlocProvider.value(
        value: context.read<GoalBloc>(),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add contribution to ${goal.title}',
                  style: AppTypography.headingMedium),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: '₹ ',
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final amount = double.tryParse(ctrl.text.trim());
                    if (amount != null && amount > 0) {
                      context
                          .read<GoalBloc>()
                          .add(ContributeToGoal(goal.id, amount));
                      Navigator.pop(ctx);
                    }
                  },
                  child: const Text('Add'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddGoalSheet extends StatefulWidget {
  const _AddGoalSheet();

  @override
  State<_AddGoalSheet> createState() => _AddGoalSheetState();
}

class _AddGoalSheetState extends State<_AddGoalSheet> {
  final _titleCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  DateTime? _deadline;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _targetCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (_titleCtrl.text.trim().isEmpty) return;
    final target = double.tryParse(_targetCtrl.text.trim());
    if (target == null || target <= 0) return;

    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) return;

    final goal = GoalModel(
      id: const Uuid().v4(),
      uid: authState.user.uid,
      title: _titleCtrl.text.trim(),
      targetAmount: target,
      currentAmount: 0,
      deadline: _deadline,
      status: GoalStatus.active,
      createdAt: DateTime.now(),
    );

    context.read<GoalBloc>().add(AddGoal(goal));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('New Goal', style: AppTypography.headingMedium),
          const SizedBox(height: 16),
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(labelText: 'Goal title'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _targetCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Target amount',
              prefixText: '₹ ',
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now().add(const Duration(days: 30)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 3650)),
              );
              if (picked != null) setState(() => _deadline = picked);
            },
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Deadline (optional)',
                prefixIcon: Icon(Icons.calendar_today_outlined),
              ),
              child: Text(
                _deadline != null
                    ? AppDateUtils.formatDay(_deadline!)
                    : 'No deadline',
                style: AppTypography.bodyMedium.copyWith(
                  color: _deadline != null
                      ? AppColors.textPrimary
                      : AppColors.textTertiary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _save,
              child: const Text('Create Goal'),
            ),
          ),
        ],
      ),
    );
  }
}
