import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:link_2_chat/core/design/app_context.dart';
import 'package:link_2_chat/core/design/app_radii.dart';
import 'package:link_2_chat/core/design/app_spacing.dart';
import 'package:link_2_chat/features/entries/entries.dart';
import 'package:link_2_chat/features/home/application/home_providers.dart';
import 'package:link_2_chat/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// The generated link: its target number, and the copy / share / open / QR
/// actions. The pre-refactor card, minus its hand-parsed phone formatting —
/// the entry already knows the number.
class LinkResultCard extends ConsumerWidget {
  const LinkResultCard({required this.entry, super.key});

  final PhoneEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    final isWhatsapp = entry.platform == LinkPlatform.whatsapp;
    final platformColor = isWhatsapp ? colors.whatsapp : colors.telegram;
    final platformName = isWhatsapp ? l10n.commonWhatsApp : l10n.commonTelegram;

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
          Row(
            children: [
              Container(
                padding: const EdgeInsetsDirectional.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: platformColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Icon(
                  isWhatsapp ? Icons.message_rounded : Icons.send_rounded,
                  color: platformColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  l10n.homeResultTitle(platformName),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: colors.page,
              borderRadius: BorderRadius.circular(AppRadii.sm),
              border: Border.all(color: colors.line),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    entry.fullPhoneNumber,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 20),
                  tooltip: l10n.homeCopyTooltip,
                  color: platformColor,
                  onPressed: () => _copy(context, entry.link),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            entry.link,
            style: TextStyle(fontSize: 14, color: colors.textMuted),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.lg),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                TextButton.icon(
                  onPressed:
                      () =>
                          ref.read(homeControllerProvider.notifier).toggleQr(),
                  icon: const Icon(Icons.qr_code_rounded, size: 18),
                  label: Text(l10n.homeActionQr),
                ),
                const SizedBox(width: AppSpacing.md),
                TextButton.icon(
                  onPressed: () => _share(context),
                  icon: const Icon(Icons.share_rounded, size: 18),
                  label: Text(l10n.homeActionShare),
                ),
                const SizedBox(width: AppSpacing.md),
                TextButton.icon(
                  onPressed: () => _open(entry.link),
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: Text(l10n.homeActionOpen),
                  style: TextButton.styleFrom(
                    foregroundColor: platformColor,
                    backgroundColor: platformColor.withValues(alpha: 0.1),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _copy(BuildContext context, String link) {
    final l10n = AppLocalizations.of(context);
    Clipboard.setData(ClipboardData(text: link));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.commonLinkCopied)));
  }

  Future<void> _share(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final platformName =
        entry.platform == LinkPlatform.whatsapp
            ? l10n.commonWhatsApp
            : l10n.commonTelegram;
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: entry.link,
          subject: l10n.commonPlatformLink(platformName),
        ),
      );
    } on Object {
      // Nothing sensible to do when the share sheet is unavailable.
    }
  }

  Future<void> _open(String link) async {
    try {
      await launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication);
    } on Object {
      // Nothing sensible to do when the platform cannot open the link.
    }
  }
}
