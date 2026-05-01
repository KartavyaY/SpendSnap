import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../shared/widgets/transaction_tile.dart';
import '../../../categories/presentation/bloc/category_bloc.dart';
import '../../../categories/presentation/bloc/category_state.dart';
import '../bloc/transaction_bloc.dart';
import '../bloc/transaction_event.dart';
import '../bloc/transaction_state.dart';
import '../../domain/transaction_model.dart';

class TransactionListPage extends StatefulWidget {
  const TransactionListPage({super.key});

  @override
  State<TransactionListPage> createState() => _TransactionListPageState();
}

class _TransactionListPageState extends State<TransactionListPage> {
  TransactionType? _typeFilter;

  void _applyFilter(TransactionType? type) {
    setState(() => _typeFilter = type);
    context.read<TransactionBloc>().add(FilterTransactions(
          typeFilter: type,
          searchQuery: null,
        ));
  }

  Map<String, List<TransactionModel>> _groupByDate(
      List<TransactionModel> txns) {
    final map = <String, List<TransactionModel>>{};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    for (final t in txns) {
      final d = DateTime(t.date.year, t.date.month, t.date.day);
      final diff = today.difference(d).inDays;
      final label = diff == 0
          ? 'Today'
          : diff == 1
              ? 'Yesterday'
              : AppDateUtils.formatDay(t.date);
      map.putIfAbsent(label, () => []).add(t);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Activity'),
        leading: IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            // Search action (no-op placeholder)
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_outlined),
            onPressed: () {
              // Filter action (no-op placeholder)
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter chips row
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              children: [
                _FilterPill(
                  label: 'All',
                  active: _typeFilter == null,
                  onTap: () => _applyFilter(null),
                ),
                const SizedBox(width: 8),
                _FilterPill(
                  label: 'Expenses',
                  active: _typeFilter == TransactionType.expense,
                  onTap: () => _applyFilter(TransactionType.expense),
                ),
                const SizedBox(width: 8),
                _FilterPill(
                  label: 'Income',
                  active: _typeFilter == TransactionType.income,
                  onTap: () => _applyFilter(TransactionType.income),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: BlocBuilder<TransactionBloc, TransactionState>(
              builder: (context, txnState) {
                if (txnState is TransactionLoading) {
                  return const LoadingIndicator();
                }

                if (txnState is TransactionError) {
                  return EmptyState(
                    title: 'Something went wrong',
                    description: txnState.message,
                    icon: Icons.error_outline,
                  );
                }

                if (txnState is TransactionLoaded) {
                  final txns = txnState.filtered;

                  if (txns.isEmpty) {
                    return EmptyState(
                      title: _typeFilter != null
                          ? 'No results found'
                          : 'No transactions yet',
                      description: _typeFilter != null
                          ? 'Try a different filter.'
                          : 'Add your first transaction to get started.',
                      icon: Icons.receipt_long_outlined,
                      actionLabel: 'Add Transaction',
                      onAction: () => context.go('/transactions/add'),
                    );
                  }

                  return BlocBuilder<CategoryBloc, CategoryState>(
                    builder: (context, catState) {
                      final categories = catState is CategoryLoaded
                          ? catState.categories
                          : <dynamic>[];

                      final grouped = _groupByDate(txns);

                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                        itemCount: grouped.length,
                        itemBuilder: (_, groupIndex) {
                          final label =
                              grouped.keys.elementAt(groupIndex);
                          final groupTxns = grouped[label]!;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Eyebrow label
                                Text(
                                  label.toUpperCase(),
                                  style: AppTypography.eyebrow,
                                ),
                                const SizedBox(height: 8),
                                // Grouped card
                                Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.cream50,
                                    borderRadius:
                                        BorderRadius.circular(16),
                                    border: Border.all(
                                        color: AppColors.borderHair),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  child: Column(
                                    children: List.generate(
                                      groupTxns.length,
                                      (i) {
                                        final txn = groupTxns[i];
                                        final cat = categories.isEmpty
                                            ? null
                                            : categories
                                                .cast<dynamic>()
                                                .firstWhere(
                                                  (c) =>
                                                      c.id == txn.categoryId,
                                                  orElse: () => null,
                                                );
                                        final isLast =
                                            i == groupTxns.length - 1;

                                        return DecoratedBox(
                                          decoration: BoxDecoration(
                                            border: isLast
                                                ? null
                                                : const Border(
                                                    bottom: BorderSide(
                                                      color: AppColors
                                                          .borderHair,
                                                      width: 1,
                                                    ),
                                                  ),
                                          ),
                                          child: TransactionTile(
                                            transaction: txn,
                                            category: cat,
                                            onTap: () => context.go(
                                                '/transactions/edit/${txn.id}'),
                                            onDelete: () => context
                                                .read<TransactionBloc>()
                                                .add(DeleteTransaction(
                                                    txn.id)),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/transactions/add'),
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: active ? AppColors.ink : AppColors.cream200,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: active ? AppColors.paper : AppColors.ink,
              height: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}
