import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:link_2_chat/app/redirect.dart';
import 'package:link_2_chat/core/design/app_context.dart';
import 'package:link_2_chat/core/design/app_radii.dart';
import 'package:link_2_chat/core/design/app_spacing.dart';
import 'package:link_2_chat/core/design/components/app_button.dart';
import 'package:link_2_chat/core/design/components/app_state_view.dart';
import 'package:link_2_chat/core/ui/failure_message.dart';
import 'package:link_2_chat/core/ui/failure_toast.dart';
import 'package:link_2_chat/features/api_keys/application/api_keys_providers.dart';
import 'package:link_2_chat/features/api_keys/domain/api_key.dart';
import 'package:link_2_chat/features/api_keys/presentation/components/api_key_card.dart';
import 'package:link_2_chat/features/api_keys/presentation/components/create_api_key_dialog.dart';
import 'package:link_2_chat/features/auth/auth.dart';
import 'package:link_2_chat/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// The API keys screen, standalone route. Professional and Enterprise only:
/// other tiers get the locked state with the upgrade tile. The docs panel is
/// expanded on the page itself, the base URL stays a literal — it is an
/// address, not prose.
class ApiKeysScreen extends ConsumerWidget {
  const ApiKeysScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context);
    final tier = ref.watch(subscriptionTierProvider);
    final unlocked =
        tier == SubscriptionTier.professional ||
        tier == SubscriptionTier.enterprise;

    ref.listen(createApiKeyActionProvider, (_, next) {
      if (isFreshFailure(next)) showFailureToast(context, next.error!);
    });
    ref.listen(deleteApiKeyActionProvider, (_, next) {
      if (isFreshFailure(next)) showFailureToast(context, next.error!);
    });
    ref.listen(toggleApiKeyActionProvider, (_, next) {
      if (isFreshFailure(next)) showFailureToast(context, next.error!);
    });

    return Scaffold(
      backgroundColor: colors.page,
      appBar: AppBar(title: Text(l10n.apiTitle)),
      floatingActionButton:
          unlocked
              ? FloatingActionButton(
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
                onPressed: () => _openCreateDialog(context, ref),
                child: const Icon(Icons.add),
              )
              : null,
      body:
          unlocked
              ? _KeysContent(onCreate: () => _openCreateDialog(context, ref))
              : _LockedState(
                onUpgrade: () => context.push(AppPaths.subscription),
              ),
    );
  }

  Future<void> _openCreateDialog(BuildContext context, WidgetRef ref) async {
    final created = await showDialog<ApiKey>(
      context: context,
      builder: (context) => const CreateApiKeyDialog(),
    );
    if (created == null || !context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => _KeyCreatedDialog(apiKey: created),
    );
  }
}

/// The keys list, the empty state, and the documentation panel.
class _KeysContent extends StatelessWidget {
  const _KeysContent({required this.onCreate});

  /// Opens the create dialog (and the reveal dialog after a success).
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(apiKeysProvider);
        final l10n = AppLocalizations.of(context);
        final body = state.keys.when(
          loading: () => const AppStateView.loading(),
          error:
              (error, _) => AppStateView.error(
                message: failureMessage(l10n, error),
                retryLabel: l10n.commonRetry,
                onRetry: () => ref.invalidate(apiKeysProvider),
              ),
          data:
              (keys) =>
                  keys.isEmpty
                      ? _KeysEmpty(onCreate: onCreate)
                      : _KeysList(keys: keys, onCreated: onCreate),
        );
        return SafeArea(child: body);
      },
    );
  }
}

/// Nothing yet: the hint and the create button.
class _KeysEmpty extends StatelessWidget {
  const _KeysEmpty({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsetsDirectional.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.vpn_key_outlined, size: 64, color: colors.textMuted),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.apiEmptyTitle,
              style: TextStyle(fontSize: 18, color: colors.textMuted),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.apiEmptyHint,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: colors.textMuted),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(label: l10n.apiCreateKey, onPressed: onCreate),
          ],
        ),
      ),
    );
  }
}

/// The "Your API Keys" list with the docs panel at the bottom.
class _KeysList extends StatelessWidget {
  const _KeysList({required this.keys, required this.onCreated});

  final List<ApiKey> keys;
  final VoidCallback onCreated;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
      children: [
        Text(
          l10n.apiYourKeys,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: colors.text,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.apiKeysSubtitle,
          style: TextStyle(fontSize: 14, color: colors.textMuted),
        ),
        const SizedBox(height: AppSpacing.lg),
        for (final apiKey in keys) ApiKeyCard(apiKey: apiKey),
        const SizedBox(height: AppSpacing.xl),
        const _ApiDocsPanel(),
      ],
    );
  }
}

/// The collapsible documentation carried over from the pre-refactor screen.
class _ApiDocsPanel extends StatelessWidget {
  const _ApiDocsPanel();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context);
    return ExpansionTile(
      title: Text(l10n.apiDocsTitle, style: TextStyle(color: colors.text)),
      leading: Icon(Icons.book_outlined, color: colors.primary),
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DocsHeading(text: l10n.apiDocsBaseUrlHeading),
              // The base URL is an address: same characters in every locale.
              Text(
                'https://api.link2chat.app/v1',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  color: colors.text,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _DocsHeading(text: l10n.apiDocsAuthHeading),
              Text(
                l10n.apiDocsAuthBody,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  color: colors.text,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _DocsHeading(text: l10n.apiDocsEndpointsHeading),
              Text(
                l10n.apiDocGetLinks,
                style: TextStyle(fontSize: 13, color: colors.text),
              ),
              Text(
                l10n.apiDocPostLinks,
                style: TextStyle(fontSize: 13, color: colors.text),
              ),
              Text(
                l10n.apiDocGetAnalytics,
                style: TextStyle(fontSize: 13, color: colors.text),
              ),
              Text(
                l10n.apiDocGetTeams,
                style: TextStyle(fontSize: 13, color: colors.text),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.apiDocsPortal,
                style: TextStyle(fontSize: 12, color: colors.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A bold docs heading.
class _DocsHeading extends StatelessWidget {
  const _DocsHeading({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.xs),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: context.appColors.text,
        ),
      ),
    );
  }
}

/// Free and basic tiers see this instead of the keys.
class _LockedState extends StatelessWidget {
  const _LockedState({required this.onUpgrade});

  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsetsDirectional.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outlined, size: 72, color: colors.textMuted),
            const SizedBox(height: AppSpacing.xl),
            Text(
              l10n.apiLockedTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colors.text,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.apiLockedMessage,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: colors.textMuted),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(label: l10n.apiUpgradePlan, onPressed: onUpgrade),
          ],
        ),
      ),
    );
  }
}

/// The one-time reveal of the full key, with its copy button.
class _KeyCreatedDialog extends StatelessWidget {
  const _KeyCreatedDialog({required this.apiKey});

  final ApiKey apiKey;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.apiKeyCreatedTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.apiKeyCreatedWarning,
            style: TextStyle(fontWeight: FontWeight.bold, color: colors.accent),
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsetsDirectional.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colors.page,
              borderRadius: BorderRadius.circular(AppRadii.sm),
              border: Border.all(color: colors.line),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    apiKey.key,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      color: colors.text,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.copy, color: colors.primary),
                  tooltip: l10n.apiCopyTooltip,
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: apiKey.key));
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(SnackBar(content: Text(l10n.apiCopied)));
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.commonClose),
        ),
      ],
    );
  }
}
