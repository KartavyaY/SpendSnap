import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/category_icon.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../shared/widgets/transaction_tile.dart';
import '../../../categories/domain/category_model.dart';
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
  List<String> _categoryFilters = [];
  DateTime? _from;
  DateTime? _to;
  bool _searchActive = false;
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _applyFilter({
    TransactionType? type,
    List<String> categoryIds = const [],
    DateTime? from,
    DateTime? to,
    String? search,
  }) {
    final catState = context.read<CategoryBloc>().state;
    final categoryNames = catState is CategoryLoaded
        ? {for (final c in catState.categories) c.id: c.name}
        : <String, String>{};

    context.read<TransactionBloc>().add(FilterTransactions(
          typeFilter: type,
          categoryFilters: categoryIds,
          from: from,
          to: to,
          searchQuery: search,
          categoryNames: categoryNames,
        ));
  }

  void _onTypeChip(TransactionType? type) {
    setState(() => _typeFilter = type);
    _applyFilter(
      type: type,
      categoryIds: _categoryFilters,
      from: _from,
      to: _to,
      search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
    );
  }

  void _onSearch(String query) {
    setState(() {}); // refresh empty-state hint that reads _searchCtrl.text
    _applyFilter(
      type: _typeFilter,
      categoryIds: _categoryFilters,
      from: _from,
      to: _to,
      search: query.trim().isEmpty ? null : query.trim(),
    );
  }

  void _clearSearch() {
    _searchCtrl.clear();
    setState(() => _searchActive = false);
    _applyFilter(
      type: _typeFilter,
      categoryIds: _categoryFilters,
      from: _from,
      to: _to,
    );
  }

  bool get _hasActiveFilters =>
      _categoryFilters.isNotEmpty || _from != null || _to != null;

  void _showFilterSheet(BuildContext context, List<CategoryModel> categories) {
    // Local state copies for the sheet
    TransactionType? sheetType = _typeFilter;
    List<String> sheetCats = List.of(_categoryFilters);
    DateTime? sheetFrom = _from;
    DateTime? sheetTo = _to;

    showModalBottomSheet(
      useRootNavigator: true,
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 20, 24, MediaQuery.of(ctx).viewInsets.bottom + 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.cream300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Filters', style: AppTypography.headingMedium),
                  TextButton(
                    onPressed: () {
                      setSheet(() {
                        sheetType = null;
                        sheetCats = [];
                        sheetFrom = null;
                        sheetTo = null;
                      });
                    },
                    child: const Text('Reset'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Type
              const Text('TYPE', style: AppTypography.eyebrow),
              const SizedBox(height: 10),
              Row(
                children: [
                  _FilterPill(
                    label: 'All',
                    active: sheetType == null,
                    onTap: () => setSheet(() => sheetType = null),
                  ),
                  const SizedBox(width: 8),
                  _FilterPill(
                    label: 'Expenses',
                    active: sheetType == TransactionType.expense,
                    onTap: () =>
                        setSheet(() => sheetType = TransactionType.expense),
                  ),
                  const SizedBox(width: 8),
                  _FilterPill(
                    label: 'Income',
                    active: sheetType == TransactionType.income,
                    onTap: () =>
                        setSheet(() => sheetType = TransactionType.income),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Category — multi-select chips
              if (categories.isNotEmpty) ...[
                const Text('CATEGORY', style: AppTypography.eyebrow),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: categories.map((cat) {
                    final selected = sheetCats.contains(cat.id);
                    Color catColor;
                    try {
                      catColor = Color(int.parse(
                          'FF${cat.color.replaceAll('#', '')}',
                          radix: 16));
                    } catch (_) {
                      catColor = AppColors.stone500;
                    }
                    return GestureDetector(
                      onTap: () => setSheet(() {
                        if (selected) {
                          sheetCats = sheetCats
                              .where((id) => id != cat.id)
                              .toList();
                        } else {
                          sheetCats = [...sheetCats, cat.id];
                        }
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.ink : AppColors.cream100,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: selected
                                ? AppColors.ink
                                : AppColors.borderHair,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppColors.paper.withValues(alpha: 0.25)
                                    : catColor,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Icon(
                                  CategoryIcon.resolve(cat.icon),
                                  size: 10,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              cat.name,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: selected
                                    ? AppColors.paper
                                    : AppColors.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
              ],

              // Date range
              const Text('DATE RANGE', style: AppTypography.eyebrow),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _DatePickerButton(
                      label: 'From',
                      date: sheetFrom,
                      onPick: (d) => setSheet(() => sheetFrom = d),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DatePickerButton(
                      label: 'To',
                      date: sheetTo,
                      onPick: (d) => setSheet(() => sheetTo = d),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Apply
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.ink,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    setState(() {
                      _typeFilter = sheetType;
                      _categoryFilters = List.of(sheetCats);
                      _from = sheetFrom;
                      _to = sheetTo;
                    });
                    _applyFilter(
                      type: sheetType,
                      categoryIds: sheetCats,
                      from: sheetFrom,
                      to: sheetTo,
                      search: _searchCtrl.text.trim().isEmpty
                          ? null
                          : _searchCtrl.text.trim(),
                    );
                    Navigator.pop(ctx);
                  },
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
        title: _searchActive
            ? SizedBox(
          height: 40,
          child: TextField(
            controller: _searchCtrl,
            autofocus: true,
            onChanged: _onSearch,
            style: AppTypography.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Search transactions…',
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
              filled: true,
              // Make sure this color exists and contrasts with your AppBar
              fillColor: AppColors.cream200,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),

              // 1. Default border
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: BorderSide.none,
              ),
              // 2. Border when not selected
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: BorderSide.none,
              ),
              // 3. Border when you are actively typing inside it
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        )
            : Text('Activity', style: AppTypography.headingLarge),
        leading: IconButton(
          icon: Icon(_searchActive ? Icons.close : Icons.search),
          onPressed: () {
            if (_searchActive) {
              _clearSearch();
            } else {
              setState(() => _searchActive = true);
            }
          },
        ),
        actions: [
          Builder(
            builder: (ctx) => Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.tune_outlined),
                  onPressed: () {
                    final catState =
                        context.read<CategoryBloc>().state;
                    final cats = catState is CategoryLoaded
                        ? catState.categories
                        : <CategoryModel>[];
                    _showFilterSheet(context, cats);
                  },
                ),
                if (_hasActiveFilters)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type filter chips
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              children: [
                _FilterPill(
                  label: 'All',
                  active: _typeFilter == null,
                  onTap: () => _onTypeChip(null),
                ),
                const SizedBox(width: 8),
                _FilterPill(
                  label: 'Expenses',
                  active: _typeFilter == TransactionType.expense,
                  onTap: () => _onTypeChip(TransactionType.expense),
                ),
                const SizedBox(width: 8),
                _FilterPill(
                  label: 'Income',
                  active: _typeFilter == TransactionType.income,
                  onTap: () => _onTypeChip(TransactionType.income),
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
                      title: _typeFilter != null ||
                              _hasActiveFilters ||
                              _searchCtrl.text.isNotEmpty
                          ? 'No results found'
                          : 'No transactions yet',
                      description: _typeFilter != null ||
                              _hasActiveFilters ||
                              _searchCtrl.text.isNotEmpty
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
                        padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom),
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
                                Text(
                                  label.toUpperCase(),
                                  style: AppTypography.eyebrow,
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  clipBehavior: Clip.antiAlias,
                                  decoration: BoxDecoration(
                                    color: AppColors.cream50,
                                    borderRadius:
                                        BorderRadius.circular(16),
                                    border: Border.all(
                                        color: AppColors.borderHair),
                                  ),
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
                                          position: DecorationPosition.foreground,
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
      floatingActionButton: MediaQuery.of(context).viewInsets.bottom > 0
          ? null
          : Transform.translate(
              offset: const Offset(0, 16),
              child: FloatingActionButton.extended(
                heroTag: 'txn_list_fab',
                onPressed: () => context.go('/transactions/add'),
                backgroundColor: AppColors.orange,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.add),
                label: const Text('Add'),
              ),
            ),
    );
  }
}

// ── Filter pill ────────────────────────────────────────────────

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

// ── Date picker button ─────────────────────────────────────────

class _DatePickerButton extends StatelessWidget {
  final String label;
  final DateTime? date;
  final ValueChanged<DateTime?> onPick;

  const _DatePickerButton({
    required this.label,
    required this.date,
    required this.onPick,
  });

  String get _display {
    if (date == null) return label;
    return '${date!.day}/${date!.month}/${date!.year}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
        );
        if (picked != null) onPick(picked);
      },
      onLongPress: date != null ? () => onPick(null) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: date != null ? AppColors.ink : AppColors.cream50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderHair),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 14,
              color: date != null ? AppColors.paper : AppColors.stone500,
            ),
            const SizedBox(width: 6),
            Text(
              _display,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: date != null ? AppColors.paper : AppColors.stone500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

