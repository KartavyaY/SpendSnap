import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/category_icon.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../shared/widgets/spend_ring.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../categories/domain/category_model.dart';
import '../../../categories/presentation/bloc/category_bloc.dart';
import '../../../categories/presentation/bloc/category_state.dart';
import '../../../goals/domain/goal_model.dart';
import '../../../goals/presentation/bloc/goal_bloc.dart';
import '../../../goals/presentation/bloc/goal_event.dart';
import '../../../goals/presentation/bloc/goal_state.dart';
import '../../domain/budget_model.dart';
import '../bloc/budget_bloc.dart';
import '../bloc/budget_event.dart';
import '../bloc/budget_state.dart';

class PlanPage extends StatefulWidget {
  final int initialTab;
  const PlanPage({super.key, this.initialTab = 0});

  @override
  State<PlanPage> createState() => _PlanPageState();
}

class _PlanPageState extends State<PlanPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this,
        initialIndex: widget.initialTab.clamp(0, 1));
    context.read<BudgetBloc>().add(const LoadBudgets());
    _tab.addListener(() {
      if (!_tab.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan'),
        actions: [
          Builder(
            builder: (innerCtx) => IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _tab.index == 0
                  ? _showSetBudgetSheet(innerCtx)
                  : _showGoalSheet(innerCtx),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          labelColor: AppColors.orange,
          unselectedLabelColor: AppColors.stone500,
          indicatorColor: AppColors.orange,
          indicatorSize: TabBarIndicatorSize.label,
          indicatorWeight: 2,
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.1,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          tabs: const [
            Tab(text: 'Budgets'),
            Tab(text: 'Savings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [
          _BudgetsTab(),
          _SavingsTab(),
        ],
      ),
    );
  }
}

// ── Sheet helpers (file-level, any context inside Scaffold works) ──

void _showSetBudgetSheet(
  BuildContext context, {
  CategoryModel? initial,
}) {
  final catState = context.read<CategoryBloc>().state;
  final categories =
      catState is CategoryLoaded ? catState.categories : <CategoryModel>[];

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.paper,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => MultiBlocProvider(
      providers: [
        BlocProvider.value(value: context.read<BudgetBloc>()),
      ],
      child: _SetBudgetSheet(categories: categories, initial: initial),
    ),
  );
}

void _showGoalSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.paper,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => BlocProvider.value(
      value: context.read<GoalBloc>(),
      child: BlocProvider.value(
        value: context.read<AuthBloc>(),
        child: const _AddGoalSheet(),
      ),
    ),
  );
}

// ── Budgets Tab ────────────────────────────────────────────

class _BudgetsTab extends StatelessWidget {
  const _BudgetsTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BudgetBloc, BudgetState>(
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
            return EmptyState(
              title: 'No budgets set',
              description:
                  'Set monthly limits on categories to track your spending.',
              icon: Icons.account_balance_wallet_outlined,
              actionLabel: 'Set a Budget',
              onAction: () => _showSetBudgetSheet(context),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _OverallBudgetCard(state: state),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 14, color: AppColors.stone500),
                  const SizedBox(width: 4),
                  Text(
                    '${state.daysLeftInMonth} days left this month',
                    style: AppTypography.caption
                        .copyWith(color: AppColors.stone500),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('By Category', style: AppTypography.headingMedium),
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
    );
  }
}

// ── Savings Tab ────────────────────────────────────────────

class _SavingsTab extends StatelessWidget {
  const _SavingsTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GoalBloc, GoalState>(
      builder: (context, state) {
        if (state is GoalLoading) return const LoadingIndicator();

        if (state is GoalLoaded && state.goals.isNotEmpty) {
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
                const Text('Achieved 🎉',
                    style: AppTypography.headingMedium),
                const SizedBox(height: 12),
                ...state.completed.map((g) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _GoalCard(goal: g),
                    )),
              ],
            ],
          );
        }

        // Use BlocBuilder's own context — guaranteed inside Scaffold.
        return EmptyState(
          title: 'Create a Savings Plan',
          description:
              'Set a goal, track your progress, and reach it faster.',
          icon: Icons.savings_outlined,
          actionLabel: 'Create Savings Plan',
          onAction: () => _showGoalSheet(context),
        );
      },
    );
  }
}

