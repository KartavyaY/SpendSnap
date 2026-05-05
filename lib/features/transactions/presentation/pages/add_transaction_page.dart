import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/category_icon.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/validators.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../categories/domain/category_model.dart';
import '../../../categories/presentation/bloc/category_bloc.dart';
import '../../../categories/presentation/bloc/category_state.dart';
import '../../../categories/presentation/pages/categories_page.dart';
import '../../domain/receipt_prefill.dart';
import '../../domain/transaction_model.dart';
import '../bloc/transaction_bloc.dart';
import '../bloc/transaction_event.dart';
import '../bloc/transaction_state.dart';

class AddTransactionPage extends StatefulWidget {
  final String? editId;
  final ReceiptPrefill? prefill;
  const AddTransactionPage({super.key, this.editId, this.prefill});

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  TransactionType _type = TransactionType.expense;
  CategoryModel? _selectedCategory;
  DateTime _date = DateTime.now();
  bool _isRecurring = false;
  String? _recurringFreq;

  TransactionModel? _editingTransaction;
  bool _initialized = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _initEdit(TransactionModel txn) {
    _amountCtrl.text = txn.amount.toString();
    _noteCtrl.text = txn.note ?? '';
    _type = txn.type;
    _date = txn.date;
    _isRecurring = txn.isRecurring;
    _recurringFreq = txn.recurringFrequency;
    _editingTransaction = txn;
    _initialized = true;
  }

  void _initFromPrefill(ReceiptPrefill p, List<CategoryModel> cats) {
    if (p.amount != null) _amountCtrl.text = p.amount!.toStringAsFixed(2);
    if (p.date != null) _date = p.date!;
    if (p.merchant != null && p.merchant!.isNotEmpty) {
      _noteCtrl.text = p.merchant!;
    }
    // Receipts are always expenses — restrict prefill match to expense cats.
    final expenseCats = cats.where((c) => !c.isIncome).toList();
    if (p.categoryHint != null && expenseCats.isNotEmpty) {
      _selectedCategory = expenseCats.firstWhere(
        (c) => c.icon == p.categoryHint,
        orElse: () => expenseCats.firstWhere(
          (c) => c.icon == 'other',
          orElse: () => expenseCats.first,
        ),
      );
    }
    _type = TransactionType.expense; // receipts always expenses
    _initialized = true;
  }

