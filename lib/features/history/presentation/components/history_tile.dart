import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:link_2_chat/core/design/app_context.dart';
import 'package:link_2_chat/core/design/app_radii.dart';
import 'package:link_2_chat/core/design/app_spacing.dart';
import 'package:link_2_chat/features/entries/entries.dart';
import 'package:link_2_chat/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// One history row: platform badge, number, country and date; tapping opens
/// the details dialog (owned by the screen).
class HistoryTile extends ConsumerWidget {
  const HistoryTile({
    required this.entry,
    required this.onOpenDetails,
    super.key,
  });

  final PhoneEntry entry;
  final VoidCallback onOpenDetails;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    final isWhatsapp = entry.platform == LinkPlatform.whatsapp;
    final platformColor = isWhatsapp ? colors.whatsapp : colors.telegram;
    final platformName = isWhatsapp ? l10n.commonWhatsApp : l10n.commonTelegram;
    final countryName =
        entry.countryName.isEmpty ? l10n.commonUnknown : entry.countryName;
    final date = DateFormat.yMMMd(
      Localizations.localeOf(context).toString(),
    ).add_jm().format(entry.createdAt);

    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.md),
      // A Material (not a decorated Container) so the ListTile's background
      // and ink splashes paint on it instead of vanishing behind a box.
      child: Material(
        color: colors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          side: BorderSide(color: colors.line),
        ),
        child: ListTile(
          contentPadding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          leading: Container(
            padding: const EdgeInsetsDirectional.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: platformColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isWhatsapp ? Icons.message_rounded : Icons.send_rounded,
              color: platformColor,
              size: 24,
            ),
          ),
          title: Text(
            displayPhoneNumber(entry),
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(countryName, style: const TextStyle(fontSize: 14)),
              const SizedBox(height: AppSpacing.xs),
              Text(
                date,
                style: TextStyle(fontSize: 12, color: colors.textMuted),
              ),
            ],
          ),
          trailing: Container(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: platformColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Text(
              platformName,
              style: TextStyle(
                color: platformColor,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          onTap: onOpenDetails,
        ),
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
