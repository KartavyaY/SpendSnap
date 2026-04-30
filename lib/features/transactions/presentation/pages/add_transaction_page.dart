import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../categories/domain/category_model.dart';
import '../../../categories/presentation/bloc/category_bloc.dart';
import '../../../categories/presentation/bloc/category_state.dart';
import '../../domain/transaction_model.dart';
import '../bloc/transaction_bloc.dart';
import '../bloc/transaction_event.dart';
import '../bloc/transaction_state.dart';

class AddTransactionPage extends StatefulWidget {
  final String? editId;
  const AddTransactionPage({super.key, this.editId});

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
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CategoryBloc, CategoryState>(
      builder: (context, catState) {
        final categories =
            catState is CategoryLoaded ? catState.categories : <CategoryModel>[];

        // Init edit mode
        if (widget.editId != null && !_initialized) {
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
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(
                widget.editId != null ? 'Edit Transaction' : 'Add Transaction'),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => context.pop(),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type toggle
                  Row(
                    children: [
                      Expanded(
                        child: _TypeButton(
                          label: 'Expense',
                          icon: Icons.arrow_downward,
                          selected: _type == TransactionType.expense,
                          color: AppColors.danger,
                          onTap: () =>
                              setState(() => _type = TransactionType.expense),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _TypeButton(
                          label: 'Income',
                          icon: Icons.arrow_upward,
                          selected: _type == TransactionType.income,
                          color: AppColors.success,
                          onTap: () =>
                              setState(() => _type = TransactionType.income),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Amount
                  TextFormField(
                    controller: _amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      prefixText: '₹ ',
                    ),
                    validator: Validators.amount,
                  ),
                  const SizedBox(height: 16),

                  // Category dropdown
                  DropdownButtonFormField<CategoryModel>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: categories
                        .map((c) => DropdownMenuItem(
                              value: c,
                              child: Row(
                                children: [
                                  Text(c.icon),
                                  const SizedBox(width: 8),
                                  Text(c.name),
                                ],
                              ),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedCategory = v),
                    validator: (_) =>
                        _selectedCategory == null ? 'Select a category' : null,
                  ),
                  const SizedBox(height: 16),

                  // Date picker
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
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        prefixIcon: Icon(Icons.calendar_today_outlined),
                        suffixIcon: Icon(Icons.arrow_drop_down),
                      ),
                      child: Text(AppDateUtils.formatDay(_date)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Note
                  TextFormField(
                    controller: _noteCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Note (optional)',
                      prefixIcon: Icon(Icons.notes_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Recurring toggle
                  SwitchListTile(
                    value: _isRecurring,
                    onChanged: (v) => setState(() => _isRecurring = v),
                    title: const Text('Recurring'),
                    subtitle: const Text('Repeat this transaction automatically'),
                    contentPadding: EdgeInsets.zero,
                    activeColor: AppColors.primary,
                  ),

                  if (_isRecurring) ...[
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _recurringFreq,
                      decoration:
                          const InputDecoration(labelText: 'Frequency'),
                      items: const [
                        DropdownMenuItem(
                            value: 'weekly', child: Text('Weekly')),
                        DropdownMenuItem(
                            value: 'monthly', child: Text('Monthly')),
                      ],
                      onChanged: (v) =>
                          setState(() => _recurringFreq = v),
                    ),
                  ],

                  const SizedBox(height: 32),

                  PrimaryButton(
                    label: widget.editId != null
                        ? 'Update Transaction'
                        : 'Add Transaction',
                    onPressed: _submit,
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
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: selected ? color : AppColors.textTertiary),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.label.copyWith(
                color: selected ? color : AppColors.textSecondary,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