// ── Budget widgets ──────────────────────────────────────────

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
            ? AppColors.warn
            : AppColors.success;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cream50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderHair),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${CurrencyFormatter.format(state.totalSpent)} of '
            '${CurrencyFormatter.format(state.totalBudget)} spent',
            style: AppTypography.displayM,
          ),
          const SizedBox(height: 16),
          Row(
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
                    Text(
                      'Overall Budget',
                      style: AppTypography.label
                          .copyWith(color: AppColors.stone600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${CurrencyFormatter.format((state.totalBudget - state.totalSpent).clamp(0, double.infinity))} remaining',
                      style: AppTypography.caption.copyWith(color: color),
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

class _BudgetCard extends StatelessWidget {
  final BudgetModel budget;
  const _BudgetCard({required this.budget});

  Color get _progressColor {
    if (budget.isOverBudget) return AppColors.danger;
    if (budget.isNearLimit) return AppColors.warn;
    return AppColors.stone600;
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return AppColors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = _parseColor(budget.category.color);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cream50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderHair),
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
                  color: categoryColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  CategoryIcon.resolve(budget.category.icon),
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      budget.category.name,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w500,
                        color: AppColors.ink,
                      ),
                    ),
                    Text(
                      '${CurrencyFormatter.format(budget.spent)} / '
                      '${CurrencyFormatter.format(budget.limit)}',
                      style: AppTypography.caption
                          .copyWith(color: AppColors.stone600),
                    ),
                  ],
                ),
              ),
              Text(
                budget.isOverBudget
                    ? 'Over!'
                    : '${(budget.progress * 100).round()}%',
                style: AppTypography.label.copyWith(
                  color: _progressColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert,
                    size: 18, color: AppColors.stone500),
                constraints: const BoxConstraints(minWidth: 0),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit limit')),
                  PopupMenuItem(
                    value: 'remove',
                    child: Text('Remove limit',
                        style: TextStyle(color: AppColors.danger)),
                  ),
                ],
                onSelected: (v) {
                  if (v == 'edit') {
                    _showSetBudgetSheet(context, initial: budget.category);
                  } else {
                    context
                        .read<BudgetBloc>()
                        .add(SetBudgetLimit(budget.category.id, null));
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: budget.progress.clamp(0.0, 1.0),
              backgroundColor: AppColors.cream300,
              valueColor: AlwaysStoppedAnimation(categoryColor),
              minHeight: 8,
            ),
          ),
          if (budget.isOverBudget) ...[
            const SizedBox(height: 6),
            Text(
              'Over by ${CurrencyFormatter.format(budget.spent - budget.limit)}',
              style: AppTypography.caption.copyWith(color: AppColors.danger),
            ),
          ] else if (budget.isNearLimit) ...[
            const SizedBox(height: 6),
            Text(
              'Approaching limit',
              style: AppTypography.caption.copyWith(color: AppColors.warn),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Goal widgets ───────────────────────────────────────────

class _GoalCard extends StatelessWidget {
  final GoalModel goal;
  const _GoalCard({required this.goal});

  Color get _ringColor {
    final p = goal.progress.clamp(0.0, 1.0);
    if (p <= 0.5) {
      return Color.lerp(AppColors.danger, AppColors.warn, p * 2)!;
    } else {
      return Color.lerp(AppColors.warn, AppColors.success, (p - 0.5) * 2)!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: goal.isCompleted
            ? null
            : () => _showContributeSheet(context, goal),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
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
                      style: AppTypography.bodyLarge
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${CurrencyFormatter.format(goal.currentAmount)} / '
                      '${CurrencyFormatter.format(goal.targetAmount)}',
                      style: AppTypography.bodyMedium
                          .copyWith(color: AppColors.textSecondary),
                    ),
                    if (goal.deadline != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'By ${AppDateUtils.formatDay(goal.deadline!)}',
                        style: AppTypography.caption
                            .copyWith(color: AppColors.textTertiary),
                      ),
                    ],
                    if (!goal.isCompleted) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${CurrencyFormatter.format(goal.remaining)} to go',
                        style: AppTypography.caption
                            .copyWith(color: AppColors.primaryLight),
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<String>(
                constraints: const BoxConstraints(minWidth: 0),
                itemBuilder: (_) => [
                  if (!goal.isCompleted) ...[
                    const PopupMenuItem(
                      value: 'complete', child: Text('Mark Complete')),
                    const PopupMenuItem(
                        value: 'edit', child: Text('Edit')),
                  ],
                  const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete',
                          style: TextStyle(color: AppColors.danger))),
                ],
                onSelected: (v) {
                  switch (v) {
                    case 'contribute':
                      _showContributeSheet(context, goal);
                    case 'edit':
                      _showEditGoalSheet(context, goal);
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
        ),
      ),
    );
  }

  void _showContributeSheet(BuildContext context, GoalModel goal) {
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
          builder: (ctx, setSheetState) {
            String? errorText;

            void submit() {
              final amount = double.tryParse(ctrl.text.trim());
              if (amount == null || amount <= 0) {
                setSheetState(() => errorText = 'Enter a valid amount');
                return;
              }
              // amount > remaining is fine — repository clamps to remaining
              // and auto-marks the goal complete.
              context
                  .read<GoalBloc>()
                  .add(ContributeToGoal(goal.id, amount));
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
                      if (errorText != null) {
                        setSheetState(() => errorText = null);
                      }
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
}

// ── Edit Goal Sheet ────────────────────────────────────────

void _showEditGoalSheet(BuildContext context, GoalModel goal) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.paper,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => BlocProvider.value(
      value: context.read<GoalBloc>(),
      child: _EditGoalSheet(goal: goal),
    ),
  );
}

