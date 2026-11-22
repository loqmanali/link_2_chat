import 'package:hive/hive.dart';

@HiveType(typeId: 4)
class Team {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final String ownerId; // User ID of the team owner

  @HiveField(4)
  final List<TeamMember> members;

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  final String? logoUrl;

  @HiveField(7)
  final TeamSettings settings;

  Team({
    required this.id,
    required this.name,
    this.description = '',
    required this.ownerId,
    this.members = const [],
    required this.createdAt,
    this.logoUrl,
    TeamSettings? settings,
  }) : settings = settings ?? TeamSettings();

  Team copyWith({
    String? id,
    String? name,
    String? description,
    String? ownerId,
    List<TeamMember>? members,
    DateTime? createdAt,
    String? logoUrl,
    TeamSettings? settings,
  }) {
    return Team(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      ownerId: ownerId ?? this.ownerId,
      members: members ?? this.members,
      createdAt: createdAt ?? this.createdAt,
      logoUrl: logoUrl ?? this.logoUrl,
      settings: settings ?? this.settings,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'ownerId': ownerId,
      'members': members.map((m) => m.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'logoUrl': logoUrl,
      'settings': settings.toJson(),
    };
  }

  // Check if a user is a member of this team
  bool hasMember(String userId) {
    return members.any((member) => member.userId == userId) ||
        ownerId == userId;
  }

  // Get a team member
  TeamMember? getMember(String userId) {
    if (ownerId == userId) {
      return TeamMember(userId: ownerId, role: TeamRole.owner);
    }

    final memberList =
        members.where((member) => member.userId == userId).toList();
    return memberList.isEmpty ? null : memberList.first;
  }

  // Check if a user has a specific permission
  bool userHasPermission(String userId, TeamPermission permission) {
    if (ownerId == userId) return true; // Owner has all permissions

    final member = getMember(userId);
    if (member == null) return false;

    // Check role-based permissions
    switch (member.role) {
      case TeamRole.owner:
        return true;
      case TeamRole.admin:
        return true; // Admins have all permissions
      case TeamRole.editor:
        // Editors can't manage team or delete it
        return permission != TeamPermission.manageTeam &&
            permission != TeamPermission.deleteTeam;
      case TeamRole.viewer:
        // Viewers can only view content
        return permission == TeamPermission.viewContent;
    }
  }
}

@HiveType(typeId: 5)
class TeamMember {
  @HiveField(0)
  final String userId;

  @HiveField(1)
  final TeamRole role;

  @HiveField(2)
  final DateTime joinedAt;

  @HiveField(3)
  final List<String> customPermissions;

  TeamMember({
    required this.userId,
    required this.role,
    DateTime? joinedAt,
    this.customPermissions = const [],
  }) : joinedAt = joinedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'role': role.name,
      'joinedAt': joinedAt.toIso8601String(),
      'customPermissions': customPermissions,
    };
  }
}

@HiveType(typeId: 6)
enum TeamRole {
  @HiveField(0)
  owner,

  @HiveField(1)
  admin,

  @HiveField(2)
  editor,

  @HiveField(3)
  viewer,
}

@HiveType(typeId: 7)
enum TeamPermission {
  @HiveField(0)
  viewContent,

  @HiveField(1)
  createLinks,

  @HiveField(2)
  editLinks,

  @HiveField(3)
  deleteLinks,

  @HiveField(4)
  viewAnalytics,

  @HiveField(5)
  exportData,

  @HiveField(6)
  inviteMembers,

  @HiveField(7)
  removeMembers,

  @HiveField(8)
  manageTeam,

  @HiveField(9)
  deleteTeam,
}

@HiveType(typeId: 8)
class TeamSettings {
  @HiveField(0)
  final bool allowMembersToInvite;

  @HiveField(1)
  final bool requireApprovalForLinks;

  @HiveField(2)
  final Map<String, dynamic> analyticsSettings;

