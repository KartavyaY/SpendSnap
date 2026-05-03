import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/category_icon.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../categories/domain/category_model.dart';
import '../../../categories/presentation/bloc/category_bloc.dart';
import '../../../categories/presentation/bloc/category_state.dart';
import '../../../transactions/domain/receipt_prefill.dart';
import '../../domain/parsed_receipt.dart';

class ReceiptReviewCard extends StatefulWidget {
  final ParsedReceipt result;
  final File image;
  final VoidCallback onRetake;

  const ReceiptReviewCard({
    super.key,
    required this.result,
    required this.image,
    required this.onRetake,
  });

  @override
  State<ReceiptReviewCard> createState() => _ReceiptReviewCardState();
}

class _ReceiptReviewCardState extends State<ReceiptReviewCard> {
  late final TextEditingController _amountCtrl;
  late final TextEditingController _merchantCtrl;
  late DateTime _date;
  CategoryModel? _selectedCategory;
  bool _categoryInited = false;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(
      text: widget.result.amount?.toStringAsFixed(2) ?? '',
    );
    _merchantCtrl =
        TextEditingController(text: widget.result.merchant ?? '');
    _date = widget.result.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _merchantCtrl.dispose();
    super.dispose();
  }

  void _initCategory(List<CategoryModel> cats) {
    if (_categoryInited || cats.isEmpty) return;
    final hint = widget.result.categoryHint;
    if (hint != null) {
      _selectedCategory = cats.firstWhere(
        (c) => c.icon == hint,
        orElse: () => cats.firstWhere(
          (c) => c.icon == 'other',
          orElse: () => cats.first,
        ),
      );
    }
    _categoryInited = true;
  }

  void _useThis() {
    final amount = double.tryParse(_amountCtrl.text.trim());
    final merchant =
        _merchantCtrl.text.trim().isEmpty ? null : _merchantCtrl.text.trim();
    context.go('/transactions/add', extra: ReceiptPrefill(
      amount: amount,
      date: _date,
      merchant: merchant,
      categoryHint: _selectedCategory?.icon,
    ));
  }

  Color _confidenceColor(double c) {
    if (c >= 0.75) return AppColors.success;
    if (c >= 0.25) return AppColors.warn;
    return AppColors.danger;
  }

  String _confidenceLabel(double c) {
    if (c >= 0.75) return 'High confidence';
    if (c >= 0.25) return 'Partial match';
    return 'Low confidence — please review';
  }

  Color _parseColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return AppColors.stone500;
    }
  }

  // Icons + name fragments that represent income — never valid for receipts.
  static const _incomeIcons = {'salary'};
  static const _incomeNameFragments = {'salary', 'income', 'wage', 'bonus'};

  static bool _isIncomeCategory(CategoryModel c) {
    if (_incomeIcons.contains(c.icon.toLowerCase().trim())) return true;
    final name = c.name.toLowerCase();
    return _incomeNameFragments.any(name.contains);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CategoryBloc, CategoryState>(
      builder: (context, catState) {
        final allCategories = catState is CategoryLoaded
            ? catState.categories
            : <CategoryModel>[];
        // Receipts are always expenses — filter income categories out.
        final categories =
            allCategories.where((c) => !_isIncomeCategory(c)).toList();
        _initCategory(categories);

        final confColor = _confidenceColor(widget.result.confidence);
        final confLabel = _confidenceLabel(widget.result.confidence);

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo + retake row
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      widget.image,
                      width: 120,
                      height: 160,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: confColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                                color: confColor.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            confLabel,
                            style: AppTypography.caption.copyWith(
                              color: confColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: widget.onRetake,
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('Retake'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text('WE FOUND', style: AppTypography.eyebrow),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.cream50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderHair),
                ),
                child: Column(
                  children: [
                    // Amount
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: TextFormField(
                        controller: _amountCtrl,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Amount',
                          prefixText: '₹ ',
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
                    // Date
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _date,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() => _date = picked);
                        }
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
                    // Merchant / note
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      child: TextFormField(
                        controller: _merchantCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Merchant / note',
                          prefixIcon: Icon(Icons.store_outlined, size: 18),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (categories.isNotEmpty) ...[
                const Text('CATEGORY', style: AppTypography.eyebrow),
                const SizedBox(height: 10),
                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final cat = categories[i];
                      final isSelected = _selectedCategory?.id == cat.id;
                      final catColor = _parseColor(cat.color);
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedCategory = cat),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.ink
                                : AppColors.cream100,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.ink
                                  : AppColors.borderHair,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 22,
                                height: 22,
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
                                    size: 12,
                                    color: isSelected
                                        ? AppColors.paper
                                        : Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                cat.name,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: isSelected
                                      ? AppColors.paper
                                      : AppColors.ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],
              // Action row
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _useThis,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    foregroundColor: AppColors.paper,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Use this',
                    style: AppTypography.label.copyWith(
                      color: AppColors.paper,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go('/transactions/add'),
                child: Text(
                  'Enter manually instead',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
