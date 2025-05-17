import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../models/team.dart';
import '../models/user.dart';
import 'auth_service.dart';

class TeamService {
  static const String _boxName = 'teams';

  // Singleton instance
  static final TeamService _instance = TeamService._internal();

  factory TeamService() => _instance;

  TeamService._internal();

  // Get all teams the current user is a member of
  Future<List<Team>> getUserTeams() async {
    try {
      final currentUser = await AuthService().getCurrentUser();
      if (currentUser == null) return [];

      final box = await Hive.openBox<Team>(_boxName);
      final allTeams = box.values.toList();

      // Filter teams where the user is a member or owner
      return allTeams
          .where(
            (team) =>
                team.ownerId == currentUser.id ||
                currentUser.teamIds.contains(team.id),
          )
          .toList();
    } catch (e) {
      print('Error getting user teams: $e');
      return [];
    }
  }

  // Get a specific team by ID
  Future<Team?> getTeam(String teamId) async {
    try {
      final box = await Hive.openBox<Team>(_boxName);
      return box.get(teamId);
    } catch (e) {
      print('Error getting team: $e');
      return null;
    }
  }

  // Create a new team
  Future<Team?> createTeam(String name, String description, User owner) async {
    try {
      // Check if user can create teams based on subscription
      if (!owner.subscriptionTier.canCreateTeams) {
        throw Exception('Your subscription does not allow creating teams');
      }

      final box = await Hive.openBox<Team>(_boxName);

      final team = Team(
        id: const Uuid().v4(),
        name: name,
        description: description,
        ownerId: owner.id,
        createdAt: DateTime.now(),
      );

      await box.put(team.id, team);

      // Update user's teamIds
      final authService = AuthService();
      final updatedUser = owner.copyWith(teamIds: [...owner.teamIds, team.id]);

      await authService.updateUser(updatedUser);

      return team;
    } catch (e) {
      print('Error creating team: $e');
      return null;
    }
  }

  // Update team details
  Future<Team?> updateTeam(
    String teamId, {
    String? name,
    String? description,
    String? logoUrl,
    TeamSettings? settings,
  }) async {
    try {
      final box = await Hive.openBox<Team>(_boxName);
      final team = box.get(teamId);

      if (team == null) return null;

      final updatedTeam = team.copyWith(
        name: name ?? team.name,
        description: description ?? team.description,
        logoUrl: logoUrl ?? team.logoUrl,
        settings: settings ?? team.settings,
      );

      await box.put(teamId, updatedTeam);
      return updatedTeam;
    } catch (e) {
      print('Error updating team: $e');
      return null;
    }
  }

  // Delete a team
  Future<bool> deleteTeam(String teamId) async {
    try {
      final box = await Hive.openBox<Team>(_boxName);
      final team = box.get(teamId);

      if (team == null) return false;

      // Remove team from all members' teamIds
      final authService = AuthService();

      // Get all users
      final allUsers = await authService.getAllUsers();

      // Update users who are members of this team
      for (final user in allUsers) {
        if (user.teamIds.contains(teamId)) {
          final updatedTeamIds = [...user.teamIds]..remove(teamId);
          await authService.updateUser(user.copyWith(teamIds: updatedTeamIds));
        }
      }

      // Delete the team
      await box.delete(teamId);
      return true;
    } catch (e) {
      print('Error deleting team: $e');
      return false;
    }
  }

  // Add a member to a team
  Future<bool> addTeamMember(
    String teamId,
    String userId,
    TeamRole role,
  ) async {
    try {
      final box = await Hive.openBox<Team>(_boxName);
      final team = box.get(teamId);
      final authService = AuthService();
      final user = await authService.getUser(userId);

      if (team == null || user == null) return false;

      // Check if user is already a member
      if (team.hasMember(userId)) return false;

      // Add user to team
      final teamMember = TeamMember(
        userId: userId,
        role: role,
        joinedAt: DateTime.now(),
      );

      final updatedMembers = [...team.members, teamMember];
      await box.put(teamId, team.copyWith(members: updatedMembers));

      // Add team to user's teamIds
      if (!user.teamIds.contains(teamId)) {
        final updatedTeamIds = [...user.teamIds, teamId];
        await authService.updateUser(user.copyWith(teamIds: updatedTeamIds));
      }

      return true;
    } catch (e) {
      print('Error adding team member: $e');
      return false;
    }
  }

  // Update a team member's role
  Future<bool> updateTeamMemberRole(
    String teamId,
    String userId,
    TeamRole newRole,
  ) async {
    try {
      final box = await Hive.openBox<Team>(_boxName);
      final team = box.get(teamId);

      if (team == null) return false;

      // Find the member
      final memberIndex = team.members.indexWhere((m) => m.userId == userId);
      if (memberIndex == -1) return false;

      // Update the member's role
      final updatedMembers = [...team.members];
      updatedMembers[memberIndex] = TeamMember(
        userId: userId,
        role: newRole,
        joinedAt: team.members[memberIndex].joinedAt,
        customPermissions: team.members[memberIndex].customPermissions,
      );

      await box.put(teamId, team.copyWith(members: updatedMembers));
      return true;
    } catch (e) {
      print('Error updating team member role: $e');
      return false;
    }
  }

  // Remove a member from a team
  Future<bool> removeTeamMember(String teamId, String userId) async {
    try {
      final box = await Hive.openBox<Team>(_boxName);
      final team = box.get(teamId);

      if (team == null) return false;

      // Check if the user is the owner
      if (team.ownerId == userId) {
        throw Exception("Cannot remove the team owner");
      }

      // Remove the member
      final updatedMembers =
          team.members.where((m) => m.userId != userId).toList();
      await box.put(teamId, team.copyWith(members: updatedMembers));

      // Remove team from user's teamIds
      final authService = AuthService();
      final user = await authService.getUser(userId);

      if (user != null && user.teamIds.contains(teamId)) {
        final updatedTeamIds = [...user.teamIds]..remove(teamId);
        await authService.updateUser(user.copyWith(teamIds: updatedTeamIds));
      }

      return true;
    } catch (e) {
      print('Error removing team member: $e');
      return false;
    }
  }

  // Check if a user has permission to perform an action on a team
  Future<bool> userHasPermission(
    String teamId,
    String userId,
    TeamPermission permission,
  ) async {
    try {
      final team = await getTeam(teamId);
      if (team == null) return false;

      return team.userHasPermission(userId, permission);
    } catch (e) {
      print('Error checking permission: $e');
      return false;
    }
  }
}
