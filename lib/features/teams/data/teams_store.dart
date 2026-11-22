import 'dart:convert';

import 'package:link_2_chat/core/api/failure.dart';
import 'package:link_2_chat/core/json/json_reader.dart';
import 'package:link_2_chat/core/local_db/change_watcher.dart';
import 'package:link_2_chat/features/teams/domain/team.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

/// The teams and their members, in the `teams` and `team_members` tables.
/// Every write calls [ChangeWatcher.notify]; read failures throw
/// [StorageFailure], team rules (not the owner, already a member) throw
/// [AuthFailure]. The owner is not a `team_members` row: [Team.ownerId]
/// names them, exactly like the pre-refactor model.
class TeamsStore {
  const TeamsStore(this._db, this._watcher);

  final Database _db;
  final ChangeWatcher _watcher;

  /// Every team [userId] owns or belongs to, newest first.
  Future<List<Team>> teamsForUser(String userId) async {
    try {
      final owned = await _db.query(
        'teams',
        where: 'owner_id = ?',
        whereArgs: [userId],
      );
      final memberships = await _db.query(
        'team_members',
        where: 'user_id = ?',
        whereArgs: [userId],
      );
      final ids = {
        for (final row in owned) row['id'] as String,
        for (final row in memberships) row['team_id'] as String,
      };
      if (ids.isEmpty) return const [];
      final rows = await _db.query(
        'teams',
        where: 'id IN (${List.filled(ids.length, '?').join(', ')})',
        whereArgs: ids.toList(),
        orderBy: 'created_at DESC',
      );
      final teams = <Team>[];
      for (final row in rows) {
        final team = _team(row);
        teams.add(await _withMembers(team));
      }
      return teams;
    } on Object catch (error) {
      throw StorageFailure('teamsForUser failed: $error');
    }
  }

  /// The same as [teamsForUser], re-read after every write.
  Stream<List<Team>> watchTeamsForUser(String userId) =>
      _watcher.watch(() => teamsForUser(userId));

