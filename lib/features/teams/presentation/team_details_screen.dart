import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:link_2_chat/core/design/app_context.dart';
import 'package:link_2_chat/core/design/app_radii.dart';
import 'package:link_2_chat/core/design/app_spacing.dart';
import 'package:link_2_chat/core/design/components/app_button.dart';
import 'package:link_2_chat/core/design/components/app_state_view.dart';
import 'package:link_2_chat/core/ui/failure_message.dart';
import 'package:link_2_chat/core/ui/failure_toast.dart';
import 'package:link_2_chat/features/auth/auth.dart';
import 'package:link_2_chat/features/entries/entries.dart';
import 'package:link_2_chat/features/teams/application/teams_providers.dart';
import 'package:link_2_chat/features/teams/domain/team.dart';
import 'package:link_2_chat/features/teams/presentation/components/invite_member_dialog.dart';
import 'package:link_2_chat/features/teams/presentation/components/member_list_item.dart';
import 'package:link_2_chat/features/teams/presentation/relative_date.dart';
import 'package:link_2_chat/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// The name of a local account by id, for the owner row of the members tab.
final _userNameProvider = FutureProvider.family<String?, String>((ref, id) {
  return ref.watch(usersStoreProvider).byId(id).then((user) => user?.name);
});

/// One team, standalone route: header, then Members / Analytics / Settings.
/// The settings tab carries the owner-only switches and the danger zone.
class TeamDetailsScreen extends ConsumerWidget {
  const TeamDetailsScreen({required this.teamId, super.key});

  final String teamId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final team = ref.watch(teamByIdProvider(teamId));
    final l10n = AppLocalizations.of(context);

    ref.listen(deleteTeamActionProvider, (_, next) {
      if (next.hasError && !next.isLoading) {
        showFailureToast(context, next.error!);
      } else if (next.hasValue && !next.isLoading) {
        Navigator.of(context).maybePop();
      }
    });
    ref.listen(updateRoleActionProvider, (_, next) {
      if (isFreshFailure(next)) showFailureToast(context, next.error!);
    });
    ref.listen(removeMemberActionProvider, (_, next) {
      if (isFreshFailure(next)) showFailureToast(context, next.error!);
    });
    ref.listen(updateTeamSettingsActionProvider, (_, next) {
      if (isFreshFailure(next)) showFailureToast(context, next.error!);
    });

    final loaded = team.value;
    return Scaffold(
      backgroundColor: context.appColors.page,
      appBar: AppBar(title: Text(loaded?.name ?? '')),
      body: team.when(
        loading: () => const AppStateView.loading(),
        error:
            (error, _) => AppStateView.error(
              message: failureMessage(l10n, error),
              retryLabel: l10n.commonRetry,
              onRetry: () => ref.invalidate(teamByIdProvider(teamId)),
            ),
        data:
            (loaded) =>
                loaded == null
                    ? AppStateView.empty(message: l10n.teamsLoadingDetails)
                    : _TeamDetails(team: loaded, teamId: teamId),
      ),
    );
  }
}

/// The loaded team view: header and the three tabs.
class _TeamDetails extends StatelessWidget {
  const _TeamDetails({required this.team, required this.teamId});

