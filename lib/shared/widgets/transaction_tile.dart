import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/category_icon.dart';
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
    final sign = isIncome ? '+' : '-';
    final amountColor = isIncome ? AppColors.success : AppColors.ink;

    final subtitle =
        '${category?.name ?? 'Unknown'} · ${AppDateUtils.formatRelative(transaction.date)}';

    Widget tile = InkWell(
      key: ValueKey(transaction.id),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            // Category dot
            _CategoryIcon(category: category),
            const SizedBox(width: 12),
            // Name + subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.note != null && transaction.note!.isNotEmpty
                        ? transaction.note!
                        : (category?.name ?? 'Unknown'),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.ink,
                      height: 1.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.stone600,
                      height: 1.4,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Amount in JetBrains Mono
            Text(
              '$sign${CurrencyFormatter.format(transaction.amount)}',
              style: AppTypography.moneyBody.copyWith(
                color: amountColor,
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
              content: const Text('This action cannot be undone.'),
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
            color: AppColors.dangerBg,
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

  const _CategoryIcon({required this.category});

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
    final color = category != null
        ? _parseColor(category!.color)
        : AppColors.stone500;

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          CategoryIcon.resolve(category?.icon ?? 'salary'),
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }
}