  /// The team with [id], or null when it is gone.
  Future<Team?> byId(String id) async {
    try {
      final rows = await _db.query(
        'teams',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      return await _withMembers(_team(rows.single));
    } on Object catch (error) {
      throw StorageFailure('byId failed: $error');
    }
  }

  /// The same as [byId], re-read after every write.
  Stream<Team?> watchById(String id) => _watcher.watch(() => byId(id));

  /// Creates a team owned by [ownerId]. Subscription gating (free accounts
  /// may not create teams) is the action layer's job, not the store's.
  Future<Team> create({
    required String name,
    required String description,
    required String ownerId,
  }) async {
    final team = Team(
      id: const Uuid().v4(),
      name: name.trim(),
      description: description.trim(),
      ownerId: ownerId,
      createdAt: DateTime.now(),
    );
    try {
      await _db.insert('teams', _row(team));
      _watcher.notify();
      return team;
    } on Object catch (error) {
      throw StorageFailure('create failed: $error');
    }
  }

  /// Deletes the team and, through the foreign key, its member rows. Only
  /// the owner may delete: anyone else gets [AuthFailure].
  Future<void> delete(String teamId, String requesterId) async {
    try {
      final team = await byId(teamId);
      if (team == null) return;
      if (team.ownerId != requesterId) {
        throw const AuthFailure('Only the team owner can delete a team.');
      }
      await _db.delete('teams', where: 'id = ?', whereArgs: [teamId]);
      _watcher.notify();
    } on Failure {
      rethrow;
    } on Object catch (error) {
      throw StorageFailure('delete failed: $error');
    }
  }

  /// Flips the owner-only switches of a team's settings.
  Future<void> updateSettings(String teamId, TeamSettings settings) async {
    try {
      await _db.update(
        'teams',
        {'settings': jsonEncode(_settingsJson(settings))},
        where: 'id = ?',
        whereArgs: [teamId],
      );
      _watcher.notify();
    } on Object catch (error) {
      throw StorageFailure('updateSettings failed: $error');
    }
  }

  /// Adds [email] to the team as [role]. A row for the same user or email in
  /// this team throws [AuthFailure]. [status] is `active` when [userId]
  /// belongs to a local account and `invited` for a placeholder member.
  Future<TeamMember> addMember({
    required String teamId,
    required String userId,
    required String name,
    required String email,
    TeamRole role = TeamRole.viewer,
    String status = 'active',
  }) async {
    final normalized = email.trim().toLowerCase();
    try {
      final existing = await _db.query(
        'team_members',
        where: 'team_id = ? AND (user_id = ? OR email = ?)',
        whereArgs: [teamId, userId, normalized],
        limit: 1,
      );
      if (existing.isNotEmpty) {
        throw const AuthFailure('This user is already a member of the team.');
      }
      final member = TeamMember(
        id: const Uuid().v4(),
        teamId: teamId,
        userId: userId,
        name: name.trim(),
        email: normalized,
        role: role,
        status: status,
        joinedAt: DateTime.now(),
      );
      await _db.insert('team_members', _memberRow(member));
      _watcher.notify();
      return member;
    } on Failure {
      rethrow;
    } on Object catch (error) {
      throw StorageFailure('addMember failed: $error');
    }
  }

  /// Moves [userId]'s membership in [teamId] to [role]. No-op when the
  /// membership is gone already.
  Future<void> updateMemberRole(
    String teamId,
    String userId,
    TeamRole role,
  ) async {
    try {
      await _db.update(
        'team_members',
        {'role': role.name},
        where: 'team_id = ? AND user_id = ?',
        whereArgs: [teamId, userId],
      );
      _watcher.notify();
    } on Object catch (error) {
      throw StorageFailure('updateMemberRole failed: $error');
    }
  }

  /// Removes [userId]'s membership row. Returns whether one was removed.
  Future<bool> removeMember(String teamId, String userId) async {
    try {
      final count = await _db.delete(
        'team_members',
        where: 'team_id = ? AND user_id = ?',
        whereArgs: [teamId, userId],
      );
      _watcher.notify();
      return count > 0;
    } on Object catch (error) {
      throw StorageFailure('removeMember failed: $error');
    }
  }

  // ------------------------------------------------------------------ reads

  Future<Team> _withMembers(Team team) async {
    final rows = await _db.query(
      'team_members',
      where: 'team_id = ?',
      whereArgs: [team.id],
      orderBy: 'joined_at ASC',
    );
    return Team(
      id: team.id,
      name: team.name,
      description: team.description,
      ownerId: team.ownerId,
      members: [for (final row in rows) _member(row)],
      createdAt: team.createdAt,
      logoUrl: team.logoUrl,
      settings: team.settings,
    );
  }

  Team _team(Map<Object?, Object?> row) {
    final r = JsonReader.of(row);
    final settingsJson = JsonReader.of(jsonDecode(r.string('settings')));
    final logo = r.stringOrNull('logo_url');
    return Team(
      id: r.string('id'),
      name: r.string('name'),
      description: r.string('description'),
      ownerId: r.string('owner_id'),
      createdAt: DateTime.fromMillisecondsSinceEpoch(r.integer('created_at')),
      logoUrl: logo,
      settings: TeamSettings(
        // The migration's default row is `{}`: absent means the default.
        allowMembersToInvite:
            settingsJson.has('allowMembersToInvite')
                ? settingsJson.boolean('allowMembersToInvite')
                : false,
        requireApprovalForLinks:
            settingsJson.has('requireApprovalForLinks')
                ? settingsJson.boolean('requireApprovalForLinks')
                : false,
      ),
    );
  }

  TeamMember _member(Map<Object?, Object?> row) {
    final r = JsonReader.of(row);
    return TeamMember(
      id: r.string('id'),
      teamId: r.string('team_id'),
      userId: r.string('user_id'),
      name: r.string('name'),
      email: r.string('email'),
      role: TeamRole.of(r.string('role')),
      status: r.string('status'),
      joinedAt: DateTime.fromMillisecondsSinceEpoch(r.integer('joined_at')),
    );
  }

  // ----------------------------------------------------------------- writes

  Map<String, Object?> _row(Team t) => {
    'id': t.id,
    'name': t.name,
    'description': t.description,
    'owner_id': t.ownerId,
    'logo_url': t.logoUrl,
    'settings': jsonEncode(_settingsJson(t.settings)),
    'created_at': t.createdAt.millisecondsSinceEpoch,
  };

  Map<String, Object?> _settingsJson(TeamSettings s) => {
    'allowMembersToInvite': s.allowMembersToInvite,
    'requireApprovalForLinks': s.requireApprovalForLinks,
  };

  Map<String, Object?> _memberRow(TeamMember m) => {
    'id': m.id,
    'team_id': m.teamId,
    'user_id': m.userId,
    'name': m.name,
    'email': m.email,
    'role': m.role.name,
    'status': m.status,
    'joined_at': m.joinedAt.millisecondsSinceEpoch,
  };
}