  final Team team;
  final String teamId;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TeamHeader(team: team),
        Expanded(
          child: DefaultTabController(
            length: 3,
            child: Scaffold(
              backgroundColor: context.appColors.page,
              appBar: TabBar(
                tabs: [
                  Tab(text: AppLocalizations.of(context).teamsMembers),
                  Tab(text: AppLocalizations.of(context).teamsTabAnalytics),
                  Tab(text: AppLocalizations.of(context).commonSettings),
                ],
              ),
              body: TabBarView(
                children: [
                  _MembersTab(team: team),
                  _AnalyticsTab(teamId: teamId),
                  _TeamSettingsTab(team: team),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Avatar, name, description, member count and creation date.
class _TeamHeader extends StatelessWidget {
  const _TeamHeader({required this.team});

  final Team team;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context);
    return Container(
      color: colors.primary.withValues(alpha: 0.05),
      padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: colors.primary.withValues(alpha: 0.2),
            child: Text(
              team.name.isNotEmpty ? team.name[0].toUpperCase() : '?',
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
                  team.name,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colors.text,
                  ),
                ),
                if (team.description.isNotEmpty)
                  Text(
                    team.description,
                    style: TextStyle(fontSize: 14, color: colors.textMuted),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Icon(Icons.people, size: 16, color: colors.textMuted),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      l10n.teamsMembersCount(team.members.length + 1),
                      style: TextStyle(fontSize: 12, color: colors.textMuted),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: colors.textMuted,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      l10n.teamsCreated(relativeDate(l10n, team.createdAt)),
                      style: TextStyle(fontSize: 12, color: colors.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The member list with the invite button for those allowed to invite.
class _MembersTab extends ConsumerWidget {
  const _MembersTab({required this.team});

  final Team team;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final currentUserId = ref.watch(currentUserProvider).value?.id;
    final isAdmin =
        team.ownerId == currentUserId ||
        team.getMember(currentUserId ?? '')?.role == TeamRole.admin;
    final canInvite =
        isAdmin ||
        (team.settings.allowMembersToInvite &&
            (team.getMember(currentUserId ?? '')?.role == TeamRole.editor ||
                team.ownerId == currentUserId));
    return Column(
      children: [
        if (canInvite)
          Padding(
            padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
            child: AppButton(
              label: l10n.teamsInviteMember,
              onPressed:
                  () => showDialog<void>(
                    context: context,
                    builder:
                        (context) => InviteMemberDialog(
                          teamId: team.id,
                          memberIds: {
                            team.ownerId,
                            for (final member in team.members) member.userId,
                          },
                        ),
                  ),
            ),
          ),
        Expanded(
          child: ListView(
            children: [
              _OwnerMemberRow(team: team, currentUserId: currentUserId),
              for (final member in team.members)
                MemberListItem(
                  member: member,
                  isCurrentUser: member.userId == currentUserId,
                  canManage: isAdmin && member.userId != currentUserId,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The owner, listed first like in the pre-refactor screen but never
/// manageable.
class _OwnerMemberRow extends ConsumerWidget {
  const _OwnerMemberRow({required this.team, required this.currentUserId});

  final Team team;
  final String? currentUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(_userNameProvider(team.ownerId)).value;
    return MemberListItem(
      member: TeamMember(
        id: '',
        teamId: team.id,
        userId: team.ownerId,
        name: name ?? '',
        email: '',
        role: TeamRole.owner,
        joinedAt: team.createdAt,
      ),
      isCurrentUser: team.ownerId == currentUserId,
      canManage: false,
    );
  }
}

/// Links generated per member, read from the local history. No local data at
/// all degrades to the legacy coming-soon note.
class _AnalyticsTab extends ConsumerWidget {
  const _AnalyticsTab({required this.teamId});

  final String teamId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamAsync = ref.watch(teamByIdProvider(teamId));
    final team = teamAsync.value;
    if (team == null) return const AppStateView.loading();
    final userIds = [
      team.ownerId,
      for (final member in team.members) member.userId,
    ];
    final counts = ref.watch(_linkCountsProvider(userIds));
    final l10n = AppLocalizations.of(context);
    final teamById = <String, TeamMember>{
      team.ownerId: TeamMember(
        id: '',
        teamId: team.id,
        userId: team.ownerId,
        name: '',
        email: '',
        role: TeamRole.owner,
        joinedAt: team.createdAt,
      ),
      for (final member in team.members) member.userId: member,
    };
    return counts.when(
      loading: () => const AppStateView.loading(),
      error:
          (error, _) => AppStateView.error(
            message: failureMessage(l10n, error),
            retryLabel: l10n.commonRetry,
            onRetry: () => ref.invalidate(_linkCountsProvider(userIds)),
          ),
      data: (perUser) {
        final total = perUser.values.fold(0, (sum, n) => sum + n);
        if (total == 0) {
          return Center(
            child: Text(
              l10n.teamsAnalyticsComingSoon,
              style: TextStyle(color: context.appColors.textMuted),
            ),
          );
        }
        final rows = [
          for (final entry in perUser.entries.where((e) => e.value > 0))
            (member: teamById[entry.key], count: entry.value),
        ]..sort((a, b) => b.count.compareTo(a.count));
        return ListView(
          padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
          children: [
            for (final row in rows)
              _AnalyticsBar(
                label: row.member?.name ?? l10n.teamsUnknownUser,
                count: row.count,
                max: rows.first.count,
              ),
          ],
        );
      },
    );
  }
}

/// History rows per user id, so the team chart-lite knows who generated what.
final _linkCountsProvider =
    FutureProvider.family<Map<String, int>, List<String>>((ref, userIds) async {
      final store = ref.watch(entriesStoreProvider);
      final counts = <String, int>{};
      for (final userId in userIds) {
        counts[userId] = (await store.history(userId)).length;
      }
      return counts;
    });

/// One horizontal bar of the per-member link counts.
class _AnalyticsBar extends StatelessWidget {
  const _AnalyticsBar({
    required this.label,
    required this.count,
    required this.max,
  });

  final String label;
  final int count;
  final int max;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: colors.text),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 20,
                  decoration: BoxDecoration(
                    color: colors.page,
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: max == 0 ? 0 : count / max,
                  child: Container(
                    height: 20,
                    decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 28,
            child: Text(
              '$count',
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: colors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The owner-only switches plus the danger zone with the delete confirm.
class _TeamSettingsTab extends ConsumerWidget {
  const _TeamSettingsTab({required this.team});

  final Team team;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context);
    final isOwner = ref.watch(currentUserProvider).value?.id == team.ownerId;
    void toggle(TeamSettings Function(TeamSettings) change) {
      if (!isOwner) return;
      ref
          .read(updateTeamSettingsActionProvider.notifier)
          .change(team.id, change(team.settings));
    }

    return ListView(
      padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
      children: [
        Text(
          l10n.teamsSettingsTitle,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colors.text,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Card(
          color: colors.card,
          child: Column(
            children: [
              SwitchListTile(
                title: Text(
                  l10n.teamsAllowInviteTitle,
                  style: TextStyle(color: colors.text),
                ),
                subtitle: Text(
                  l10n.teamsAllowInviteSubtitle,
                  style: TextStyle(color: colors.textMuted),
                ),
                value: team.settings.allowMembersToInvite,
                onChanged:
                    isOwner
                        ? (value) => toggle(
                          (s) => s.copyWith(allowMembersToInvite: value),
                        )
                        : null,
              ),
              Divider(height: 1, color: colors.line),
              SwitchListTile(
                title: Text(
                  l10n.teamsRequireApprovalTitle,
                  style: TextStyle(color: colors.text),
                ),
                subtitle: Text(
                  l10n.teamsRequireApprovalSubtitle,
                  style: TextStyle(color: colors.textMuted),
                ),
                value: team.settings.requireApprovalForLinks,
                onChanged:
                    isOwner
                        ? (value) => toggle(
                          (s) => s.copyWith(requireApprovalForLinks: value),
                        )
                        : null,
              ),
            ],
          ),
        ),
        if (isOwner) ...[
          const SizedBox(height: AppSpacing.xl),
          Text(
            l10n.teamsDangerZone,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colors.danger,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Card(
            color: colors.danger.withValues(alpha: 0.06),
            child: Padding(
              padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.teamsDeleteThisTeam,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colors.text,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.teamsDeleteWarning,
                    style: TextStyle(fontSize: 14, color: colors.textMuted),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    label: l10n.teamsDeleteThisTeam,
                    onPressed: () => _confirmDelete(context, ref),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(l10n.teamsDeleteTeam),
            content: Text(l10n.teamsDeleteConfirmMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.commonCancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(l10n.commonDelete),
              ),
            ],
          ),
    );
    if (confirmed ?? false) {
      await ref.read(deleteTeamActionProvider.notifier).delete(team.id);
    }
  }
}
