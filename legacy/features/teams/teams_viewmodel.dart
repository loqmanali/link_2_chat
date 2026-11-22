import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/models/team.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/team_service.dart';

// Events
abstract class TeamsEvent {}

class LoadTeamsEvent extends TeamsEvent {}

class CreateTeamEvent extends TeamsEvent {
  final String name;
  final String description;

  CreateTeamEvent(this.name, this.description);
}

class DeleteTeamEvent extends TeamsEvent {
  final String teamId;

  DeleteTeamEvent(this.teamId);
}

// State
class TeamsState {
  final List<Team> teams;
  final bool isLoading;
  final String? error;

  TeamsState({required this.teams, this.isLoading = false, this.error});

  TeamsState copyWith({List<Team>? teams, bool? isLoading, String? error}) {
    return TeamsState(
      teams: teams ?? this.teams,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// BLoC
class TeamsBloc extends Bloc<TeamsEvent, TeamsState> {
  final TeamService _teamService = TeamService();
  final AuthService _authService = AuthService();

  TeamsBloc() : super(TeamsState(teams: [])) {
    on<LoadTeamsEvent>(_loadTeams);
    on<CreateTeamEvent>(_createTeam);
    on<DeleteTeamEvent>(_deleteTeam);
  }

  Future<void> _loadTeams(
    LoadTeamsEvent event,
    Emitter<TeamsState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true, error: null));

      final teams = await _teamService.getUserTeams();
      emit(state.copyWith(teams: teams, isLoading: false));
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          error: 'Failed to load teams: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _createTeam(
    CreateTeamEvent event,
    Emitter<TeamsState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true, error: null));

      // Get current user
      final currentUser = await _authService.getCurrentUser();

      if (currentUser == null) {
        emit(state.copyWith(isLoading: false, error: 'User not authenticated'));
        return;
      }

      // Check subscription tier
      if (!currentUser.subscriptionTier.canCreateTeams) {
        emit(
          state.copyWith(
            isLoading: false,
            error: 'Your subscription does not allow creating teams',
          ),
        );
        return;
      }

      // Create team
      final createdTeam = await _teamService.createTeam(
        event.name,
        event.description,
        currentUser,
      );

      if (createdTeam == null) {
        emit(state.copyWith(isLoading: false, error: 'Failed to create team'));
        return;
      }

      // Reload teams
      final teams = await _teamService.getUserTeams();
      emit(state.copyWith(teams: teams, isLoading: false));
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          error: 'Failed to create team: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _deleteTeam(
    DeleteTeamEvent event,
    Emitter<TeamsState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true, error: null));

      // Delete team
      final success = await _teamService.deleteTeam(event.teamId);

      if (!success) {
        emit(state.copyWith(isLoading: false, error: 'Failed to delete team'));
        return;
      }

      // Reload teams
      final teams = await _teamService.getUserTeams();
      emit(state.copyWith(teams: teams, isLoading: false));
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          error: 'Failed to delete team: ${e.toString()}',
        ),
      );
    }
  }
}
