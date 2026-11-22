import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:link_2_chat/app/redirect.dart';
import 'package:link_2_chat/core/design/app_context.dart';
import 'package:link_2_chat/core/design/app_radii.dart';
import 'package:link_2_chat/core/design/app_spacing.dart';
import 'package:link_2_chat/core/design/components/app_button.dart';
import 'package:link_2_chat/core/design/components/app_text_field.dart';
import 'package:link_2_chat/core/session/session_providers.dart';
import 'package:link_2_chat/core/settings/app_preferences.dart';
import 'package:link_2_chat/core/ui/failure_message.dart';
import 'package:link_2_chat/core/ui/failure_toast.dart';
import 'package:link_2_chat/features/api_keys/api_keys.dart';
import 'package:link_2_chat/features/auth/auth.dart';
import 'package:link_2_chat/features/settings/application/settings_providers.dart';
import 'package:link_2_chat/features/settings/presentation/language_name.dart';
import 'package:link_2_chat/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

/// The legal pages, carried over as constants for the about section.
const String _privacyUrl = 'https://link2chat.example.com/privacy';
const String _termsUrl = 'https://link2chat.example.com/terms';

/// The settings tab: profile (or guest card), appearance, behavior,
/// subscription, API, account and about. A tab child, so no route of its
/// own. The sections are private widget classes below — this is the port of
/// the pre-refactor 2258-line `settings_screen`, minus everything Supabase.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);
    final user = ref.watch(currentUserProvider).value;

    ref.listen(updateProfileActionProvider, (_, next) {
      if (isFreshFailure(next)) {
        showFailureToast(context, next.error!);
      } else if (next.hasValue && !next.isLoading) {
        _announce(context, AppLocalizations.of(context).settingsProfileUpdated);
      }
    });
    ref.listen(deleteAccountActionProvider, (_, next) {
      if (isFreshFailure(next)) {
        showFailureToast(context, next.error!);
      } else if (next.hasValue && !next.isLoading) {
        _announce(context, AppLocalizations.of(context).settingsAccountDeleted);
      }
    });
    ref.listen(signOutActionProvider, (_, next) {
      if (isFreshFailure(next)) showFailureToast(context, next.error!);
    });

    return SafeArea(
      child: ListView(
        padding: const EdgeInsetsDirectional.all(AppSpacing.xl),
        children: [
          if (session == null || session.isGuest || user == null)
            const _GuestCard()
          else ...[
            _ProfileSection(user: user),
            const SizedBox(height: AppSpacing.xl),
            const _SubscriptionSection(),
            const SizedBox(height: AppSpacing.lg),
            const _ApiSection(),
            const SizedBox(height: AppSpacing.xl),
            const _AccountSection(),
          ],
          const SizedBox(height: AppSpacing.xl),
          const _AppearanceSection(),
          const SizedBox(height: AppSpacing.xl),
          const _BehaviorSection(),
          const SizedBox(height: AppSpacing.xl),
          const _AboutSection(),
        ],
      ),
    );
  }

  void _announce(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

/// Avatar, name, email, the role badge, and the edit / delete buttons.
class _ProfileSection extends StatelessWidget {
  const _ProfileSection({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context);
    return Card(
      color: colors.card,
      child: Padding(
        padding: const EdgeInsetsDirectional.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: colors.primary.withValues(alpha: 0.1),
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: colors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: colors.text,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        user.email,
                        style: TextStyle(fontSize: 14, color: colors.textMuted),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: colors.success,
                          borderRadius: BorderRadius.circular(AppRadii.sm),
                        ),
                        child: Text(
                          user.role.isEmpty
                              ? l10n.settingsRoleMember
                              : '${user.role[0].toUpperCase()}${user.role.substring(1)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: l10n.settingsEditProfile,
              onPressed:
                  () => showDialog<void>(
                    context: context,
                    builder: (context) => _EditProfileDialog(user: user),
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(
              onPressed:
                  () => showDialog<void>(
                    context: context,
                    builder: (context) => const _DeleteAccountDialog(),
                  ),
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.danger,
                minimumSize: const Size.fromHeight(48),
                side: BorderSide(color: colors.danger),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
              ),
              child: Text(l10n.settingsDeleteAccount),
            ),
          ],
        ),
      ),
    );
  }
}

/// Renames the account and optionally sets a new password.
class _EditProfileDialog extends ConsumerStatefulWidget {
  const _EditProfileDialog({required this.user});

  final User user;