  bool _isDuplicate(double amount, String categoryId, String? note) {
    final txnState = context.read<TransactionBloc>().state;
    if (txnState is! TransactionLoaded) return false;
    final normalizedNote = note?.trim().toLowerCase();
    return txnState.transactions.any((t) {
      if (t.amount != amount) return false;
      if (t.categoryId != categoryId) return false;
      if (t.date.year != _date.year ||
          t.date.month != _date.month ||
          t.date.day != _date.day) {
        return false;
      }
      // Different merchants on same day = not a duplicate
      final tNote = t.note?.trim().toLowerCase();
      if (normalizedNote != null &&
          tNote != null &&
          normalizedNote != tNote) {
        return false;
      }
      return true;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) return;

    final amount = double.parse(_amountCtrl.text.trim());
    final categoryId = _selectedCategory!.id;

    final note = _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim();

    // Dupe check only for scanned receipts (not manual entry)
    if (_editingTransaction == null &&
        widget.prefill != null &&
        _isDuplicate(amount, categoryId, note)) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Possible duplicate'),
          content: const Text(
            'A transaction with the same amount, category, and date already exists. Add it anyway?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: AppColors.orange),
              child: const Text('Add anyway'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    if (!mounted) return;

    final txn = TransactionModel(
      id: _editingTransaction?.id ?? const Uuid().v4(),
      uid: authState.user.uid,
      amount: amount,
      type: _type,
      categoryId: categoryId,
      note: note,
      date: _date,
      isRecurring: _isRecurring,
      recurringFrequency: _isRecurring ? _recurringFreq : null,
    );

    if (_editingTransaction != null) {
      context.read<TransactionBloc>().add(UpdateTransaction(txn));
    } else {
      context.read<TransactionBloc>().add(AddTransaction(txn));
    }
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/transactions');
    }
  }

  static const _freqOptions = [
    ('daily', 'Daily', Icons.wb_sunny_outlined),
    ('weekly', 'Weekly', Icons.view_week_outlined),
    ('monthly', 'Monthly', Icons.calendar_month_outlined),
  ];

  String _freqLabel(String v) =>
      _freqOptions.firstWhere((e) => e.$1 == v, orElse: () => (v, v, Icons.repeat)).$2;

  void _pickFrequency(BuildContext ctx) {
    showModalBottomSheet(
      useRootNavigator: true,
      context: ctx,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.cream300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text('Frequency', style: AppTypography.headingMedium),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: AppColors.cream50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderHair),
              ),
              child: Column(
                children: List.generate(_freqOptions.length, (i) {
                  final (value, label, icon) = _freqOptions[i];
                  final selected = _recurringFreq == value;
                  final isLast = i == _freqOptions.length - 1;
                  return Column(
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.vertical(
                          top: i == 0 ? const Radius.circular(16) : Radius.zero,
                          bottom: isLast ? const Radius.circular(16) : Radius.zero,
                        ),
                        onTap: () {
                          setState(() => _recurringFreq = value);
                          Navigator.pop(ctx);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          child: Row(
                            children: [
                              Icon(icon,
                                  size: 18,
                                  color: selected
                                      ? AppColors.orange
                                      : AppColors.stone600),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  label,
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: selected
                                        ? AppColors.orange
                                        : AppColors.ink,
                                    fontWeight: selected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                ),
                              ),
                              if (selected)
                                const Icon(Icons.check,
                                    size: 18, color: AppColors.orange),
                            ],
                          ),
                        ),
                      ),
                      if (!isLast)
                        const Divider(
                            height: 1,
                            thickness: 1,
                            indent: 16,
                            endIndent: 16,
                            color: AppColors.borderHair),
                    ],
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _parseColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return AppColors.stone500;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CategoryBloc, CategoryState>(
      builder: (context, catState) {
        final categories =
            catState is CategoryLoaded ? catState.categories : <CategoryModel>[];

        // Init edit mode or prefill mode (one-time)
        if (!_initialized) {
          if (widget.editId != null) {
            final txnState = context.read<TransactionBloc>().state;
            if (txnState is TransactionLoaded) {
              final txn = txnState.transactions.firstWhere(
                (t) => t.id == widget.editId,
                orElse: () => throw StateError('Transaction not found'),
              );
              _initEdit(txn);
              _selectedCategory = categories.firstWhere(
                (c) => c.id == txn.categoryId,
                orElse: () => categories.first,
              );
            }
          } else if (widget.prefill != null) {
            _initFromPrefill(widget.prefill!, categories);
          }
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(
              widget.editId != null ? 'Edit transaction' : 'New transaction',
            ),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/transactions');
                }
              },
            ),
          ),
          body: Builder(builder: (context) {
            // padding.bottom = pillHeight (set by MainShell overlay).
            // Button sits 16px above the pill's top edge.
            // Sit just above pill: scrollClearance = pillHeight + 24, want ~8px above pill.
            final btnBottom = MediaQuery.of(context).padding.bottom - 16;
            return Stack(
              children: [
                SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, btnBottom + 52 + 8),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Amount section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 24, horizontal: 20),
                    decoration: BoxDecoration(
                      color: AppColors.cream50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderHair),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'AMOUNT',
                          style: AppTypography.eyebrow,
                        ),
                        const SizedBox(height: 12),
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            TextFormField(
                              controller: _amountCtrl,
                              keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true),
                              textAlign: TextAlign.center,
                              style: AppTypography.moneyDisplay(48),
                              decoration: const InputDecoration(
                                hintText: '0',
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                filled: false,
                                contentPadding: EdgeInsets.zero,
                              ),
                              validator: Validators.amount,
                            ),
                            Positioned(
                              left: 0,
                              child: Text(
                                '₹',
                                style: AppTypography.moneyDisplay(48).copyWith(
                                  color: Colors.black45,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Type toggle
                  Row(
                    children: [
                      Expanded(
                        child: _TypeButton(
                          label: 'Expense',
                          selected: _type == TransactionType.expense,
                          onTap: () => setState(() {
                            _type = TransactionType.expense;
                            // Clear category if it's income-only
                            if (_selectedCategory != null &&
                                _selectedCategory!.isIncome) {
                              _selectedCategory = null;
                            }
                          }),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _TypeButton(
                          label: 'Income',
                          selected: _type == TransactionType.income,
                          onTap: () {
                            final incomeCats = categories
                                .where((c) => c.isIncome)
                                .toList();
                            setState(() {
                              _type = TransactionType.income;
                              _selectedCategory = incomeCats.isNotEmpty
                                  ? incomeCats.first
                                  : null;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Category grid — filtered by transaction type.
                  Builder(builder: (gridCtx) {
                    final filteredCategories = _type == TransactionType.income
                        ? categories.where((c) => c.isIncome).toList()
                        : categories.where((c) => !c.isIncome).toList();

                    // Auto-select income category when none is selected
                    // (covers edit-mode load and initial income selection)
                    if (_type == TransactionType.income &&
                        filteredCategories.isNotEmpty &&
                        (_selectedCategory == null ||
                            !filteredCategories
                                .any((c) => c.id == _selectedCategory!.id))) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(
                              () => _selectedCategory = filteredCategories.first);
                        }
                      });
                    }

                    void showAddCategorySheet() {
                      final catBloc = context.read<CategoryBloc>();
                      final authBloc = context.read<AuthBloc>();
                      showModalBottomSheet(
                        useRootNavigator: true,
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: AppColors.paper,
                        shape: const RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(24)),
                        ),
                        builder: (_) => BlocProvider.value(
                          value: catBloc,
                          child: BlocProvider.value(
                            value: authBloc,
                            child: CategoryFormSheet(
                              initialIsIncome:
                                  _type == TransactionType.income,
                            ),
                          ),
                        ),
                      );
                    }

                    void showEditCategorySheet(CategoryModel cat) {
                      final catBloc = context.read<CategoryBloc>();
                      final authBloc = context.read<AuthBloc>();
                      showModalBottomSheet(
                        useRootNavigator: true,
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: AppColors.paper,
                        shape: const RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(24)),
                        ),
                        builder: (_) => BlocProvider.value(
                          value: catBloc,
                          child: BlocProvider.value(
                            value: authBloc,
                            child: CategoryFormSheet(editing: cat),
                          ),
                        ),
                      );
                    }

                    // itemCount + 1 for the "+ Add category" tile
                    final totalItems = filteredCategories.length + 1;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('CATEGORY', style: AppTypography.eyebrow),
                        const SizedBox(height: 10),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.zero,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 1.8,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: totalItems,
                          itemBuilder: (_, i) {
                            // Last tile = "+ Add category"
                            if (i == filteredCategories.length) {
                              return GestureDetector(
                                onTap: showAddCategorySheet,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppColors.cream100,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.borderHair,
                                      style: BorderStyle.solid,
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add,
                                          size: 14,
                                          color: AppColors.stone600),
                                      SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          'Add',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.stone600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            final cat = filteredCategories[i];
                            final isSelected = _selectedCategory?.id == cat.id;
                            final catColor = _parseColor(cat.color);
                            return GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () =>
                                  setState(() => _selectedCategory = cat),
                              onLongPress: () => showEditCategorySheet(cat),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.ink
                                      : AppColors.cream100,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.ink
                                        : AppColors.borderHair,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppColors.paper
                                                .withValues(alpha: 0.2)
                                            : catColor,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Icon(
                                          CategoryIcon.resolve(cat.icon),
                                          size: 13,
                                          color: isSelected
                                              ? AppColors.paper
                                              : Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        cat.name,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: isSelected
                                              ? AppColors.paper
                                              : AppColors.ink,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                      ],
                    );
                  }),

                  // Details card
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.cream50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderHair),
                    ),
                    child: Column(
                      children: [
                        // Note field
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                          child: TextFormField(
                            controller: _noteCtrl,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              hintText: 'Note (optional)',
                              prefixIcon:
                                  Icon(Icons.notes_outlined, size: 18),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                            ),
                          ),
                        ),
                        const Divider(
                            height: 1,
                            thickness: 1,
                            color: AppColors.borderHair),
                        // Date picker row
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _date,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) setState(() => _date = picked);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_outlined,
                                    size: 18, color: AppColors.stone600),
                                const SizedBox(width: 12),
                                Text(
                                  AppDateUtils.formatDay(_date),
                                  style: AppTypography.bodyMedium,
                                ),
                                const Spacer(),
                                const Icon(Icons.chevron_right,
                                    size: 18, color: AppColors.stone500),
                              ],
                            ),
                          ),
                        ),
                        const Divider(
                            height: 1,
                            thickness: 1,
                            color: AppColors.borderHair),
                        // Recurring toggle
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          child: SwitchListTile(
                            value: _isRecurring,
                            onChanged: (v) =>
                                setState(() => _isRecurring = v),
                            title: const Text('Recurring'),
                            subtitle: const Text(
                                'Repeat this transaction automatically'),
                            contentPadding: EdgeInsets.zero,
                            activeThumbColor: AppColors.orange,
                          ),
                        ),
                        if (_isRecurring) ...[
                          const Divider(
                              height: 1,
                              thickness: 1,
                              color: AppColors.borderHair),
                          InkWell(
                            onTap: () => _pickFrequency(context),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              child: Row(
                                children: [
                                  const Icon(Icons.repeat,
                                      size: 18, color: AppColors.stone600),
                                  const SizedBox(width: 12),
                                  Text(
                                    _recurringFreq != null
                                        ? _freqLabel(_recurringFreq!)
                                        : 'Select frequency',
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: _recurringFreq != null
                                          ? AppColors.ink
                                          : AppColors.stone500,
                                    ),
                                  ),
                                  const Spacer(),
                                  const Icon(Icons.chevron_right,
                                      size: 18, color: AppColors.stone500),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                ],
              ),
            ),
          ),
                // Floating button
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: btnBottom,
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.orange,
                        foregroundColor: AppColors.paper,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        widget.editId != null
                            ? 'Update transaction'
                            : 'Save transaction',
                        style: AppTypography.label.copyWith(
                          color: AppColors.paper,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
        );
      },
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 40,
        decoration: BoxDecoration(
          color: selected ? AppColors.ink : AppColors.cream200,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: selected ? AppColors.paper : AppColors.stone600,
            ),
          ),
        ),
      ),
    );
  }
}
