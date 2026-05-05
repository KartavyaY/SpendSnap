import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../categories/domain/category_model.dart';
import '../../../categories/presentation/bloc/category_bloc.dart';
import '../../../categories/presentation/bloc/category_state.dart';
import '../../../transactions/domain/transaction_model.dart';
import '../../../transactions/presentation/bloc/transaction_bloc.dart';
import '../../../transactions/presentation/bloc/transaction_state.dart';

enum _DateRange { thisMonth, last3Months, last6Months, thisYear }

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  _DateRange _range = _DateRange.thisMonth;

  List<TransactionModel> _filterByRange(List<TransactionModel> all) {
    final now = DateTime.now();
    DateTime from;
    switch (_range) {
      case _DateRange.thisMonth:
        from = AppDateUtils.startOfMonth(now);
      case _DateRange.last3Months:
        from = AppDateUtils.nMonthsAgo(now, 3);
      case _DateRange.last6Months:
        from = AppDateUtils.nMonthsAgo(now, 6);
      case _DateRange.thisYear:
        from = DateTime(now.year, 1, 1);
    }
    return all.where((t) => t.date.isAfter(from)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: BlocBuilder<TransactionBloc, TransactionState>(
        builder: (context, txnState) {
          if (txnState is TransactionLoading) return const LoadingIndicator();

          final allTxns = txnState is TransactionLoaded
              ? txnState.transactions
              : <TransactionModel>[];
          final filtered = _filterByRange(allTxns);

          return BlocBuilder<CategoryBloc, CategoryState>(
            builder: (context, catState) {
              final categories = catState is CategoryLoaded
                  ? catState.categories
                  : <CategoryModel>[];

              return ListView(
                padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).padding.bottom),
                children: [
                  // Date range selector
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _DateRange.values.map((r) {
                        final labels = {
                          _DateRange.thisMonth: 'This Month',
                          _DateRange.last3Months: 'Last 3M',
                          _DateRange.last6Months: 'Last 6M',
                          _DateRange.thisYear: 'This Year',
                        };
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(labels[r]!),
                            selected: _range == r,
                            onSelected: (_) =>
                                setState(() => _range = r),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (filtered.isEmpty)
                    const EmptyState(
                      title: 'No data',
                      description: 'Add transactions to see your analytics.',
                      icon: Icons.bar_chart_outlined,
                    )
                  else ...[
                    // Pie chart
                    _ChartSection(
                      title: 'Spending by Category',
                      interpretation: _buildPieInterpretation(
                          filtered, categories),
                      child: _CategoryPieChart(
                          transactions: filtered, categories: categories),
                    ),
                    const SizedBox(height: 24),

                    // Bar chart
                    _ChartSection(
                      title: 'Income vs Expense (6 months)',
                      interpretation: _buildBarInterpretation(allTxns),
                      child: _MonthlyBarChart(transactions: allTxns),
                    ),
                    const SizedBox(height: 24),

                    // Line chart
                    _ChartSection(
                      title: 'Balance (last 30 days)',
                      interpretation: _buildLineInterpretation(allTxns),
                      child: _BalanceLineChart(transactions: allTxns),
                    ),
                  ],
                ],
              );
            },
          );
        },
      ),
    );
  }

  String _buildPieInterpretation(
    List<TransactionModel> txns,
    List<CategoryModel> categories,
  ) {
    final expenses = txns.where((t) => t.type == TransactionType.expense);
    if (expenses.isEmpty) return 'No expenses in this period.';

    final totals = <String, double>{};
    for (final t in expenses) {
      totals[t.categoryId] = (totals[t.categoryId] ?? 0) + t.amount;
    }

    if (totals.isEmpty) return 'No expense data.';

    final topId =
        totals.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    final topCat =
        categories.firstWhere((c) => c.id == topId, orElse: () => categories.first);
    final totalSpend = totals.values.fold(0.0, (a, b) => a + b);
    final topPct =
        totalSpend > 0 ? ((totals[topId]! / totalSpend) * 100).round() : 0;

    return '${topCat.name} is your top spending category at $topPct%.';
  }

  String _buildBarInterpretation(List<TransactionModel> txns) {
    final now = DateTime.now();
    final thisMonthIncome = txns
        .where((t) =>
            t.type == TransactionType.income &&
            AppDateUtils.isSameMonth(t.date, now))
        .fold(0.0, (s, t) => s + t.amount);
    final thisMonthExpense = txns
        .where((t) =>
            t.type == TransactionType.expense &&
            AppDateUtils.isSameMonth(t.date, now))
        .fold(0.0, (s, t) => s + t.amount);

    if (thisMonthIncome > thisMonthExpense) {
      return 'This month you are saving ${CurrencyFormatter.format(thisMonthIncome - thisMonthExpense)} so far.';
    } else if (thisMonthExpense > thisMonthIncome) {
      return 'This month you are overspending by ${CurrencyFormatter.format(thisMonthExpense - thisMonthIncome)}.';
    }
    return 'Income and expenses are balanced this month.';
  }

  String _buildLineInterpretation(List<TransactionModel> txns) {
    final now = DateTime.now();
    final last30 = now.subtract(const Duration(days: 30));
    final recent = txns.where((t) => t.date.isAfter(last30));
    final netChange = recent.fold(0.0, (s, t) {
      return t.type == TransactionType.income ? s + t.amount : s - t.amount;
    });
    if (netChange > 0) {
      return 'Your balance grew by ${CurrencyFormatter.format(netChange)} over the last 30 days.';
    } else if (netChange < 0) {
      return 'Your balance decreased by ${CurrencyFormatter.format(-netChange)} over the last 30 days.';
    }
    return 'Your balance is unchanged over the last 30 days.';
  }
}

