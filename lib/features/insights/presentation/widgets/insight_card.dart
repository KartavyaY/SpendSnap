import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/insight_model.dart';

class InsightCard extends StatelessWidget {
  final Insight insight;
  final bool compact;

  const InsightCard({super.key, required this.insight, this.compact = false});

  Color get _typeColor {
    switch (insight.type) {
      case InsightType.warning:
        return AppColors.danger;
      case InsightType.observation:
        return AppColors.info;
      case InsightType.achievement:
        return AppColors.success;
      case InsightType.projection:
        return AppColors.warning;
    }
  }

  IconData get _typeIcon {
    switch (insight.type) {
      case InsightType.warning:
        return Icons.warning_amber_rounded;
      case InsightType.observation:
        return Icons.lightbulb_outline;
      case InsightType.achievement:
        return Icons.emoji_events_outlined;
      case InsightType.projection:
        return Icons.trending_up;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _typeColor;
    return Container(
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(compact ? 12 : 16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_typeIcon, size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  insight.title,
                  style: AppTypography.label.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (!compact) ...[
            const SizedBox(height: 8),
            Text(
              insight.description,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            if (insight.actionLabel != null && insight.actionRoute != null) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go(insight.actionRoute!),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: color,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(insight.actionLabel!,
                        style: AppTypography.caption.copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
                        )),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward, size: 12, color: color),
                  ],
                ),
              ),
            ],
          ] else ...[
            const SizedBox(height: 4),
            Text(
              insight.description,
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
