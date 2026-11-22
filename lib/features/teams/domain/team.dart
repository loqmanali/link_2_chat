/// The team domain: who belongs to a team, what each role may do, and the
/// team's settings. Pure Dart — no sqlite, no json. The store persists rows;
/// this file holds the rules carried over from the pre-refactor `Team`.
library;

/// The roles a member can hold. The owner is not a member row: [Team.ownerId]
/// names them, and they outrank every role.
enum TeamRole {
  owner,
  admin,
  editor,
  viewer;

  static TeamRole of(String name) => TeamRole.values.firstWhere(
    (role) => role.name == name,
    orElse: () => TeamRole.viewer,
  );

  /// Everything the role may do, owner excluded ([Team.userHasPermission]
  /// answers for the owner directly).
  Set<TeamPermission> get permissions => switch (this) {
    TeamRole.owner => TeamPermission.values.toSet(),
    TeamRole.admin => TeamPermission.values.toSet(),
    TeamRole.editor =>
      TeamPermission.values
          .where(
            (p) =>
                p != TeamPermission.manageTeam &&
                p != TeamPermission.deleteTeam,
          )
          .toSet(),
    TeamRole.viewer => {TeamPermission.viewContent},
  };
}

/// One thing a member may or may not do inside a team.
enum TeamPermission {
  viewContent,
  createLinks,
  editLinks,
  deleteLinks,
  viewAnalytics,
  exportData,
  inviteMembers,
  removeMembers,
  manageTeam,
  deleteTeam;

  static TeamPermission? of(String name) {
    for (final permission in TeamPermission.values) {
      if (permission.name == name) return permission;
    }
    return null;
  }
}

/// The switches a team's owner can flip on the details screen.
class TeamSettings {
  const TeamSettings({
    this.allowMembersToInvite = false,
    this.requireApprovalForLinks = false,
  });

  final bool allowMembersToInvite;
  final bool requireApprovalForLinks;

  TeamSettings copyWith({
    bool? allowMembersToInvite,
    bool? requireApprovalForLinks,
  }) => TeamSettings(
    allowMembersToInvite: allowMembersToInvite ?? this.allowMembersToInvite,
    requireApprovalForLinks:
        requireApprovalForLinks ?? this.requireApprovalForLinks,
  );

  @override
  bool operator ==(Object other) =>
      other is TeamSettings &&
      other.allowMembersToInvite == allowMembersToInvite &&
      other.requireApprovalForLinks == requireApprovalForLinks;

  @override
  int get hashCode =>
      Object.hash(allowMembersToInvite, requireApprovalForLinks);
}

/// A membership row: a person inside one team, with the role they were
/// invited to hold. [status] is `active` or `invited` (an invited member is a
/// placeholder until they sign in on this device).
class TeamMember {
  const TeamMember({
    required this.id,
    required this.teamId,
    required this.userId,
    required this.name,
    required this.email,
    this.role = TeamRole.viewer,
    this.status = 'active',
    required this.joinedAt,
  });

  final String id;
  final String teamId;
  final String userId;
  final String name;
  final String email;
  final TeamRole role;

  /// `active` for a local account, `invited` for a placeholder.
  final String status;
  final DateTime joinedAt;

  TeamMember copyWith({TeamRole? role, String? status}) => TeamMember(
    id: id,
    teamId: teamId,
    userId: userId,
    name: name,
    email: email,
    role: role ?? this.role,
    status: status ?? this.status,
    joinedAt: joinedAt,
  );
}

/// A team: one owner plus [members]. The owner is never in [members].
class Team {
  const Team({
    required this.id,
    required this.name,
    this.description = '',
    required this.ownerId,
    this.members = const [],
    required this.createdAt,
    this.logoUrl,
    this.settings = const TeamSettings(),
  });

  final String id;
  final String name;
  final String description;
  final String ownerId;
  final List<TeamMember> members;
  final DateTime createdAt;
  final String? logoUrl;
  final TeamSettings settings;

  /// Whether [userId] is the owner or any kind of member.
  bool hasMember(String userId) =>
      ownerId == userId || members.any((m) => m.userId == userId);

  /// The membership of [userId]; the owner comes back as a synthetic owner
  /// row without a database id.
  TeamMember? getMember(String userId) {
    if (ownerId == userId) {
      return TeamMember(
        id: '',
        teamId: id,
        userId: userId,
        name: '',
        email: '',
        role: TeamRole.owner,
        joinedAt: createdAt,
      );
    }
    for (final member in members) {
      if (member.userId == userId) return member;
    }
    return null;
  }

  /// Whether [userId] may do [permission] here: the owner and admins may do
  /// everything, editors everything but managing or deleting the team, and
  /// viewers only look.
  bool userHasPermission(String userId, TeamPermission permission) {
    if (ownerId == userId) return true;
    final member = getMember(userId);
    if (member == null) return false;
    return member.role.permissions.contains(permission);
  }

  @override
  String toString() => 'Team($name)';
}
