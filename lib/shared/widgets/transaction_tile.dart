import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_utils.dart';
import '../../features/categories/domain/category_model.dart';
import '../../features/transactions/domain/transaction_model.dart';

class TransactionTile extends StatelessWidget {
  final TransactionModel transaction;
  final CategoryModel? category;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final bool dense;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.category,
    this.onTap,
    this.onDelete,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionType.income;
    final amountColor =
        isIncome ? AppColors.success : AppColors.danger;
    final sign = isIncome ? '+' : '-';

    Widget tile = InkWell(
      key: ValueKey(transaction.id),
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: dense ? 8 : 12,
        ),
        child: Row(
          children: [
            // Category icon circle
            _CategoryIcon(category: category, dense: dense),
            const SizedBox(width: 12),
            // Name + note + date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category?.name ?? 'Unknown',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (transaction.note != null &&
                      transaction.note!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      transaction.note!,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 2),
                  Text(
                    AppDateUtils.formatRelative(transaction.date),
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            // Amount
            Text(
              '$sign${CurrencyFormatter.format(transaction.amount)}',
              style: AppTypography.bodyMedium.copyWith(
                color: amountColor,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );

    if (onDelete != null) {
      tile = Dismissible(
        key: ValueKey('dismiss_${transaction.id}'),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => onDelete!(),
        confirmDismiss: (direction) async {
          return await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Delete transaction?'),
              content:
                  const Text('This action cannot be undone.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.danger,
                  ),
                  child: const Text('Delete'),
                ),
              ],
            ),
          );
        },
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: AppColors.danger.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.delete_outline, color: AppColors.danger),
        ),
        child: tile,
      );
    }

    return tile;
  }
}

class _CategoryIcon extends StatelessWidget {
  final CategoryModel? category;
  final bool dense;

  const _CategoryIcon({required this.category, required this.dense});

  Color _parseColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return AppColors.textTertiary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = dense ? 36.0 : 44.0;
    final color = category != null ? _parseColor(category!.color) : AppColors.textTertiary;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(size / 3),
      ),
      child: Center(
        child: Text(
          category?.icon ?? '💰',
          style: TextStyle(fontSize: dense ? 16 : 20),
        ),
      ),
    );
  }
}
