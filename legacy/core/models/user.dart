import 'package:hive/hive.dart';

@HiveType(typeId: 2)
class User {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String email;

  @HiveField(3)
  final String passwordHash; // we'll store a simple hash of the password

  @HiveField(4)
  final String role; // 'admin', 'member', 'viewer', etc.

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  final DateTime lastLoginAt;

  @HiveField(7)
  final List<String> teamIds; // IDs of teams the user belongs to

  @HiveField(8)
  final Map<String, List<String>> permissions; // teamId -> list of permissions

  @HiveField(9)
  final SubscriptionTier subscriptionTier;

  @HiveField(10)
  final DateTime? subscriptionExpiry;

  @HiveField(11)
  final Map<String, dynamic> preferences; // User preferences

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.passwordHash,
    this.role = 'member',
    required this.createdAt,
    required this.lastLoginAt,
    this.teamIds = const [],
    this.permissions = const {},
    this.subscriptionTier = SubscriptionTier.free,
    this.subscriptionExpiry,
    this.preferences = const {},
  });

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? passwordHash,
    String? role,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    List<String>? teamIds,
    Map<String, List<String>>? permissions,
    SubscriptionTier? subscriptionTier,
    DateTime? subscriptionExpiry,
    Map<String, dynamic>? preferences,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      teamIds: teamIds ?? this.teamIds,
      permissions: permissions ?? this.permissions,
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      subscriptionExpiry: subscriptionExpiry ?? this.subscriptionExpiry,
      preferences: preferences ?? this.preferences,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt.toIso8601String(),
      'teamIds': teamIds,
      'permissions': permissions,
      'subscriptionTier': subscriptionTier.name,
      'subscriptionExpiry': subscriptionExpiry?.toIso8601String(),
      'preferences': preferences,
    };
  }

  // Check if user has a specific permission in a team
  bool hasPermission(String teamId, String permission) {
    if (!permissions.containsKey(teamId)) return false;
    return permissions[teamId]!.contains(permission);
  }

  // Check if user is a member of a team
  bool isMemberOfTeam(String teamId) {
    return teamIds.contains(teamId);
  }

  // Check if subscription is active
  bool get hasActiveSubscription {
    if (subscriptionTier == SubscriptionTier.free) return true;
    return subscriptionExpiry != null &&
        subscriptionExpiry!.isAfter(DateTime.now());
  }
}

// Subscription tiers
@HiveType(typeId: 3)
enum SubscriptionTier {
  @HiveField(0)
  free,

  @HiveField(1)
  basic,

  @HiveField(2)
  professional,

  @HiveField(3)
  enterprise;

  // Features available per tier
  bool get canCreateTeams => this != free;
  bool get hasAdvancedAnalytics => this == professional || this == enterprise;
  bool get hasApiAccess => this == professional || this == enterprise;
  bool get hasUnlimitedHistory => this != free;
  bool get hasCustomBranding => this == enterprise;
  bool get hasPrioritySupport => this == enterprise;

  // Get limits based on tier
  int get maxTeamMembers {
    switch (this) {
      case free:
        return 0;
      case basic:
        return 5;
      case professional:
        return 20;
      case enterprise:
        return 100;
    }
  }

  int get maxHistoryItems {
    switch (this) {
      case free:
        return 50;
      case basic:
        return 500;
      case professional:
        return 5000;
      case enterprise:
        return 50000;
    }
  }
}

// Hive adapter
class UserAdapter extends TypeAdapter<User> {
  @override
  final typeId = 2;

  @override
  User read(BinaryReader reader) {
    return User(
      id: reader.read(),
      name: reader.read(),
      email: reader.read(),
      passwordHash: reader.read(),
      role: reader.read(),
      createdAt: reader.read(),
      lastLoginAt: reader.read(),
      teamIds: List<String>.from(reader.read() ?? []),
      permissions: Map<String, List<String>>.from(reader.read() ?? {}),
      subscriptionTier: reader.read() ?? SubscriptionTier.free,
      subscriptionExpiry: reader.read(),
      preferences: Map<String, dynamic>.from(reader.read() ?? {}),
    );
  }

  @override
  void write(BinaryWriter writer, User obj) {
    writer.write(obj.id);
    writer.write(obj.name);
    writer.write(obj.email);
    writer.write(obj.passwordHash);
    writer.write(obj.role);
    writer.write(obj.createdAt);
    writer.write(obj.lastLoginAt);
    writer.write(obj.teamIds);
    writer.write(obj.permissions);
    writer.write(obj.subscriptionTier);
    writer.write(obj.subscriptionExpiry);
    writer.write(obj.preferences);
  }
}

// Subscription tier adapter
class SubscriptionTierAdapter extends TypeAdapter<SubscriptionTier> {
  @override
  final typeId = 3;

  @override
  SubscriptionTier read(BinaryReader reader) {
    return SubscriptionTier.values[reader.readInt()];
  }

  @override
  void write(BinaryWriter writer, SubscriptionTier obj) {
    writer.writeInt(obj.index);
  }
}