  @override
  ConsumerState<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends ConsumerState<_EditProfileDialog> {
  late final TextEditingController _nameController = TextEditingController(
    text: widget.user.name,
  );
  final _passwordController = TextEditingController();

  /// The validation or action failure under the name field. A listenable,
  /// because the guard forbids `setState`.
  final _error = ValueNotifier<String?>(null);

  @override
  void dispose() {
    _error.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final action = ref.watch(updateProfileActionProvider);
    return AlertDialog(
      title: Text(l10n.settingsEditProfile),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ValueListenableBuilder<String?>(
              valueListenable: _error,
              builder:
                  (context, error, _) => AppTextField(
                    controller: _nameController,
                    label: l10n.settingsNameLabel,
                    errorText: error,
                  ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              controller: _passwordController,
              label: l10n.settingsNewPasswordLabel,
              obscureText: true,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.commonCancel),
        ),
        AppButton(
          label: l10n.settingsSave,
          isLoading: action.isLoading,
          onPressed: _save,
        ),
      ],
    );
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _error.value = l10n.authNameRequired;
      return;
    }
    final password = _passwordController.text;
    if (password.isNotEmpty && password.length < 6) {
      _error.value = l10n.authPasswordTooShort;
      return;
    }
    _error.value = null;
    await ref
        .read(updateProfileActionProvider.notifier)
        .updateProfile(
          name: name,
          newPassword: password.isEmpty ? null : password,
        );
    final result = ref.read(updateProfileActionProvider);
    if (!mounted) return;
    if (isFreshFailure(result)) {
      _error.value = failureMessage(l10n, result.error!);
      return;
    }
    Navigator.pop(context);
  }
}

/// The password prompt that deletes the account for good.
class _DeleteAccountDialog extends ConsumerStatefulWidget {
  const _DeleteAccountDialog();

  @override
  ConsumerState<_DeleteAccountDialog> createState() =>
      _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends ConsumerState<_DeleteAccountDialog> {
  final _passwordController = TextEditingController();

  /// The validation or action failure under the password field. A
  /// listenable, because the guard forbids `setState`.
  final _error = ValueNotifier<String?>(null);

  @override
  void dispose() {
    _error.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context);
    final action = ref.watch(deleteAccountActionProvider);
    return AlertDialog(
      title: Text(l10n.settingsDeleteAccount),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.settingsDeleteAccountWarning,
              style: TextStyle(color: colors.danger, fontSize: 13),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.settingsDeleteAccountPrompt,
              style: TextStyle(fontSize: 13, color: colors.text),
            ),
            const SizedBox(height: AppSpacing.sm),
            ValueListenableBuilder<String?>(
              valueListenable: _error,
              builder:
                  (context, error, _) => AppTextField(
                    controller: _passwordController,
                    label: l10n.authPasswordLabel,
                    obscureText: true,
                    errorText: error,
                  ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.commonCancel),
        ),
        AppButton(
          label: l10n.settingsDeleteAccount,
          isLoading: action.isLoading,
          onPressed: _delete,
        ),
      ],
    );
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context);
    if (_passwordController.text.isEmpty) {
      _error.value = l10n.authPasswordRequired;
      return;
    }
    _error.value = null;
    await ref
        .read(deleteAccountActionProvider.notifier)
        .delete(password: _passwordController.text);
    final result = ref.read(deleteAccountActionProvider);
    if (!mounted) return;
    if (isFreshFailure(result)) {
      _error.value = failureMessage(l10n, result.error!);
      return;
    }
    // The session is gone; the router's redirect leaves for the sign-in.
    Navigator.pop(context);
  }
}

/// What a guest sees instead of the profile: the pitch and the two buttons.
class _GuestCard extends ConsumerWidget {
  const _GuestCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context);
    return Card(
      color: colors.card,
      child: Padding(
        padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.settingsSectionAccount,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: colors.page,
                  child: Icon(
                    Icons.person_outline,
                    size: 30,
                    color: colors.textMuted,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.settingsGuestUser,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colors.text,
                        ),
                      ),
                      Text(
                        l10n.settingsGuestUsingApp,
                        style: TextStyle(fontSize: 14, color: colors.textMuted),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Container(
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colors.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(AppRadii.lg),
                        ),
                        child: Text(
                          l10n.settingsLimitedFeatures,
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.accent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.settingsGuestSignInPrompt,
              style: TextStyle(fontSize: 14, color: colors.text),
            ),
            const SizedBox(height: AppSpacing.sm),
            _GuestFeature(text: l10n.settingsFeatureSaveHistory),
            _GuestFeature(text: l10n.settingsFeatureSyncDevices),
            _GuestFeature(text: l10n.settingsFeatureTeams),
            _GuestFeature(text: l10n.settingsFeatureAnalytics),
            _GuestFeature(text: l10n.settingsFeatureApi),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: l10n.settingsSignIn,
                    onPressed:
                        () => _leaveGuestMode(context, ref, AppPaths.signIn),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        () => _leaveGuestMode(context, ref, AppPaths.register),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      side: BorderSide(color: colors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadii.md),
                      ),
                    ),
                    child: Text(l10n.settingsSignUp),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// The guard sends a session to the main screens, so guest mode ends
  /// first; the redirect then lands on the public screen.
  Future<void> _leaveGuestMode(
    BuildContext context,
    WidgetRef ref,
    String target,
  ) async {
    await ref.read(signOutActionProvider.notifier).signOut();
    if (context.mounted) context.go(target);
  }
}

