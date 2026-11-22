import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:link_2_chat/core/design/app_colors.dart';
import 'package:link_2_chat/core/design/app_context.dart';
import 'package:link_2_chat/core/design/app_radii.dart';
import 'package:link_2_chat/core/design/app_spacing.dart';
import 'package:link_2_chat/features/teams/application/teams_providers.dart';
import 'package:link_2_chat/features/teams/domain/team.dart';
import 'package:link_2_chat/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// One row of the members tab: avatar, name and email, the role badge, the
/// YOU badge, and — for a manageable member — the role and remove menu.
class MemberListItem extends ConsumerWidget {
  const MemberListItem({
    required this.member,
    required this.isCurrentUser,
    required this.canManage,
    super.key,
  });

  final TeamMember member;
  final bool isCurrentUser;

  /// Whether the signed-in user may re-role or remove this member.
  final bool canManage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context);
    return Card(
      margin: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      color: colors.card,
      child: Padding(
        padding: const EdgeInsetsDirectional.all(AppSpacing.md),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: _roleColor(colors).withValues(alpha: 0.2),
              child: Text(
                member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                style: TextStyle(
                  color: _roleColor(colors),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.name.isEmpty ? l10n.teamsUnknownUser : member.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colors.text,
                    ),
                  ),
                  if (member.email.isNotEmpty)
                    Text(
                      member.email,
                      style: TextStyle(fontSize: 12, color: colors.textMuted),
                    ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      _RoleBadge(role: member.role),
                      if (isCurrentUser) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsetsDirectional.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colors.page,
                            borderRadius: BorderRadius.circular(AppRadii.lg),
                          ),
                          child: Text(
                            l10n.teamsYouBadge,
                            style: TextStyle(
                              fontSize: 10,
                              color: colors.textMuted,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (canManage)
              PopupMenuButton<_MemberMenuAction>(
                icon: Icon(Icons.more_vert, size: 18, color: colors.textMuted),
                onSelected: (action) => _handle(context, ref, action),
                itemBuilder:
                    (context) => [
                      PopupMenuItem(
                        value: _MemberMenuAction.makeAdmin,
                        child: Text(l10n.teamsMakeAdmin),
                      ),
                      PopupMenuItem(
                        value: _MemberMenuAction.makeEditor,
                        child: Text(l10n.teamsMakeEditor),
                      ),
                      PopupMenuItem(
                        value: _MemberMenuAction.makeViewer,
                        child: Text(l10n.teamsMakeViewer),
                      ),
                      PopupMenuItem(
                        value: _MemberMenuAction.remove,
                        child: Text(
                          l10n.teamsRemoveFromTeam,
                          style: TextStyle(color: colors.danger),
                        ),
                      ),
                    ],
              ),
          ],
        ),
      ),
    );
  }

  void _handle(BuildContext context, WidgetRef ref, _MemberMenuAction action) {
    final l10n = AppLocalizations.of(context);
    switch (action) {
      case _MemberMenuAction.makeAdmin:
        ref
            .read(updateRoleActionProvider.notifier)
            .updateRole(
              teamId: member.teamId,
              userId: member.userId,
              role: TeamRole.admin,
            );
      case _MemberMenuAction.makeEditor:
        ref
            .read(updateRoleActionProvider.notifier)
            .updateRole(
              teamId: member.teamId,
              userId: member.userId,
              role: TeamRole.editor,
            );
      case _MemberMenuAction.makeViewer:
        ref
            .read(updateRoleActionProvider.notifier)
            .updateRole(
              teamId: member.teamId,
              userId: member.userId,
              role: TeamRole.viewer,
            );
      case _MemberMenuAction.remove:
        unawaited(_confirmRemove(context, ref, l10n));
    }
  }

  Future<void> _confirmRemove(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(l10n.teamsRemoveTitle),
            content: Text(l10n.teamsRemoveMessage(member.name)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.commonCancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(l10n.teamsRemove),
              ),
            ],
          ),
    );
    if (confirmed ?? false) {
      await ref
          .read(removeMemberActionProvider.notifier)
          .remove(teamId: member.teamId, userId: member.userId);
    }
  }

  Color _roleColor(AppColors colors) => switch (member.role) {
    TeamRole.owner => colors.accent,
    TeamRole.admin => colors.danger,
    TeamRole.editor => colors.success,
    TeamRole.viewer => colors.telegram,
  };
}

/// What one tap of the member menu asks for.
enum _MemberMenuAction { makeAdmin, makeEditor, makeViewer, remove }

/// The coloured OWNER/ADMIN/EDITOR/VIEWER chip.
class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});

  final TeamRole role;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context);
    final color = switch (role) {
      TeamRole.owner => colors.accent,
      TeamRole.admin => colors.danger,
      TeamRole.editor => colors.success,
      TeamRole.viewer => colors.telegram,
    };
    final label = switch (role) {
      TeamRole.owner => l10n.teamsRoleOwnerBadge,
      TeamRole.admin => l10n.teamsRoleAdminBadge,
      TeamRole.editor => l10n.teamsRoleEditorBadge,
      TeamRole.viewer => l10n.teamsRoleViewerBadge,
    };
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
