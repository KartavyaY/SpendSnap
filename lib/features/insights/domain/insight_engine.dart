import 'dart:math';
import '../../categories/domain/category_model.dart';
import '../../transactions/domain/transaction_model.dart';
import 'insight_model.dart';

class InsightEngine {

  /// Minimum requirements before generating insights.
  static const _minTransactions = 7;
  static const _minUniqueDays = 3;

  List<Insight> generate({
    required List<TransactionModel> transactions,
    required List<CategoryModel> categories,
    required DateTime now,
  }) {
    // Check data sufficiency
    final expenses = transactions
        .where((t) => t.type == TransactionType.expense)
        .toList();
    final uniqueDays = expenses
        .map((t) => DateTime(t.date.year, t.date.month, t.date.day))
        .toSet()
        .length;

    if (expenses.length < _minTransactions || uniqueDays < _minUniqueDays) {
      return [
        Insight(
          id: 'insufficient_data',
          type: InsightType.observation,
          severity: InsightSeverity.info,
          title: 'Building your financial picture',
          description:
              'Add at least $_minTransactions expenses across $_minUniqueDays different days and insights will start appearing here.',
          generatedAt: now,
        ),
      ];
    }

    final insights = <Insight>[];
    insights.addAll(_weekendSpendingRule(transactions, now));
    insights.addAll(_categoryDriftRule(transactions, categories, now));
    insights.addAll(_burnRateProjectionRule(transactions, categories, now));
    insights.addAll(_unusualTransactionRule(transactions, now));
    insights.addAll(_savingsStreakRule(transactions, now));
    insights.sort((a, b) => b.severity.index.compareTo(a.severity.index));
    return insights;
  }

  // Rule 1: Weekend spending ratio
  List<Insight> _weekendSpendingRule(
    List<TransactionModel> transactions,
    DateTime now,
  ) {
    final startOfMonth = DateTime(now.year, now.month, 1);
    final monthExpenses = transactions.where((t) =>
        t.type == TransactionType.expense &&
        t.date.isAfter(startOfMonth.subtract(const Duration(seconds: 1))));

    double weekendTotal = 0;
    int weekendDays = 0;
    double weekdayTotal = 0;
    int weekdayDays = 0;

    for (final t in monthExpenses) {
      if (t.date.weekday == DateTime.saturday ||
          t.date.weekday == DateTime.sunday) {
        weekendTotal += t.amount;
      } else {
        weekdayTotal += t.amount;
      }
    }

    // Count unique weekend/weekday days in current month up to now
    for (int d = 1; d <= now.day; d++) {
      final day = DateTime(now.year, now.month, d);
      if (day.weekday == DateTime.saturday || day.weekday == DateTime.sunday) {
        weekendDays++;
      } else {
        weekdayDays++;
      }
    }

    if (weekendDays == 0 || weekdayDays == 0 || weekdayTotal == 0) return [];

    final weekendPerDay = weekendTotal / weekendDays;
    final weekdayPerDay = weekdayTotal / weekdayDays;

    if (weekdayPerDay == 0 || weekendPerDay <= weekdayPerDay * 1.5) return [];

    final ratio = ((weekendPerDay / weekdayPerDay - 1) * 100).round();

    return [
      Insight(
        id: 'weekend_${now.year}_${now.month}',
        type: InsightType.observation,
        severity: InsightSeverity.medium,
        title: 'You spend more on weekends',
        description:
            'Your weekend daily spend is $ratio% higher than weekdays. Consider planning weekend budgets.',
        actionLabel: 'View Analytics',
        actionRoute: '/analytics',
        generatedAt: now,
      ),
    ];
  }

  // Rule 2: Category drift (50%+ increase month over month)
  List<Insight> _categoryDriftRule(
    List<TransactionModel> transactions,
    List<CategoryModel> categories,
    DateTime now,
  ) {
    final thisMonthStart = DateTime(now.year, now.month, 1);
    final lastMonthStart = DateTime(now.year, now.month - 1, 1);
    final lastMonthEnd = thisMonthStart.subtract(const Duration(seconds: 1));

    final insights = <Insight>[];

    for (final category in categories) {
      final thisMonth = transactions
          .where((t) =>
              t.categoryId == category.id &&
              t.type == TransactionType.expense &&
              t.date.isAfter(
                  thisMonthStart.subtract(const Duration(seconds: 1))))
          .fold(0.0, (sum, t) => sum + t.amount);

      final lastMonth = transactions
          .where((t) =>
              t.categoryId == category.id &&
              t.type == TransactionType.expense &&
              t.date.isAfter(
                  lastMonthStart.subtract(const Duration(seconds: 1))) &&
              t.date.isBefore(lastMonthEnd.add(const Duration(seconds: 1))))
          .fold(0.0, (sum, t) => sum + t.amount);

      if (lastMonth == 0 || thisMonth <= 1000) continue;

      final drift = (thisMonth - lastMonth) / lastMonth;
      if (drift <= 0.5) continue;

      final pct = (drift * 100).round();
      insights.add(Insight(
        id: 'drift_${category.id}_${now.year}_${now.month}',
        type: InsightType.warning,
        severity: InsightSeverity.high,
        title: '${category.name} spending is up $pct%',
        description:
            "You've spent ₹${thisMonth.toStringAsFixed(0)} on ${category.name} this month, up from ₹${lastMonth.toStringAsFixed(0)} last month.",
        actionLabel: 'View Budget',
        actionRoute: '/budgets',
        generatedAt: now,
      ));
    }

    return insights;
  }

