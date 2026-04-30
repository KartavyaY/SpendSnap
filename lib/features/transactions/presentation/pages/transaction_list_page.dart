import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
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
  final _searchCtrl = TextEditingController();
  TransactionType? _typeFilter;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _applyFilter() {
    context.read<TransactionBloc>().add(FilterTransactions(
          typeFilter: _typeFilter,
          searchQuery: _searchCtrl.text.isEmpty ? null : _searchCtrl.text,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          PopupMenuButton<TransactionType?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (v) {
              setState(() => _typeFilter = v);
              _applyFilter();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: null, child: Text('All')),
              const PopupMenuItem(
                  value: TransactionType.income, child: Text('Income')),
              const PopupMenuItem(
                  value: TransactionType.expense, child: Text('Expense')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                hintText: 'Search by note...',
                prefixIcon: Icon(Icons.search, size: 20),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onChanged: (_) => _applyFilter(),
            ),
          ),

          // Filter chips
          if (_typeFilter != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  FilterChip(
                    label: Text(_typeFilter == TransactionType.income
                        ? 'Income'
                        : 'Expense'),
                    selected: true,
                    onSelected: (_) {
                      setState(() => _typeFilter = null);
                      _applyFilter();
                    },
                    avatar: Icon(
                      _typeFilter == TransactionType.income
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      size: 14,
                      color: _typeFilter == TransactionType.income
                          ? AppColors.success
                          : AppColors.danger,
                    ),
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
                      title: txnState.searchQuery != null
                          ? 'No results found'
                          : 'No transactions yet',
                      description: txnState.searchQuery != null
                          ? 'Try a different search term.'
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

                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: txns.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 4),
                        itemBuilder: (_, i) {
                          final txn = txns[i];
                          final cat = categories.isEmpty
                              ? null
                              : categories.cast<dynamic>().firstWhere(
                                    (c) => c.id == txn.categoryId,
                                    orElse: () => null,
                                  );
                          return TransactionTile(
                            transaction: txn,
                            category: cat,
                            onTap: () => context
                                .go('/transactions/edit/${txn.id}'),
                            onDelete: () => context
                                .read<TransactionBloc>()
                                .add(DeleteTransaction(txn.id)),
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
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
    );
  }
}
