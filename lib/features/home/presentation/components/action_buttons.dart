import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:link_2_chat/core/design/app_context.dart';
import 'package:link_2_chat/core/design/app_radii.dart';
import 'package:link_2_chat/core/design/app_spacing.dart';
import 'package:link_2_chat/features/entries/entries.dart' show LinkPlatform;
import 'package:link_2_chat/features/home/application/home_providers.dart';
import 'package:link_2_chat/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// The WhatsApp / Telegram generate buttons and the QR shortcut. Disabled
/// while the number does not pass the length rule or a generate is running
/// (the pre-refactor buttons coloured themselves down instead).
class ActionButtons extends ConsumerWidget {
  const ActionButtons({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    final input = ref.watch(homeControllerProvider);
    final action = ref.watch(generateLinkActionProvider);
    final enabled = input.isValid && !action.isLoading;

    void generate(LinkPlatform platform) {
      FocusManager.instance.primaryFocus?.unfocus();
      ref.read(generateLinkActionProvider.notifier).generate(platform);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _PlatformButton(
                label: l10n.commonWhatsApp,
                icon: Icons.message_rounded,
                color: colors.whatsapp,
                enabled: enabled,
                onPressed: () => generate(LinkPlatform.whatsapp),
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: _PlatformButton(
                label: l10n.commonTelegram,
                icon: Icons.send_rounded,
                color: colors.telegram,
                enabled: enabled,
                onPressed: () => generate(LinkPlatform.telegram),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        OutlinedButton.icon(
          onPressed:
              enabled
                  ? () {
                    FocusManager.instance.primaryFocus?.unfocus();
                    ref.read(homeControllerProvider.notifier).toggleQr();
                  }
                  : null,
          icon: const Icon(Icons.qr_code_rounded, size: 22),
          label: Text(
            l10n.homeGenerateQr,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: colors.primary,
            minimumSize: const Size.fromHeight(52),
            side: BorderSide(color: colors.primary, width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.lg),
            ),
          ),
        ),
      ],
    );
  }
}

/// One coloured generate button. Disabled buttons dim in the theme's own way.
class _PlatformButton extends StatelessWidget {
  const _PlatformButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return ElevatedButton.icon(
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon, size: 22),
      label: Text(
        label,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: colors.onPrimary,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
      ),
    );
  }
}
