import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../core/models/team.dart';
import '../../core/models/user.dart';
import '../../core/services/auth_service.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/loading_indicator.dart';
import 'components/create_team_dialog.dart';
import 'components/team_card.dart';
import 'team_details_screen.dart';
import 'teams_viewmodel.dart';

class TeamsScreen extends HookWidget {
  const TeamsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final teamsBloc = useMemoized(() => TeamsBloc(), []);
    final authService = useMemoized(() => AuthService(), []);
    final currentUser = useState<User?>(null);

    // Load teams when screen is opened
    useEffect(() {
      teamsBloc.add(LoadTeamsEvent());
      _loadCurrentUser(authService, currentUser);
      return () {
        teamsBloc.close();
      };
    }, [teamsBloc]);

    return BlocProvider(
      create: (context) => teamsBloc,
      child: Scaffold(
        appBar: const CustomAppBar(title: 'Teams'),
        body: BlocBuilder<TeamsBloc, TeamsState>(
          builder: (context, state) {
            if (state.isLoading && state.teams.isEmpty) {
              return const LoadingIndicator(message: 'Loading teams...');
            }

            if (state.error != null && state.teams.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error: ${state.error}',
                      style: const TextStyle(fontSize: 18, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => teamsBloc.add(LoadTeamsEvent()),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (state.teams.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.group_outlined,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No teams yet',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Create a team to collaborate with others',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed:
                          () => _showCreateTeamDialog(
                            context,
                            teamsBloc,
                            currentUser.value,
                          ),
                      icon: const Icon(Icons.add),
                      label: const Text('Create Team'),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                teamsBloc.add(LoadTeamsEvent());
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Your Teams',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (currentUser
                                .value
                                ?.subscriptionTier
                                .canCreateTeams ==
                            true)
                          ElevatedButton.icon(
                            onPressed:
                                () => _showCreateTeamDialog(
                                  context,
                                  teamsBloc,
                                  currentUser.value,
                                ),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Create'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (!currentUser.value!.subscriptionTier.canCreateTeams)
                      const Card(
                        margin: EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Icon(Icons.star, color: Colors.amber),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Upgrade to a premium plan to create teams and collaborate with others',
                                  style: TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: state.teams.length,
                        itemBuilder: (context, index) {
                          final team = state.teams[index];
                          return TeamCard(
                            team: team,
                            isOwner: team.ownerId == currentUser.value?.id,
                            onTap: () => _navigateToTeamDetails(context, team),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _loadCurrentUser(
    AuthService authService,
    ValueNotifier<User?> currentUser,
  ) async {
    final user = await authService.getCurrentUser();
    currentUser.value = user;
  }

  void _showCreateTeamDialog(
    BuildContext context,
    TeamsBloc bloc,
    User? currentUser,
  ) {
    if (currentUser == null) return;

    showDialog(
      context: context,
      builder:
          (context) => CreateTeamDialog(
            onTeamCreated: (name, description) {
              bloc.add(CreateTeamEvent(name, description));
              Navigator.pop(context);
            },
          ),
    );
  }

  void _navigateToTeamDetails(BuildContext context, Team team) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TeamDetailsScreen(team: team)),
    );
  }
}
