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

  // Income-only icons — never selectable from a receipt prefill.
  static const _incomeIcons = {'salary'};

  void _initFromPrefill(ReceiptPrefill p, List<CategoryModel> cats) {
    if (p.amount != null) _amountCtrl.text = p.amount!.toStringAsFixed(2);
    if (p.date != null) _date = p.date!;
    if (p.merchant != null && p.merchant!.isNotEmpty) {
      _noteCtrl.text = p.merchant!;
    }
    // Receipts are always expenses — restrict prefill match to expense cats.
    final expenseCats =
        cats.where((c) => !_incomeIcons.contains(c.icon)).toList();
    if (p.categoryHint != null &&
        !_incomeIcons.contains(p.categoryHint) &&
        expenseCats.isNotEmpty) {
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

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) return;

    final txn = TransactionModel(
      id: _editingTransaction?.id ?? const Uuid().v4(),
      uid: authState.user.uid,
      amount: double.parse(_amountCtrl.text.trim()),
      type: _type,
      categoryId: _selectedCategory!.id,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
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
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
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
                            // Clear stale category when switching type
                            if (_selectedCategory != null &&
                                _incomeIcons
                                    .contains(_selectedCategory!.icon)) {
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
                          onTap: () => setState(() {
                            _type = TransactionType.income;
                            if (_selectedCategory != null &&
                                !_incomeIcons
                                    .contains(_selectedCategory!.icon)) {
                              _selectedCategory = null;
                            }
                          }),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Category grid — filtered by transaction type.
                  // Expense types hide income-only icons; income shows only income cats.
                  Builder(builder: (_) {
                    final filteredCategories = _type == TransactionType.income
                        ? categories
                            .where((c) => _incomeIcons.contains(c.icon))
                            .toList()
                        : categories
                            .where((c) => !_incomeIcons.contains(c.icon))
                            .toList();
                    return filteredCategories.isEmpty
                        ? const SizedBox.shrink()
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('CATEGORY',
                                  style: AppTypography.eyebrow),
                              const SizedBox(height: 10),
                              GridView.builder(
                                shrinkWrap: true,
                                physics:
                                    const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  childAspectRatio: 1.8,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                ),
                                itemCount: filteredCategories.length,
                                itemBuilder: (_, i) {
                                  final cat = filteredCategories[i];
                        final isSelected = _selectedCategory?.id == cat.id;
                        final catColor = _parseColor(cat.color);
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedCategory = cat),
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
                                        ? AppColors.paper.withValues(alpha: 0.2)
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
                              const SizedBox(height: 20),
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
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                            child: DropdownButtonFormField<String>(
                              initialValue: _recurringFreq,
                              decoration: const InputDecoration(
                                labelText: 'Frequency',
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                filled: false,
                              ),
                              items: const [
                                DropdownMenuItem(
                                    value: 'daily', child: Text('Daily')),
                                DropdownMenuItem(
                                    value: 'weekly', child: Text('Weekly')),
                                DropdownMenuItem(
                                    value: 'monthly',
                                    child: Text('Monthly')),
                              ],
                              onChanged: (v) =>
                                  setState(() => _recurringFreq = v),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Save button
                  SizedBox(
                    width: double.infinity,
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
                ],
              ),
            ),
          ),
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