  // Rule 3: Burn rate projection
  List<Insight> _burnRateProjectionRule(
    List<TransactionModel> transactions,
    List<CategoryModel> categories,
    DateTime now,
  ) {
    final daysIntoMonth = now.day;
    if (daysIntoMonth < 7) return [];

    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final monthStart = DateTime(now.year, now.month, 1);

    final insights = <Insight>[];

    for (final category in categories) {
      final limit = category.monthlyLimit;
      if (limit == null || limit <= 0) continue;

      final currentSpend = transactions
          .where((t) =>
              t.categoryId == category.id &&
              t.type == TransactionType.expense &&
              t.date
                  .isAfter(monthStart.subtract(const Duration(seconds: 1))))
          .fold(0.0, (sum, t) => sum + t.amount);

      if (currentSpend == 0) continue;

      final projectedSpend = currentSpend / daysIntoMonth * daysInMonth;

      if (projectedSpend <= limit * 1.1) continue;

      insights.add(Insight(
        id: 'burn_${category.id}_${now.year}_${now.month}',
        type: InsightType.projection,
        severity: InsightSeverity.high,
        title: '${category.name} on track to exceed budget',
        description:
            'At current pace, you\'ll spend ₹${projectedSpend.toStringAsFixed(0)} by month-end (budget: ₹${limit.toStringAsFixed(0)}).',
        actionLabel: 'View Budget',
        actionRoute: '/budgets',
        generatedAt: now,
      ));
    }

    return insights;
  }

  // Rule 4: Unusual transaction (> mean + 2*stddev in last 30 days)
  List<Insight> _unusualTransactionRule(
    List<TransactionModel> transactions,
    DateTime now,
  ) {
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    final last30 = transactions
        .where((t) =>
            t.type == TransactionType.expense &&
            t.date.isAfter(thirtyDaysAgo))
        .toList();

    if (last30.length < 3) return [];

    final amounts = last30.map((t) => t.amount).toList();
    final mean = amounts.fold(0.0, (a, b) => a + b) / amounts.length;
    final variance = amounts
            .map((a) => (a - mean) * (a - mean))
            .fold(0.0, (a, b) => a + b) /
        amounts.length;
    final stddev = sqrt(variance);

    final threshold = mean + 2 * stddev;

    final insights = <Insight>[];
    final recentUnusual = last30.where((t) =>
        t.date.isAfter(sevenDaysAgo) && t.amount > threshold);

    for (final t in recentUnusual) {
      insights.add(Insight(
        id: 'unusual_${t.id}',
        type: InsightType.observation,
        severity: InsightSeverity.medium,
        title: 'Unusual transaction detected',
        description:
            'A ₹${t.amount.toStringAsFixed(0)} expense on ${_formatDate(t.date)} is significantly higher than your typical spending.',
        generatedAt: now,
      ));
    }

    return insights;
  }

  // Rule 5: Savings streak (consecutive months income > expense)
  List<Insight> _savingsStreakRule(
    List<TransactionModel> transactions,
    DateTime now,
  ) {
    int streak = 0;

    for (int i = 1; i <= 12; i++) {
      final monthStart = DateTime(now.year, now.month - i, 1);
      final monthEnd = DateTime(now.year, now.month - i + 1, 1)
          .subtract(const Duration(seconds: 1));

      final monthTxns = transactions.where((t) =>
          t.date.isAfter(monthStart.subtract(const Duration(seconds: 1))) &&
          t.date.isBefore(monthEnd.add(const Duration(seconds: 1))));

      final income = monthTxns
          .where((t) => t.type == TransactionType.income)
          .fold(0.0, (s, t) => s + t.amount);

      final expense = monthTxns
          .where((t) => t.type == TransactionType.expense)
          .fold(0.0, (s, t) => s + t.amount);

      if (income > expense) {
        streak++;
      } else {
        break;
      }
    }

    if (streak < 2) return [];

    return [
      Insight(
        id: 'streak_${now.year}_${now.month}',
        type: InsightType.achievement,
        severity: InsightSeverity.low,
        title: '$streak-month savings streak',
        description:
            "You've spent less than you earned for $streak months in a row. Keep it up!",
        generatedAt: now,
      ),
    ];
  }

  String _formatDate(DateTime date) =>
      '${date.day}/${date.month}/${date.year}';
}