class _ChartSection extends StatelessWidget {
  final String title;
  final Widget child;
  final String interpretation;

  const _ChartSection({
    required this.title,
    required this.child,
    required this.interpretation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.headingMedium),
          const SizedBox(height: 16),
          SizedBox(height: 200, child: child),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.info_outline,
                  size: 14, color: AppColors.textTertiary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  interpretation,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryPieChart extends StatelessWidget {
  final List<TransactionModel> transactions;
  final List<CategoryModel> categories;

  const _CategoryPieChart(
      {required this.transactions, required this.categories});

  Color _parseColor(String hex) {
    try {
      return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final expenses =
        transactions.where((t) => t.type == TransactionType.expense).toList();
    if (expenses.isEmpty) {
      return const Center(child: Text('No expense data'));
    }

    final totals = <String, double>{};
    for (final t in expenses) {
      totals[t.categoryId] = (totals[t.categoryId] ?? 0) + t.amount;
    }

    final total = totals.values.fold(0.0, (a, b) => a + b);

    final sections = totals.entries.map((e) {
      final cat =
          categories.firstWhere((c) => c.id == e.key, orElse: () => categories.first);
      final pct = total > 0 ? (e.value / total * 100).round() : 0;
      return PieChartSectionData(
        value: e.value,
        color: _parseColor(cat.color),
        title: '$pct%',
        radius: 70,
        titleStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      );
    }).toList();

    return PieChart(
      PieChartData(
        sections: sections,
        centerSpaceRadius: 32,
        sectionsSpace: 2,
      ),
    );
  }
}

class _MonthlyBarChart extends StatelessWidget {
  final List<TransactionModel> transactions;
  const _MonthlyBarChart({required this.transactions});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final groups = <BarChartGroupData>[];

    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final income = transactions
          .where((t) =>
              t.type == TransactionType.income &&
              AppDateUtils.isSameMonth(t.date, month))
          .fold(0.0, (s, t) => s + t.amount);
      final expense = transactions
          .where((t) =>
              t.type == TransactionType.expense &&
              AppDateUtils.isSameMonth(t.date, month))
          .fold(0.0, (s, t) => s + t.amount);

      groups.add(BarChartGroupData(
        x: 5 - i,
        barRods: [
          BarChartRodData(
            toY: income,
            color: AppColors.success,
            width: 10,
            borderRadius: BorderRadius.circular(4),
          ),
          BarChartRodData(
            toY: expense,
            color: AppColors.danger,
            width: 10,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ));
    }

    return BarChart(
      BarChartData(
        barGroups: groups,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) {
                final month =
                    DateTime(now.year, now.month - (5 - v.toInt()), 1);
                return Text(
                  AppDateUtils.formatShortMonth(month).substring(0, 3),
                  style: AppTypography.caption,
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
        ),
      ),
    );
  }
}

class _BalanceLineChart extends StatelessWidget {
  final List<TransactionModel> transactions;
  const _BalanceLineChart({required this.transactions});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final spots = <FlSpot>[];
    double runningBalance = 0;

    for (int d = 29; d >= 0; d--) {
      final day = now.subtract(Duration(days: d));
      final dayStart = AppDateUtils.startOfDay(day);
      final dayEnd = dayStart.add(const Duration(hours: 23, minutes: 59));
      final dayTxns = transactions.where(
          (t) => t.date.isAfter(dayStart) && t.date.isBefore(dayEnd));

      for (final t in dayTxns) {
        runningBalance += t.type == TransactionType.income
            ? t.amount
            : -t.amount;
      }
      spots.add(FlSpot((29 - d).toDouble(), runningBalance));
    }

    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.primary,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primary.withValues(alpha: 0.1),
            ),
          ),
        ],
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
      ),
    );
  }
}
