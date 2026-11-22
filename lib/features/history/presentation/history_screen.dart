import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:link_2_chat/core/api/failure.dart';
import 'package:link_2_chat/core/design/app_context.dart';
import 'package:link_2_chat/core/design/app_radii.dart';
import 'package:link_2_chat/core/design/app_spacing.dart';
import 'package:link_2_chat/core/design/components/app_state_view.dart';
import 'package:link_2_chat/core/ui/failure_message.dart';
import 'package:link_2_chat/core/ui/failure_toast.dart';
import 'package:link_2_chat/features/entries/entries.dart';
import 'package:link_2_chat/features/history/application/history_providers.dart';
import 'package:link_2_chat/features/history/presentation/components/history_tile.dart';
import 'package:link_2_chat/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

/// The link history tab: every generated link, newest first, with its details
/// dialog and the clear-all action. A tab child: the shell owns the scaffold
/// and the bottom bar.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    final state = ref.watch(historyControllerProvider);
    ref.listen(clearHistoryActionProvider, (previous, next) {
      if (isFreshFailure(next) && next.error is Failure) {
        showFailureToast(context, next.error!);
      }
    });
    ref.listen(historyControllerProvider, (previous, next) {
      final error = next.error;
      if (previous?.error == null && error != null && error is Failure) {
        showFailureToast(context, error);
      }
    });

    if (state.isLoading && state.entries.isEmpty) {
      return const AppStateView.loading();
    }
    if (state.error != null && state.entries.isEmpty) {
      return AppStateView.error(
        message: l10n.historyErrorLoad(failureMessage(l10n, state.error!)),
        retryLabel: l10n.commonRetry,
        onRetry: () => ref.invalidate(historyControllerProvider),
      );
    }
    if (state.entries.isEmpty) return const _HistoryEmpty();

    return Column(
      children: [
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl,
              0,
            ),
            child: TextButton.icon(
              onPressed: () => _confirmClear(context, ref),
              icon: const Icon(Icons.delete_outline_rounded, size: 20),
              label: Text(l10n.commonDelete),
              style: TextButton.styleFrom(foregroundColor: colors.danger),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
            itemCount: state.entries.length,
            itemBuilder: (context, index) {
              final entry = state.entries[index];
              return HistoryTile(
                entry: entry,
                onOpenDetails: () => _showDetails(context, entry),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text(l10n.historyClearTitle),
            content: Text(l10n.historyClearMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(l10n.commonCancel),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                child: Text(l10n.historyClearConfirm),
              ),
            ],
          ),
    );
    if (confirmed ?? false) {
      await ref.read(clearHistoryActionProvider.notifier).clear();
    }
  }

  void _showDetails(BuildContext context, PhoneEntry entry) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    final isWhatsapp = entry.platform == LinkPlatform.whatsapp;
    final platformColor = isWhatsapp ? colors.whatsapp : colors.telegram;
    final platformName = isWhatsapp ? l10n.commonWhatsApp : l10n.commonTelegram;
    final countryName =
        entry.countryName.isEmpty ? l10n.commonUnknown : entry.countryName;
    final date = DateFormat.yMMMMd(
      Localizations.localeOf(context).toString(),
    ).add_jm().format(entry.createdAt);

    showDialog<void>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsetsDirectional.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: platformColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isWhatsapp ? Icons.message_rounded : Icons.send_rounded,
                    color: platformColor,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: Text(l10n.commonPlatformLink(platformName))),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.historyDetailsPhone,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(displayPhoneNumber(entry)),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l10n.historyDetailsCountry,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(countryName),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l10n.historyDetailsGenerated,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(date),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l10n.historyDetailsLink,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Container(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: colors.page,
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                    border: Border.all(color: colors.line),
                  ),
                  child: Text(
                    entry.link,
                    style: TextStyle(color: platformColor, fontSize: 14),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(l10n.commonClose),
              ),
              TextButton(
                onPressed: () {
                  _copy(context, entry.link);
                  Navigator.of(dialogContext).pop();
                },
                child: Text(l10n.commonCopyLink),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  _open(entry.link);
                },
                child: Text(l10n.historyOpenLink),
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

  Future<void> _open(String link) async {
    try {
      await launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication);
    } on Object {
      // Nothing sensible to do when the platform cannot open the link.
    }
  }
}

/// The 'nothing generated yet' state of the tab.
class _HistoryEmpty extends StatelessWidget {
  const _HistoryEmpty();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: colors.page,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.history, size: 64, color: colors.textMuted),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            l10n.historyEmpty,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: colors.text,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.historyEmptyHint,
            style: TextStyle(fontSize: 15, color: colors.textMuted),
          ),
        ],
      ),
    );
  }
}
