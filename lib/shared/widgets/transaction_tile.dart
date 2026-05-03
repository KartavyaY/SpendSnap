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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
      return _SwipeToRevealDelete(
        key: ValueKey('swipe_${transaction.id}'),
        onDelete: onDelete!,
        child: tile,
      );
    }

    return tile;
  }
}

class _SwipeToRevealDelete extends StatefulWidget {
  final Widget child;
  final VoidCallback onDelete;

  const _SwipeToRevealDelete({
    super.key,
    required this.child,
    required this.onDelete,
  });

  @override
  State<_SwipeToRevealDelete> createState() => _SwipeToRevealDeleteState();
}

class _SwipeToRevealDeleteState extends State<_SwipeToRevealDelete>
    with SingleTickerProviderStateMixin {
  static const _revealWidth = 64.0;
  late final AnimationController _ctrl;
  late Animation<double> _offsetAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _offsetAnim = Tween<double>(begin: 0, end: 0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  double _dragStart = 0;
  double _currentOffset = 0;

  void _onDragStart(DragStartDetails d) {
    _dragStart = d.localPosition.dx;
  }

  void _onDragUpdate(DragUpdateDetails d) {
    final delta = d.localPosition.dx - _dragStart;
    final raw = (_currentOffset + delta).clamp(double.negativeInfinity, 0.0);
    double effective;
    if (raw < -_revealWidth) {
      // Rubber band: dampen drag past the reveal point
      final overshoot = raw + _revealWidth;
      effective = -_revealWidth + overshoot * 0.3;
    } else {
      effective = raw;
    }
    _offsetAnim = AlwaysStoppedAnimation(effective);
    setState(() {});
  }

  void _onDragEnd(DragEndDetails d) {
    final raw = _offsetAnim.value;
    if (raw < -_revealWidth / 2) {
      _snap(-_revealWidth); // snap to open (rubber band snaps back here too)
    } else {
      _snap(0);
    }
  }

  void _snap(double target) {
    final from = _offsetAnim.value;
    final opening = target < 0;
    _ctrl.duration = Duration(milliseconds: opening ? 320 : 200);
    _offsetAnim = Tween<double>(begin: from, end: target).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: opening ? Curves.easeOutBack : Curves.easeOut,
      ),
    );
    _ctrl.forward(from: 0).then((_) => _currentOffset = target);
    setState(() {});
  }

  void _close() => _snap(0);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Fallback for unbounded contexts — render tile without swipe.
        if (!constraints.hasBoundedWidth) return widget.child;
        final tileWidth = constraints.maxWidth;
        return ClipRect(
          child: AnimatedBuilder(
            animation: _offsetAnim,
            builder: (context, _) {
              final offset = _offsetAnim.value;
              final isOpen = offset < 0;
              return TapRegion(
                consumeOutsideTaps: isOpen,
                onTapOutside: isOpen ? (_) => _close() : null,
                child: Stack(
                  children: [
                    // Tile — non-positioned so Stack sizes to its height.
                    // Forced to exactly tileWidth via SizedBox.
                    Transform.translate(
                      offset: Offset(offset, 0),
                      child: SizedBox(
                        width: tileWidth,
                        child: GestureDetector(
                          onHorizontalDragStart: _onDragStart,
                          onHorizontalDragUpdate: _onDragUpdate,
                          onHorizontalDragEnd: _onDragEnd,
                          onTap: isOpen ? _close : null,
                          behavior: HitTestBehavior.translucent,
                          child: widget.child,
                        ),
                      ),
                    ),
                    // Delete button — sits at the right edge of the tile.
                    // At rest (offset=0), it's at left: tileWidth → outside ClipRect.
                    Positioned(
                      left: tileWidth + offset,
                      top: 0,
                      bottom: 0,
                      width: _revealWidth,
                      child: GestureDetector(
                        onTap: widget.onDelete,
                        child: const ColoredBox(
                          color: AppColors.dangerBg,
                          child: Center(
                            child: Icon(
                              Icons.delete_outline,
                              color: AppColors.danger,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
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