class _EditGoalSheet extends StatefulWidget {
  final GoalModel goal;
  const _EditGoalSheet({required this.goal});

  @override
  State<_EditGoalSheet> createState() => _EditGoalSheetState();
}

class _EditGoalSheetState extends State<_EditGoalSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _targetCtrl;
  DateTime? _deadline;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.goal.title);
    _targetCtrl = TextEditingController(
        text: widget.goal.targetAmount.toStringAsFixed(0));
    _deadline = widget.goal.deadline;
  }

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

    final updated = widget.goal.copyWith(
      title: _titleCtrl.text.trim(),
      targetAmount: target,
      deadline: _deadline,
    );
    context.read<GoalBloc>().add(UpdateGoal(updated));
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
          const Text('Edit Goal', style: AppTypography.headingMedium),
          const SizedBox(height: 16),
          TextField(
            controller: _titleCtrl,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Goal title'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _targetCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
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
                initialDate: _deadline ??
                    DateTime.now().add(const Duration(days: 30)),
                firstDate: DateTime.now(),
                lastDate:
                    DateTime.now().add(const Duration(days: 3650)),
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
              child: const Text('Save Changes'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Add Goal Sheet ─────────────────────────────────────────

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
          const Text('New Savings Goal', style: AppTypography.headingMedium),
          const SizedBox(height: 16),
          TextField(
            controller: _titleCtrl,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Goal title'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _targetCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
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

// ── Set Budget Sheet ───────────────────────────────────────

class _SetBudgetSheet extends StatefulWidget {
  final List<CategoryModel> categories;
  final CategoryModel? initial; // non-null = editing existing

  const _SetBudgetSheet({required this.categories, this.initial});

  @override
  State<_SetBudgetSheet> createState() => _SetBudgetSheetState();
}

class _SetBudgetSheetState extends State<_SetBudgetSheet> {
  late CategoryModel? _selected;
  late final TextEditingController _amountCtrl;

  @override
  void initState() {
    super.initState();
    _selected = widget.initial ??
        (widget.categories.isNotEmpty ? widget.categories.first : null);
    _amountCtrl = TextEditingController(
      text: widget.initial?.monthlyLimit != null
          ? widget.initial!.monthlyLimit!.toStringAsFixed(0)
          : '',
    );
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (_selected == null) return;
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) return;
    context.read<BudgetBloc>().add(SetBudgetLimit(_selected!.id, amount));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initial != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isEditing ? 'Edit Budget' : 'Set Category Budget',
            style: AppTypography.headingMedium,
          ),
          const SizedBox(height: 16),

          // Editing: show fixed category header
          // Adding: show dropdown picker
          if (isEditing) ...[
            Row(
              children: [
                Icon(CategoryIcon.resolve(widget.initial!.icon), size: 22),
                const SizedBox(width: 12),
                Text(
                  widget.initial!.name,
                  style: AppTypography.bodyLarge
                      .copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ] else if (widget.categories.isNotEmpty) ...[
            InputDecorator(
              decoration: const InputDecoration(labelText: 'Category'),
              child: DropdownButton<CategoryModel>(
                value: _selected,
                isExpanded: true,
                underline: const SizedBox.shrink(),
                items: widget.categories
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Row(
                            children: [
                              Icon(CategoryIcon.resolve(c.icon), size: 16),
                              const SizedBox(width: 8),
                              Text(c.name),
                            ],
                          ),
                        ))
                    .toList(),
                onChanged: (c) => setState(() => _selected = c),
              ),
            ),
            const SizedBox(height: 12),
          ] else ...[
            Text(
              'No categories found. Add categories first.',
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.stone500),
            ),
            const SizedBox(height: 16),
          ],

          TextField(
            controller: _amountCtrl,
            autofocus: true,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Monthly limit',
              prefixText: '₹ ',
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.categories.isEmpty ? null : _save,
              child: const Text('Save Budget'),
            ),
          ),
        ],
      ),
    );
  }
}
