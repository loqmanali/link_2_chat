import 'package:go_router/go_router.dart';
import 'package:link_2_chat/features/teams/presentation/team_details_screen.dart';

/// The details route lives under `/teams`, with the id as the parameter —
/// exactly the shape `AppPaths.teamDetails(teamId)` builds.
const String teamDetailsBase = '/teams';
const String teamDetailsSegment = 'details';

/// `/teams/details/<teamId>`.
String teamDetailsPath(String teamId) =>
    '$teamDetailsBase/$teamDetailsSegment/$teamId';

/// The route list the app router spreads in.
final List<RouteBase> teamsRoutes = [
  GoRoute(
    path: '$teamDetailsBase/$teamDetailsSegment/:teamId',
    builder:
        (context, state) =>
            TeamDetailsScreen(teamId: state.pathParameters['teamId']!),
  ),
];
