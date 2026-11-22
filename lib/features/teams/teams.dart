/// The teams feature: teams owned or joined on this device. Other features
/// import this barrel only.
export 'package:link_2_chat/features/teams/application/teams_providers.dart'
    show
        teamsWatcherProvider,
        teamsStoreProvider,
        teamsProvider,
        TeamsState,
        teamByIdProvider,
        createTeamActionProvider,
        deleteTeamActionProvider,
        inviteMemberActionProvider,
        updateRoleActionProvider,
        removeMemberActionProvider,
        updateTeamSettingsActionProvider;
export 'package:link_2_chat/features/teams/domain/team.dart'
    show Team, TeamMember, TeamPermission, TeamRole, TeamSettings;
export 'package:link_2_chat/features/teams/presentation/routes.dart'
    show teamDetailsBase, teamDetailsSegment, teamDetailsPath, teamsRoutes;
export 'package:link_2_chat/features/teams/presentation/team_details_screen.dart'
    show TeamDetailsScreen;
export 'package:link_2_chat/features/teams/presentation/teams_screen.dart'
    show TeamsScreen;
