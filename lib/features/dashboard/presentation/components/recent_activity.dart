import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:link_2_chat/core/design/app_context.dart';
import 'package:link_2_chat/core/design/app_radii.dart';
import 'package:link_2_chat/core/design/app_spacing.dart';
import 'package:link_2_chat/features/dashboard/application/dashboard_providers.dart';
import 'package:link_2_chat/features/entries/entries.dart';
import 'package:link_2_chat/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// The newest generated links, capped by the controller. The pre-refactor
/// recent activity list.
class RecentActivityList extends ConsumerWidget {
  const RecentActivityList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    final entries = ref.watch(
      dashboardControllerProvider.select((s) => s.recentEntries),
    );

    return Container(
      padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: colors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.dashboardRecentActivity,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colors.text,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (entries.isEmpty)
            SizedBox(
              height: 120,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.history, size: 44, color: colors.line),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      l10n.dashboardNoActivity,
                      style: TextStyle(fontSize: 14, color: colors.textMuted),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            for (final entry in entries) _ActivityRow(entry: entry),
          ],
        ],
      ),
    );
  }
}

/// One row: platform badge, number and country, then the platform name and
/// date on the end side.
class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.entry});

  final PhoneEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    final isWhatsapp = entry.platform == LinkPlatform.whatsapp;
    final color = isWhatsapp ? colors.whatsapp : colors.telegram;
    final platformName = isWhatsapp ? l10n.commonWhatsApp : l10n.commonTelegram;
    final countryName =
        entry.countryName.isEmpty ? l10n.commonUnknown : entry.countryName;
    final date = DateFormat.yMMMd(
      Localizations.localeOf(context).toString(),
    ).add_jm().format(entry.createdAt);

    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsetsDirectional.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Icon(
              isWhatsapp ? Icons.message_rounded : Icons.send_rounded,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayPhoneNumber(entry),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  countryName,
                  style: TextStyle(color: colors.textMuted, fontSize: 13),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Text(
                  platformName,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                date,
                style: TextStyle(color: colors.textMuted, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// '+20100 123 456 7'-style grouping for display only.
String displayPhoneNumber(PhoneEntry entry) {
  final code =
      entry.countryCode.startsWith('+')
          ? entry.countryCode
          : '+${entry.countryCode}';
  final digits = entry.phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
  final groups = <String>[];
  for (var i = 0; i < digits.length; i += 3) {
    final end = (i + 3 > digits.length) ? digits.length : i + 3;
    groups.add(digits.substring(i, end));
  }
  return '$code ${groups.join(' ')}';
}