  @HiveField(3)
  final Map<String, dynamic> customSettings;

  TeamSettings({
    this.allowMembersToInvite = false,
    this.requireApprovalForLinks = false,
    this.analyticsSettings = const {},
    this.customSettings = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'allowMembersToInvite': allowMembersToInvite,
      'requireApprovalForLinks': requireApprovalForLinks,
      'analyticsSettings': analyticsSettings,
      'customSettings': customSettings,
    };
  }

  TeamSettings copyWith({
    bool? allowMembersToInvite,
    bool? requireApprovalForLinks,
    Map<String, dynamic>? analyticsSettings,
    Map<String, dynamic>? customSettings,
  }) {
    return TeamSettings(
      allowMembersToInvite: allowMembersToInvite ?? this.allowMembersToInvite,
      requireApprovalForLinks:
          requireApprovalForLinks ?? this.requireApprovalForLinks,
      analyticsSettings: analyticsSettings ?? this.analyticsSettings,
      customSettings: customSettings ?? this.customSettings,
    );
  }
}

// Adapters for Hive
class TeamAdapter extends TypeAdapter<Team> {
  @override
  final typeId = 4;

  @override
  Team read(BinaryReader reader) {
    return Team(
      id: reader.read(),
      name: reader.read(),
      description: reader.read(),
      ownerId: reader.read(),
      members: List<TeamMember>.from(reader.read() ?? []),
      createdAt: reader.read(),
      logoUrl: reader.read(),
      settings: reader.read(),
    );
  }

  @override
  void write(BinaryWriter writer, Team obj) {
    writer.write(obj.id);
    writer.write(obj.name);
    writer.write(obj.description);
    writer.write(obj.ownerId);
    writer.write(obj.members);
    writer.write(obj.createdAt);
    writer.write(obj.logoUrl);
    writer.write(obj.settings);
  }
}

class TeamMemberAdapter extends TypeAdapter<TeamMember> {
  @override
  final typeId = 5;

  @override
  TeamMember read(BinaryReader reader) {
    return TeamMember(
      userId: reader.read(),
      role: reader.read(),
      joinedAt: reader.read(),
      customPermissions: List<String>.from(reader.read() ?? []),
    );
  }

  @override
  void write(BinaryWriter writer, TeamMember obj) {
    writer.write(obj.userId);
    writer.write(obj.role);
    writer.write(obj.joinedAt);
    writer.write(obj.customPermissions);
  }
}

class TeamRoleAdapter extends TypeAdapter<TeamRole> {
  @override
  final typeId = 6;

  @override
  TeamRole read(BinaryReader reader) {
    return TeamRole.values[reader.readInt()];
  }

  @override
  void write(BinaryWriter writer, TeamRole obj) {
    writer.writeInt(obj.index);
  }
}

class TeamPermissionAdapter extends TypeAdapter<TeamPermission> {
  @override
  final typeId = 7;

  @override
  TeamPermission read(BinaryReader reader) {
    return TeamPermission.values[reader.readInt()];
  }

  @override
  void write(BinaryWriter writer, TeamPermission obj) {
    writer.writeInt(obj.index);
  }
}

class TeamSettingsAdapter extends TypeAdapter<TeamSettings> {
  @override
  final typeId = 8;

  @override
  TeamSettings read(BinaryReader reader) {
    return TeamSettings(
      allowMembersToInvite: reader.read(),
      requireApprovalForLinks: reader.read(),
      analyticsSettings: Map<String, dynamic>.from(reader.read() ?? {}),
      customSettings: Map<String, dynamic>.from(reader.read() ?? {}),
    );
  }

  @override
  void write(BinaryWriter writer, TeamSettings obj) {
    writer.write(obj.allowMembersToInvite);
    writer.write(obj.requireApprovalForLinks);
    writer.write(obj.analyticsSettings);
    writer.write(obj.customSettings);
  }
}