/// One ticked line of the guest pitch.
class _GuestFeature extends StatelessWidget {
  const _GuestFeature({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: colors.primary, size: 16),
          const SizedBox(width: AppSpacing.sm),
          Text(text, style: TextStyle(fontSize: 14, color: colors.text)),
        ],
      ),
    );
  }
}

/// The theme-mode and language radio groups.
class _AppearanceSection extends ConsumerWidget {
  const _AppearanceSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context);
    final themeMode = ref.watch(themeModeControllerProvider);
    final locale = ref.watch(localeControllerProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.settingsSectionAppearance,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: colors.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Card(
          color: colors.card,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: AppSpacing.lg,
                  top: AppSpacing.lg,
                ),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    l10n.settingsThemeTitle,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colors.primary,
                    ),
                  ),
                ),
              ),
              RadioGroup<ThemeMode>(
                groupValue: themeMode,
                onChanged:
                    (value) => ref
                        .read(themeModeControllerProvider.notifier)
                        .choose(value!),
                child: Column(
                  children: [
                    _ThemeTile(
                      mode: ThemeMode.system,
                      title: l10n.settingsThemeSystem,
                      subtitle: l10n.settingsThemeSystemSubtitle,
                      icon: Icons.brightness_auto,
                    ),
                    _ThemeTile(
                      mode: ThemeMode.light,
                      title: l10n.settingsThemeLight,
                      subtitle: l10n.settingsThemeLightSubtitle,
                      icon: Icons.light_mode,
                    ),
                    _ThemeTile(
                      mode: ThemeMode.dark,
                      title: l10n.settingsThemeDark,
                      subtitle: l10n.settingsThemeDarkSubtitle,
                      icon: Icons.dark_mode,
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: colors.line),
              Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: AppSpacing.lg,
                  top: AppSpacing.lg,
                ),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    l10n.commonSettings,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colors.primary,
                    ),
                  ),
                ),
              ),
              // A null locale follows the phone, so then no tile is picked.
              RadioGroup<Locale>(
                groupValue: locale,
                onChanged:
                    (value) => ref
                        .read(localeControllerProvider.notifier)
                        .choose(value),
                child: Column(
                  children: [
                    for (final language in supportedLanguages)
                      RadioListTile<Locale>(
                        title: Text(
                          languageName(language),
                          style: TextStyle(color: colors.text),
                        ),
                        value: language,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ],
    );
  }
}

/// One theme radio tile with its icon.
class _ThemeTile extends StatelessWidget {
  const _ThemeTile({
    required this.mode,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final ThemeMode mode;
  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isSelected =
        RadioGroup.maybeOf<ThemeMode>(context)?.groupValue == mode;
    return RadioListTile<ThemeMode>(
      value: mode,
      secondary: Icon(
        icon,
        color: isSelected ? colors.primary : colors.textMuted,
      ),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w600, color: colors.text),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: colors.textMuted),
      ),
    );
  }
}

/// The behavior toggles and the not-yet default-platform tile.
class _BehaviorSection extends ConsumerWidget {
  const _BehaviorSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context);
    final saveHistory = ref.watch(saveHistoryControllerProvider);
    final showQr = ref.watch(showQrControllerProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.settingsSectionBehavior,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: colors.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Card(
          color: colors.card,
          child: Column(
            children: [
              SwitchListTile(
                title: Text(
                  l10n.settingsSaveHistoryTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: colors.text,
                  ),
                ),
                subtitle: Text(
                  l10n.settingsSaveHistorySubtitle,
                  style: TextStyle(fontSize: 14, color: colors.textMuted),
                ),
                value: saveHistory,
                onChanged:
                    (value) => ref
                        .read(saveHistoryControllerProvider.notifier)
                        .choose(value),
              ),
              SwitchListTile(
                title: Text(
                  l10n.settingsShowQrTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: colors.text,
                  ),
                ),
                subtitle: Text(
                  l10n.settingsShowQrSubtitle,
                  style: TextStyle(fontSize: 14, color: colors.textMuted),
                ),
                value: showQr,
                onChanged:
                    (value) => ref
                        .read(showQrControllerProvider.notifier)
                        .choose(value),
              ),
              Divider(height: 1, color: colors.line),
              ListTile(
                title: Text(
                  l10n.settingsDefaultPlatform,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: colors.text,
                  ),
                ),
                trailing: Container(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  child: Text(
                    l10n.settingsDefaultBadge,
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                onTap: _showComingSoon(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  VoidCallback _showComingSoon(BuildContext context) => () {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).settingsComingSoon),
        ),
      );
  };
}

