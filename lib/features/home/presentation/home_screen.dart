import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:link_2_chat/core/api/failure.dart';
import 'package:link_2_chat/core/design/app_context.dart';
import 'package:link_2_chat/core/design/app_radii.dart';
import 'package:link_2_chat/core/design/app_spacing.dart';
import 'package:link_2_chat/core/ui/failure_toast.dart';
import 'package:link_2_chat/features/home/application/home_providers.dart';
import 'package:link_2_chat/features/home/domain/guest_limit_failure.dart';
import 'package:link_2_chat/features/home/presentation/components/action_buttons.dart';
import 'package:link_2_chat/features/home/presentation/components/link_result_card.dart';
import 'package:link_2_chat/features/home/presentation/components/phone_input_card.dart';
import 'package:link_2_chat/features/home/presentation/components/qr_code_panel.dart';
import 'package:link_2_chat/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// The link generator tab: header, phone input, generate buttons, then the
/// result card or the QR panel of the last generated link. A tab child: the
/// shell owns the scaffold and the bottom bar.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeControllerProvider);
    ref.listen(generateLinkActionProvider, (previous, next) {
      _onActionResult(context, next);
    });

    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _HomeHeader(),
          const SizedBox(height: AppSpacing.xl),
          const PhoneInputCard(),
          const SizedBox(height: AppSpacing.xl),
          const ActionButtons(),
          if (state.generatedEntry != null && !state.isShowingQr) ...[
            const SizedBox(height: AppSpacing.xl),
            LinkResultCard(entry: state.generatedEntry!),
          ],
          if (state.generatedEntry != null && state.isShowingQr) ...[
            const SizedBox(height: AppSpacing.xl),
            QrCodePanel(entry: state.generatedEntry!),
          ],
        ],
      ),
    );
  }

  /// Maps the action's failure to a sentence: the guest limit and the invalid
  /// number have their own screen strings; known core failures go through the
  /// shared toast; anything else is not the user's business.
  void _onActionResult(BuildContext context, AsyncValue<void> next) {
    if (!isFreshFailure(next)) return;
    final l10n = AppLocalizations.of(context);
    final error = next.error;
    final message = switch (error) {
      GuestLimitFailure() => l10n.homeGuestLimit,
      ValidationFailure() => l10n.homeInvalidNumber,
      _ => null,
    };
    if (message != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    } else if (error is Failure) {
      showFailureToast(context, error);
    }
  }
}

/// The title card: a branded icon bubble and the headline sentence.
class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsetsDirectional.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: colors.line),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: colors.primary, width: 2),
            ),
            child: Icon(Icons.link_rounded, color: colors.primary, size: 40),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.homeTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
              color: colors.text,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.homeSubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: colors.textMuted,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
