import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:link_2_chat/core/design/app_context.dart';
import 'package:link_2_chat/core/design/app_radii.dart';
import 'package:link_2_chat/core/design/app_spacing.dart';
import 'package:link_2_chat/features/dashboard/application/dashboard_providers.dart';
import 'package:link_2_chat/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// The gradient counter card: the total generated links and today's date.
/// The pre-refactor summary card, on the theme's tokens.
class SummaryCard extends ConsumerWidget {
  const SummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    final totalLinks = ref.watch(
      dashboardControllerProvider.select((s) => s.totalLinks),
    );
    final today = DateFormat.yMMMMd(
      Localizations.localeOf(context).toString(),
    ).format(DateTime.now());

    return Container(
      padding: const EdgeInsetsDirectional.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [colors.primary, colors.primary.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.dashboardTotalLinks,
                      style: TextStyle(
                        color: colors.onPrimary.withValues(alpha: 0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '$totalLinks',
                      style: TextStyle(
                        color: colors.onPrimary,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsetsDirectional.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: colors.onPrimary.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.link_rounded,
                  color: colors.onPrimary,
                  size: 32,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: colors.onPrimary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppRadii.lg),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  color: colors.onPrimary,
                  size: 16,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  today,
                  style: TextStyle(
                    color: colors.onPrimary.withValues(alpha: 0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
