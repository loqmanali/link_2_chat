import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:link_2_chat/core/design/app_context.dart';
import 'package:link_2_chat/core/design/app_radii.dart';
import 'package:link_2_chat/core/design/app_spacing.dart';
import 'package:link_2_chat/core/download/file_downloader.dart';
import 'package:link_2_chat/features/entries/entries.dart';
import 'package:link_2_chat/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// The expanded QR code of the generated link, with share (the QR image goes
/// to the same download / share flow an export would) and copy actions. The
/// pre-refactor inline `QrCodeWidget`, without its `RepaintBoundary` capture:
/// `QrPainter.toImageData` renders the bytes directly.
class QrCodePanel extends ConsumerWidget {
  const QrCodePanel({required this.entry, super.key});

  final PhoneEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    final platformName =
        entry.platform == LinkPlatform.whatsapp
            ? l10n.commonWhatsApp
            : l10n.commonTelegram;

    return Container(
      padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: colors.line),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.homeQrTitle(platformName),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsetsDirectional.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colors.page,
              borderRadius: BorderRadius.circular(AppRadii.sm),
              border: Border.all(color: colors.line),
            ),
            child: QrImageView(
              data: entry.link,
              size: 200,
              backgroundColor: colors.card,
              eyeStyle: QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: colors.text,
              ),
              dataModuleStyle: QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: colors.text,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: () => _shareQr(context),
                icon: const Icon(Icons.share, size: 18),
                label: Text(l10n.homeQrShare),
              ),
              const SizedBox(width: AppSpacing.lg),
              OutlinedButton.icon(
                onPressed: () => _copy(context, entry.link),
                icon: const Icon(Icons.content_copy, size: 18),
                label: Text(l10n.commonCopyLink),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            entry.link,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: colors.textMuted),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  /// Renders the QR to PNG bytes and hands them to the share sheet (mobile)
  /// or the browser download (web).
  Future<void> _shareQr(BuildContext context) async {
    try {
      final bytes = await QrPainter(
        data: entry.link,
        version: QrVersions.auto,
      ).toImageData(200);
      if (bytes == null) return;
      await saveGeneratedFile(
        bytes: bytes.buffer.asUint8List(),
        fileName: 'link2chat-qr.png',
        mimeType: 'image/png',
      );
    } on Object {
      // Nothing sensible to do when rendering or sharing fails; the QR stays
      // on screen.
    }
  }

  void _copy(BuildContext context, String link) {
    final l10n = AppLocalizations.of(context);
    Clipboard.setData(ClipboardData(text: link));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.commonLinkCopied)));
  }
}
