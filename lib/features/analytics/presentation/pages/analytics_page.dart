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

// Brighter red for charts — AppColors.danger is too dark/maroon for data vis
const Color _kChartRed = Color(0xFFE53935);

enum _DateRange { thisMonth, last3Months, last6Months, thisYear }

extension _DateRangeLabel on _DateRange {
  String get label {
    switch (this) {
      case _DateRange.thisMonth:
        return 'This Month';
      case _DateRange.last3Months:
        return 'Last 3M';
      case _DateRange.last6Months:
        return 'Last 6M';
      case _DateRange.thisYear:
        return 'This Year';
    }
  }

  String get eyebrow {
    switch (this) {
      case _DateRange.thisMonth:
        return 'THIS MONTH';
      case _DateRange.last3Months:
        return 'LAST 3 MONTHS';
      case _DateRange.last6Months:
        return 'LAST 6 MONTHS';
      case _DateRange.thisYear:
        return 'THIS YEAR';
    }
  }
}

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
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Analytics', style: AppTypography.headingLarge),
      ),
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

              final income = filtered
                  .where((t) => t.type == TransactionType.income)
                  .fold(0.0, (s, t) => s + t.amount);
              final expense = filtered
                  .where((t) => t.type == TransactionType.expense)
                  .fold(0.0, (s, t) => s + t.amount);

              return ListView(
                padding: EdgeInsets.fromLTRB(
                  16, 8, 16, MediaQuery.of(context).padding.bottom,
                ),
                children: [
                  // ── Date range selector ──────────────────────────
                  _DateRangeSelector(
                    selected: _range,
                    onChanged: (r) => setState(() => _range = r),
                  ),
                  const SizedBox(height: 16),

                  // ── Summary hero card ────────────────────────────
                  _SummaryCard(
                    range: _range,
                    income: income,
                    expense: expense,
                  ),
                  const SizedBox(height: 28),

                  if (filtered.isEmpty)
                    const EmptyState(
                      title: 'No data',
                      description: 'Add transactions to see your analytics.',
                      icon: Icons.bar_chart_outlined,
                    )
                  else ...[
                    // ── Spending by category ─────────────────────
                    const Text('SPENDING', style: AppTypography.eyebrow),
                    const SizedBox(height: 10),
                    _SectionCard(
                      title: 'By Category',
                      child: _CategoryPieChart(
                        transactions: filtered,
                        categories: categories,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Income vs expenses ───────────────────────
                    const Text('HISTORY', style: AppTypography.eyebrow),
                    const SizedBox(height: 10),
                    _SectionCard(
                      title: 'Income vs Expenses',
                      subtitle: 'Last 6 months',
                      child: _MonthlyBarChart(transactions: allTxns),
                    ),
                    const SizedBox(height: 24),

                    // ── Balance trend ────────────────────────────
                    const Text('TREND', style: AppTypography.eyebrow),
                    const SizedBox(height: 10),
                    _SectionCard(
                      title: 'Balance',
                      subtitle: 'Last 30 days',
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
}

// ── Date range selector ────────────────────────────────────────────────────

class _DateRangeSelector extends StatelessWidget {
  final _DateRange selected;
  final ValueChanged<_DateRange> onChanged;

  const _DateRangeSelector({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _DateRange.values.map((r) {
          final isSelected = r == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onChanged(r),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.ink : AppColors.cream200,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  r.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? AppColors.paper : AppColors.stone600,
                    height: 1.2,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Summary tiles ──────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final _DateRange range;
  final double income;
  final double expense;

  const _SummaryCard({
    required this.range,
    required this.income,
    required this.expense,
  });

  @override
  Widget build(BuildContext context) {
    final net = income - expense;
    final netAbs = net.abs();
    final isPositive = net >= 0;
    final total = income + expense;
    final expenseRatio = total > 0 ? (expense / total).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          range.eyebrow,
          style: AppTypography.eyebrow,
        ),
        const SizedBox(height: 10),
        // 3 stat tiles
        IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: 'Spent',
                  value: CurrencyFormatter.format(expense),
                  bg: AppColors.dangerBg,
                  fg: AppColors.danger,
                  icon: Icons.arrow_upward_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatTile(
                  label: 'Income',
                  value: CurrencyFormatter.format(income),
                  bg: AppColors.successBg,
                  fg: AppColors.success,
                  icon: Icons.arrow_downward_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatTile(
                  label: 'Net',
                  value: '${isPositive ? '+' : '-'}${CurrencyFormatter.format(netAbs)}',
                  bg: isPositive ? AppColors.successBg : AppColors.dangerBg,
                  fg: isPositive ? AppColors.success : AppColors.danger,
                  icon: isPositive
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                ),
              ),
            ],
          ),
        ),
        if (total > 0) ...[
          const SizedBox(height: 12),
          // Ratio bar: expense (red) vs income (green)
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 8,
              child: Row(
                children: [
                  Flexible(
                    flex: (expenseRatio * 1000).round(),
                    child: Container(color: _kChartRed),
                  ),
                  Flexible(
                    flex: ((1 - expenseRatio) * 1000).round(),
                    child: Container(color: AppColors.success),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(expenseRatio * 100).round()}% spent',
                style: AppTypography.caption
                    .copyWith(color: _kChartRed),
              ),
              Text(
                '${((1 - expenseRatio) * 100).round()}% saved',
                style: AppTypography.caption
                    .copyWith(color: AppColors.success),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color bg;
  final Color fg;
  final IconData icon;

  const _StatTile({
    required this.label,
    required this.value,
    required this.bg,
    required this.fg,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: fg),
              const SizedBox(width: 4),
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTypography.moneySmall.copyWith(
              color: fg,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Section card wrapper ───────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const _SectionCard({
    required this.title,
    this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cream50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderHair),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(title, style: AppTypography.headingMedium),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: AppTypography.caption
                      .copyWith(color: AppColors.stone500),
                ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

// ── Pie chart ──────────────────────────────────────────────────────────────

class _CategoryPieChart extends StatelessWidget {
  final List<TransactionModel> transactions;
  final List<CategoryModel> categories;

  const _CategoryPieChart({
    required this.transactions,
    required this.categories,
  });

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
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text('No expenses in this period.',
              style: AppTypography.bodySmall),
        ),
      );
    }

    final totals = <String, double>{};
    for (final t in expenses) {
      totals[t.categoryId] = (totals[t.categoryId] ?? 0) + t.amount;
    }

    final total = totals.values.fold(0.0, (a, b) => a + b);

    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topEntries = sorted.take(5).toList();
    final otherTotal = sorted.length > 5
        ? sorted.skip(5).fold(0.0, (s, e) => s + e.value)
        : 0.0;

    final sections = <PieChartSectionData>[];
    final legendItems = <_LegendItem>[];

    for (final e in topEntries) {
      final cat = categories.firstWhere(
        (c) => c.id == e.key,
        orElse: () => categories.isEmpty
            ? const CategoryModel(
                id: '', uid: '', name: 'Unknown',
                icon: '📦', color: '#8A857C',
              )
            : categories.first,
      );
      final color = _parseColor(cat.color);
      final pct = total > 0 ? e.value / total * 100 : 0.0;
      sections.add(PieChartSectionData(
        value: e.value,
        color: color,
        title: '',
        radius: 56,
      ));
      legendItems.add(_LegendItem(
        color: color, name: cat.name, amount: e.value, pct: pct,
      ));
    }

    if (otherTotal > 0) {
      final pct = total > 0 ? otherTotal / total * 100 : 0.0;
      sections.add(PieChartSectionData(
        value: otherTotal, color: AppColors.cream400, title: '', radius: 56,
      ));
      legendItems.add(_LegendItem(
        color: AppColors.cream400, name: 'Other',
        amount: otherTotal, pct: pct,
      ));
    }

    return Column(
      children: [
        // Donut with total in center
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: 52,
                  sectionsSpace: 3,
                  startDegreeOffset: -90,
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'total',
                  style: AppTypography.caption
                      .copyWith(color: AppColors.stone500),
                ),
                const SizedBox(height: 2),
                Text(
                  CurrencyFormatter.format(total),
                  style: AppTypography.moneyBody,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Divider(color: AppColors.borderHair, height: 1),
        const SizedBox(height: 16),
        ...legendItems.map((item) => _LegendRow(item: item, total: total)),
      ],
    );
  }
}

class _LegendItem {
  final Color color;
  final String name;
  final double amount;
  final double pct;

  const _LegendItem({
    required this.color,
    required this.name,
    required this.amount,
    required this.pct,
  });
}

class _LegendRow extends StatelessWidget {
  final _LegendItem item;
  final double total;

  const _LegendRow({required this.item, required this.total});

  @override
  Widget build(BuildContext context) {
    final filledFlex = (item.pct * 10).round().clamp(1, 1000);
    final emptyFlex = (1000 - filledFlex).clamp(0, 999);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 10, height: 10,
            decoration: BoxDecoration(
              color: item.color, shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 80,
            child: Text(
              item.name,
              style: AppTypography.label.copyWith(color: AppColors.stone700),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 10),
          // Mini progress bar
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: SizedBox(
                height: 7,
                child: Row(
                  children: [
                    Flexible(
                      flex: filledFlex,
                      child: Container(color: item.color),
                    ),
                    if (emptyFlex > 0)
                      Flexible(
                        flex: emptyFlex,
                        child: Container(color: AppColors.cream300),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 34,
            child: Text(
              '${item.pct.round()}%',
              style: AppTypography.caption
                  .copyWith(color: AppColors.stone500),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            CurrencyFormatter.format(item.amount),
            style: AppTypography.moneySmall,
          ),
        ],
      ),
    );
  }
}

// ── Bar chart ──────────────────────────────────────────────────────────────

class _MonthlyBarChart extends StatelessWidget {
  final List<TransactionModel> transactions;
  const _MonthlyBarChart({required this.transactions});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final groups = <BarChartGroupData>[];

    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final isCurrent = i == 0;
      final alpha = isCurrent ? 1.0 : 0.55;

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
        barsSpace: 5,
        barRods: [
          BarChartRodData(
            toY: income,
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                AppColors.success.withValues(alpha: alpha * 0.45),
                AppColors.success.withValues(alpha: alpha),
              ],
            ),
            width: 13,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
          BarChartRodData(
            toY: expense,
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                _kChartRed.withValues(alpha: alpha * 0.45),
                _kChartRed.withValues(alpha: alpha),
              ],
            ),
            width: 13,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ],
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            _ChartDot(color: AppColors.success, label: 'Income'),
            SizedBox(width: 16),
            _ChartDot(color: _kChartRed, label: 'Expenses'),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: BarChart(
            BarChartData(
              barGroups: groups,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => const FlLine(
                  color: AppColors.borderHair,
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => AppColors.ink,
                  tooltipRoundedRadius: 10,
                  getTooltipItem: (group, _, rod, rodIndex) {
                    final label = rodIndex == 0 ? 'Income' : 'Expense';
                    return BarTooltipItem(
                      '$label\n',
                      AppTypography.caption
                          .copyWith(color: AppColors.cream300),
                      children: [
                        TextSpan(
                          text: CurrencyFormatter.format(rod.toY),
                          style: AppTypography.moneySmall
                              .copyWith(color: AppColors.paper),
                        ),
                      ],
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (v, _) {
                      final idx = v.toInt();
                      final month = DateTime(
                          now.year, now.month - (5 - idx), 1);
                      final isCurrent = idx == 5;
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          AppDateUtils.formatShortMonth(month).substring(0, 3),
                          style: AppTypography.caption.copyWith(
                            color: isCurrent
                                ? AppColors.ink
                                : AppColors.stone500,
                            fontWeight: isCurrent
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                        ),
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
          ),
        ),
      ],
    );
  }
}

class _ChartDot extends StatelessWidget {
  final Color color;
  final String label;

  const _ChartDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppTypography.caption),
      ],
    );
  }
}

// ── Line chart ─────────────────────────────────────────────────────────────

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
        runningBalance +=
            t.type == TransactionType.income ? t.amount : -t.amount;
      }
      spots.add(FlSpot((29 - d).toDouble(), runningBalance));
    }

    final ys = spots.map((s) => s.y).toList();
    final maxY = ys.reduce((a, b) => a > b ? a : b);
    final minY = ys.reduce((a, b) => a < b ? a : b);
    final rangeY = (maxY - minY).abs();
    final yPad = rangeY > 0 ? rangeY * 0.2 : 100.0;

    final startVal = spots.first.y;
    final endVal = spots.last.y;
    final isPositiveTrend = endVal >= startVal;
    final trendColor = isPositiveTrend ? AppColors.success : AppColors.danger;
    final trendDiff = (endVal - startVal).abs();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Trend badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: trendColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isPositiveTrend
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                size: 14, color: trendColor,
              ),
              const SizedBox(width: 5),
              Text(
                isPositiveTrend
                    ? '+${CurrencyFormatter.format(trendDiff)} over 30 days'
                    : '-${CurrencyFormatter.format(trendDiff)} over 30 days',
                style: AppTypography.caption.copyWith(
                  color: trendColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 150,
          child: LineChart(
            LineChartData(
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  curveSmoothness: 0.3,
                  color: trendColor,
                  barWidth: 2.5,
                  dotData: FlDotData(
                    show: true,
                    checkToShowDot: (spot, _) =>
                        spot.x == 0 || spot.x == 29,
                    getDotPainter: (spot, _, __, ___) =>
                        FlDotCirclePainter(
                          radius: 4,
                          color: trendColor,
                          strokeWidth: 2.5,
                          strokeColor: AppColors.cream50,
                        ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        trendColor.withValues(alpha: 0.22),
                        trendColor.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ],
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => const FlLine(
                  color: AppColors.borderHair,
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              minY: minY - yPad,
              maxY: maxY + yPad,
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => AppColors.ink,
                  tooltipRoundedRadius: 10,
                  getTooltipItems: (spots) => spots.map((s) =>
                    LineTooltipItem(
                      CurrencyFormatter.format(s.y),
                      AppTypography.moneySmall
                          .copyWith(color: AppColors.paper),
                    ),
                  ).toList(),
                ),
              ),
              titlesData: const FlTitlesData(
                leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
