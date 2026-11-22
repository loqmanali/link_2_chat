import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:link_2_chat/core/design/app_colors.dart';
import 'package:link_2_chat/core/design/app_context.dart';
import 'package:link_2_chat/core/design/app_radii.dart';
import 'package:link_2_chat/core/design/app_spacing.dart';
import 'package:link_2_chat/core/design/components/app_button.dart';
import 'package:link_2_chat/core/design/components/app_text_field.dart';
import 'package:link_2_chat/core/ui/failure_message.dart';
import 'package:link_2_chat/core/ui/failure_toast.dart' show isFreshFailure;
import 'package:link_2_chat/features/auth/auth.dart';
import 'package:link_2_chat/features/teams/application/teams_providers.dart';
import 'package:link_2_chat/features/teams/domain/team.dart';
import 'package:link_2_chat/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// Invites one member by email. As the address is typed, local accounts that
/// match it exactly are offered under "Matching Users". There is no
/// cross-device directory any more: an unknown email is stored as an invited
/// placeholder member, not rejected.
class InviteMemberDialog extends ConsumerStatefulWidget {
  const InviteMemberDialog({
    required this.teamId,
    required this.memberIds,
    super.key,
  });

  final String teamId;

  /// The user ids already in the team; a suggestion for one of them is
  /// hidden.
  final Set<String> memberIds;

  @override
  ConsumerState<InviteMemberDialog> createState() => _InviteMemberDialogState();
}

class _InviteMemberDialogState extends ConsumerState<InviteMemberDialog> {
  final _emailController = TextEditingController();

  /// The selected role; the chips and the description listen to it.
  final _role = ValueNotifier<TeamRole>(TeamRole.viewer);

  /// A local account matching the typed email, if any.
  final _matchingUser = ValueNotifier<User?>(null);

  /// The validation or action failure under the email field.
  final _error = ValueNotifier<String?>(null);

  @override
  void initState() {
    super.initState();
    // AppTextField owns no onChanged, so the controller itself is watched.
    _emailController.addListener(_onEmailChanged);
  }

  @override
  void dispose() {
    _emailController.removeListener(_onEmailChanged);
    _emailController.dispose();
    _role.dispose();
    _matchingUser.dispose();
    _error.dispose();
    super.dispose();
  }

  void _onEmailChanged() => unawaited(_search(_emailController.text));

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context);
    final action = ref.watch(inviteMemberActionProvider);
    return AlertDialog(
      title: Text(l10n.teamsInviteTeamMember),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ValueListenableBuilder<String?>(
              valueListenable: _error,
              builder:
                  (context, error, _) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (error != null) ...[
                        Text(
                          error,
                          style: TextStyle(color: colors.danger, fontSize: 12),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      AppTextField(
                        controller: _emailController,
                        label: l10n.teamsEmailLabel,
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ],
                  ),
            ),
            ValueListenableBuilder<User?>(
              valueListenable: _matchingUser,
              builder: (context, user, _) {
                if (user == null) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l10n.teamsMatchingUsers,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: colors.text,
                      ),
                    ),
                    ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        backgroundColor: colors.page,
                        child: Text(
                          user.name.isNotEmpty
                              ? user.name[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: colors.text,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        user.name,
                        style: TextStyle(color: colors.text),
                      ),
                      subtitle: Text(
                        user.email,
                        style: TextStyle(fontSize: 12, color: colors.textMuted),
                      ),
                      onTap: () {
                        _emailController.text = user.email;
                        _matchingUser.value = null;
                      },
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.teamsSelectRole,
              style: TextStyle(fontWeight: FontWeight.bold, color: colors.text),
            ),
            const SizedBox(height: AppSpacing.sm),
            ValueListenableBuilder<TeamRole>(
              valueListenable: _role,
              builder:
                  (context, selectedRole, _) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: AppSpacing.sm,
                        children: [
                          _RoleChip(
                            role: TeamRole.admin,
                            label: l10n.teamsRoleAdmin,
                            selectedRole: selectedRole,
                            onSelected: (role) => _role.value = role,
                          ),
                          _RoleChip(
                            role: TeamRole.editor,
                            label: l10n.teamsRoleEditor,
                            selectedRole: selectedRole,
                            onSelected: (role) => _role.value = role,
                          ),
                          _RoleChip(
                            role: TeamRole.viewer,
                            label: l10n.teamsRoleViewer,
                            selectedRole: selectedRole,
                            onSelected: (role) => _role.value = role,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        l10n.teamsRolePermissions,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: colors.text,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Container(
                        padding: const EdgeInsetsDirectional.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: _roleColor(
                            colors,
                            selectedRole,
                          ).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadii.sm),
                        ),
                        child: Text(
                          _roleDescription(l10n, selectedRole),
                          style: TextStyle(
                            fontSize: 12,
                            color: _roleColor(colors, selectedRole),
                          ),
                        ),
                      ),
                    ],
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
          label: l10n.teamsInvite,
          isLoading: action.isLoading,
          onPressed: _invite,
        ),
      ],
    );
  }

  Future<void> _search(String value) async {
    final text = value.trim().toLowerCase();
    if (!text.contains('@')) {
      _matchingUser.value = null;
      return;
    }
    final user = await ref.read(usersStoreProvider).byEmail(text);
    if (!mounted) return;
    _matchingUser.value =
        (user == null || widget.memberIds.contains(user.id)) ? null : user;
  }

  Future<void> _invite() async {
    final l10n = AppLocalizations.of(context);
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _error.value = l10n.teamsEmailRequired;
      return;
    }
    _error.value = null;
    await ref
        .read(inviteMemberActionProvider.notifier)
        .invite(teamId: widget.teamId, email: email, role: _role.value);
    final result = ref.read(inviteMemberActionProvider);
    if (!mounted) return;
    if (isFreshFailure(result)) {
      _error.value = failureMessage(l10n, result.error!);
      return;
    }
    Navigator.pop(context);
  }

  String _roleDescription(AppLocalizations l10n, TeamRole role) =>
      switch (role) {
        TeamRole.owner => '',
        TeamRole.admin => l10n.teamsRoleAdminDesc,
        TeamRole.editor => l10n.teamsRoleEditorDesc,
        TeamRole.viewer => l10n.teamsRoleViewerDesc,
      };

  Color _roleColor(AppColors colors, TeamRole role) => switch (role) {
    TeamRole.owner => colors.accent,
    TeamRole.admin => colors.danger,
    TeamRole.editor => colors.success,
    TeamRole.viewer => colors.telegram,
  };
}

/// The Admin/Editor/Viewer choice chip of the invite dialog.
class _RoleChip extends StatelessWidget {
  const _RoleChip({
    required this.role,
    required this.label,
    required this.selectedRole,
    required this.onSelected,
  });

  final TeamRole role;
  final String label;
  final TeamRole selectedRole;
  final ValueChanged<TeamRole> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isSelected = selectedRole == role;
    final color = switch (role) {
      TeamRole.owner => colors.accent,
      TeamRole.admin => colors.danger,
      TeamRole.editor => colors.success,
      TeamRole.viewer => colors.telegram,
    };
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(role),
      selectedColor: color,
      labelStyle: TextStyle(
        color: isSelected ? colors.onPrimary : colors.text,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}
