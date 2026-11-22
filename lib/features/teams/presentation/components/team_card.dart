import 'package:link_2_chat/core/design/app_context.dart';
import 'package:link_2_chat/core/design/app_radii.dart';
import 'package:link_2_chat/core/design/app_spacing.dart';
import 'package:link_2_chat/features/teams/domain/team.dart';
import 'package:link_2_chat/features/teams/presentation/relative_date.dart';
import 'package:link_2_chat/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// One team in the list: the avatar row plus the description and the member
/// and created chips. Tapping opens the details screen.
class TeamCard extends StatelessWidget {
  const TeamCard({
    required this.team,
    required this.isOwner,
    required this.onTap,
    super.key,
  });

  final Team team;
  final bool isOwner;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context);
    return Card(
      margin: const EdgeInsetsDirectional.only(bottom: AppSpacing.md),
      clipBehavior: Clip.antiAlias,
      color: colors.card,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: colors.primary.withValues(alpha: 0.08),
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: colors.primary.withValues(alpha: 0.2),
                    child: Text(
                      team.name.isNotEmpty ? team.name[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          team.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: colors.text,
                          ),
                        ),
                        if (isOwner)
                          Text(
                            l10n.teamsOwner,
                            style: TextStyle(
                              color: colors.primary,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: colors.textMuted,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (team.description.isNotEmpty) ...[
                    Text(
                      team.description,
                      style: TextStyle(fontSize: 14, color: colors.text),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  Row(
                    children: [
                      _TeamInfoChip(
                        icon: Icons.people_outline,
                        value: '${team.members.length + 1}',
                        label: l10n.teamsMembers,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      _TeamInfoChip(
                        icon: Icons.calendar_today,
                        value: relativeDate(l10n, team.createdAt),
                        label: l10n.commonCreated,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The small grey "3 / Members" chip on a card.
class _TeamInfoChip extends StatelessWidget {
  const _TeamInfoChip({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.md,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: colors.page,
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colors.textMuted),
          const SizedBox(width: AppSpacing.xs),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colors.text,
                ),
              ),
              Text(
                label,
                style: TextStyle(fontSize: 10, color: colors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