/// The current plan, tapping through to the subscription screen.
class _SubscriptionSection extends ConsumerWidget {
  const _SubscriptionSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context);
    final tier = ref.watch(subscriptionTierProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.settingsSectionSubscription,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: colors.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Card(
          color: colors.card,
          child: ListTile(
            contentPadding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            leading: CircleAvatar(
              backgroundColor: colors.accent.withValues(alpha: 0.15),
              child: Icon(Icons.workspace_premium, color: colors.accent),
            ),
            title: Text(
              l10n.settingsPlanTitle,
              style: TextStyle(fontWeight: FontWeight.w600, color: colors.text),
            ),
            subtitle: Padding(
              padding: const EdgeInsetsDirectional.only(top: AppSpacing.xs),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Container(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  child: Text(
                    switch (tier) {
                      SubscriptionTier.free => l10n.subscriptionTierFree,
                      SubscriptionTier.basic => l10n.subscriptionTierBasic,
                      SubscriptionTier.professional =>
                        l10n.subscriptionTierProfessional,
                      SubscriptionTier.enterprise =>
                        l10n.subscriptionTierEnterprise,
                    },
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            trailing: Icon(Icons.chevron_right, color: colors.textMuted),
            onTap: () => context.push(AppPaths.subscription),
          ),
        ),
      ],
    );
  }
}

/// The door to the API keys screen.
class _ApiSection extends StatelessWidget {
  const _ApiSection();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context);
    return Card(
      color: colors.card,
      child: ListTile(
        contentPadding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        leading: CircleAvatar(
          backgroundColor: colors.accent.withValues(alpha: 0.15),
          child: Icon(Icons.vpn_key, color: colors.accent),
        ),
        title: Text(
          l10n.apiTitle,
          style: TextStyle(fontWeight: FontWeight.w600, color: colors.text),
        ),
        subtitle: Text(
          l10n.settingsApiKeysSubtitle,
          style: TextStyle(fontSize: 14, color: colors.textMuted),
        ),
        trailing: Icon(Icons.chevron_right, color: colors.textMuted),
        onTap: () => context.push(apiKeysPath),
      ),
    );
  }
}

/// The sign-out row with its confirmation.
class _AccountSection extends ConsumerWidget {
  const _AccountSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton(
          onPressed: () => _confirmSignOut(context, ref),
          style: OutlinedButton.styleFrom(
            foregroundColor: colors.danger,
            minimumSize: const Size.fromHeight(48),
            side: BorderSide(color: colors.danger),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
          ),
          child: Text(l10n.settingsSignOut),
        ),
      ],
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(l10n.settingsSignOut),
            content: Text(l10n.settingsSignOutConfirm),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.commonCancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(l10n.settingsSignOut),
              ),
            ],
          ),
    );
    if (confirmed ?? false) {
      await ref.read(signOutActionProvider.notifier).signOut();
    }
  }
}

/// Version and the two legal links.
class _AboutSection extends ConsumerWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context);
    final version = ref.watch(appVersionProvider).value ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.settingsSectionAbout,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: colors.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Card(
          color: colors.card,
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.info_outline, color: colors.primary),
                title: Text(
                  l10n.settingsVersion,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: colors.text,
                  ),
                ),
                subtitle: Text(
                  version,
                  style: TextStyle(fontSize: 14, color: colors.textMuted),
                ),
              ),
              Divider(height: 1, color: colors.line),
              ListTile(
                leading: Icon(
                  Icons.privacy_tip_outlined,
                  color: colors.success,
                ),
                title: Text(
                  l10n.settingsPrivacyPolicy,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: colors.text,
                  ),
                ),
                subtitle: Text(
                  l10n.settingsPrivacyPolicySubtitle,
                  style: TextStyle(fontSize: 14, color: colors.textMuted),
                ),
                trailing: Icon(Icons.chevron_right, color: colors.textMuted),
                onTap: () => unawaited(_open(_privacyUrl)),
              ),
              Divider(height: 1, color: colors.line),
              ListTile(
                leading: Icon(Icons.gavel_outlined, color: colors.accent),
                title: Text(
                  l10n.settingsTermsOfService,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: colors.text,
                  ),
                ),
                subtitle: Text(
                  l10n.settingsTermsSubtitle,
                  style: TextStyle(fontSize: 14, color: colors.textMuted),
                ),
                trailing: Icon(Icons.chevron_right, color: colors.textMuted),
                onTap: () => unawaited(_open(_termsUrl)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Object {
      // Nothing sensible to do without a browser; the tap just does nothing.
    }
  }
}
