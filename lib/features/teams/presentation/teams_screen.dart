import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:link_2_chat/core/design/app_context.dart';
import 'package:link_2_chat/core/design/app_spacing.dart';
import 'package:link_2_chat/core/design/components/app_button.dart';
import 'package:link_2_chat/core/design/components/app_state_view.dart';
import 'package:link_2_chat/core/ui/failure_message.dart';
import 'package:link_2_chat/features/auth/auth.dart';
import 'package:link_2_chat/features/teams/application/teams_providers.dart';
import 'package:link_2_chat/features/teams/domain/team.dart';
import 'package:link_2_chat/features/teams/presentation/components/create_team_dialog.dart';
import 'package:link_2_chat/features/teams/presentation/components/team_card.dart';
import 'package:link_2_chat/features/teams/presentation/routes.dart';
import 'package:link_2_chat/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// The teams tab: every team the signed-in account owns or belongs to, the
/// empty state, and — for free accounts — the premium upsell tile. A tab
/// child, so no route of its own.
class TeamsScreen extends ConsumerWidget {
  const TeamsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(teamsProvider);
    final userId = ref.watch(currentUserProvider).value?.id;
    final body = state.teams.when(
      loading: () => const AppStateView.loading(),
      error:
          (error, _) => AppStateView.error(
            message: failureMessage(AppLocalizations.of(context), error),
            retryLabel: AppLocalizations.of(context).commonRetry,
            onRetry: () => ref.invalidate(teamsProvider),
          ),
      data:
          (teams) =>
              teams.isEmpty
                  ? _TeamsEmpty(onCreate: () => _onCreate(context, ref))
                  : _TeamsList(
                    teams: teams,
                    userId: userId,
                    canCreate: _canCreate(ref),
                    onCreate: () => _onCreate(context, ref),
                  ),
    );
    return SafeArea(child: body);
  }

  bool _canCreate(WidgetRef ref) =>
      ref.read(subscriptionTierProvider) != SubscriptionTier.free;

  void _onCreate(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    if (!_canCreate(ref)) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.teamsErrorNotAllowed)));
      return;
    }
    showDialog<void>(
      context: context,
      builder: (context) => const CreateTeamDialog(),
    );
  }
}

/// Nothing yet: the hint and the create button of the legacy empty state.
class _TeamsEmpty extends StatelessWidget {
  const _TeamsEmpty({required this.onCreate});

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
            Icon(Icons.group_outlined, size: 64, color: colors.textMuted),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.teamsEmpty,
              style: TextStyle(fontSize: 18, color: colors.textMuted),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.teamsEmptyHint,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: colors.textMuted),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(label: l10n.teamsCreateTeam, onPressed: onCreate),
          ],
        ),
      ),
    );
  }
}

/// The "Your Teams" header, the free-tier upsell tile and the team cards.
class _TeamsList extends StatelessWidget {
  const _TeamsList({
    required this.teams,
    required this.userId,
    required this.canCreate,
    required this.onCreate,
  });

  final List<Team> teams;
  final String? userId;
  final bool canCreate;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.teamsYourTeams,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colors.text,
              ),
            ),
            if (canCreate)
              OutlinedButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add, size: 18),
                label: Text(l10n.teamsCreateTeam),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        if (!canCreate) ...[
          const _TeamsUpsell(),
          const SizedBox(height: AppSpacing.lg),
        ],
        for (final team in teams)
          TeamCard(
            team: team,
            isOwner: team.ownerId == userId,
            onTap: () => context.push(teamDetailsPath(team.id)),
          ),
      ],
    );
  }
}

/// The premium tile a free account sees above the list.
class _TeamsUpsell extends StatelessWidget {
  const _TeamsUpsell();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context);
    return Card(
      color: colors.card,
      child: Padding(
        padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
        child: Row(
          children: [
            Icon(Icons.star, color: colors.accent),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                l10n.teamsUpgradeHint,
                style: TextStyle(fontSize: 14, color: colors.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
