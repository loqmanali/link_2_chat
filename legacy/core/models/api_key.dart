import 'package:hive/hive.dart';

@HiveType(typeId: 10)
class ApiKey {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String name;

  @HiveField(3)
  final String description;

  @HiveField(4)
  final String key;

  @HiveField(5)
  final List<ApiPermission> permissions;

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  final DateTime? lastUsedAt;

  @HiveField(8)
  final bool isActive;

  ApiKey({
    required this.id,
    required this.userId,
    required this.name,
    required this.description,
    required this.key,
    required this.permissions,
    required this.createdAt,
    this.lastUsedAt,
    required this.isActive,
  });

  ApiKey copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    String? key,
    List<ApiPermission>? permissions,
    DateTime? createdAt,
    DateTime? lastUsedAt,
    bool? isActive,
  }) {
    return ApiKey(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      key: key ?? this.key,
      permissions: permissions ?? this.permissions,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'description': description,
      'key': '${key.substring(0, 8)}...', // Don't expose full key in JSON
      'permissions': permissions.map((p) => p.name).toList(),
      'created_at': createdAt.toIso8601String(),
      'last_used_at': lastUsedAt?.toIso8601String(),
      'is_active': isActive,
    };
  }

  // Get the key with limited visibility for UI display
  String get maskedKey {
    if (key.length <= 16) return key;
    return '${key.substring(0, 8)}...${key.substring(key.length - 8)}';
  }
}

@HiveType(typeId: 11)
enum ApiPermission {
  @HiveField(0)
  generateLinks,

  @HiveField(1)
  viewAnalytics,

  @HiveField(2)
  viewHistory,

  @HiveField(3)
  exportData,

  @HiveField(4)
  viewTeamData,

  @HiveField(5)
  manageTeam;

  String get displayName {
    switch (this) {
      case ApiPermission.generateLinks:
        return 'Generate Links';
      case ApiPermission.viewAnalytics:
        return 'View Analytics';
      case ApiPermission.viewHistory:
        return 'View History';
      case ApiPermission.exportData:
        return 'Export Data';
      case ApiPermission.viewTeamData:
        return 'View Team Data';
      case ApiPermission.manageTeam:
        return 'Manage Team';
    }
  }

  String get description {
    switch (this) {
      case ApiPermission.generateLinks:
        return 'Create WhatsApp and Telegram chat links';
      case ApiPermission.viewAnalytics:
        return 'Access analytics and statistics';
      case ApiPermission.viewHistory:
        return 'View link generation history';
      case ApiPermission.exportData:
        return 'Export data in various formats';
      case ApiPermission.viewTeamData:
        return 'View team information and members';
      case ApiPermission.manageTeam:
        return 'Manage team settings and members';
    }
  }
}

// Hive adapters
class ApiKeyAdapter extends TypeAdapter<ApiKey> {
  @override
  final typeId = 10;

  @override
  ApiKey read(BinaryReader reader) {
    return ApiKey(
      id: reader.read(),
      userId: reader.read(),
      name: reader.read(),
      description: reader.read(),
      key: reader.read(),
      permissions: (reader.read() as List).cast<ApiPermission>(),
      createdAt: reader.read(),
      lastUsedAt: reader.read(),
      isActive: reader.read(),
    );
  }

  @override
  void write(BinaryWriter writer, ApiKey obj) {
    writer.write(obj.id);
    writer.write(obj.userId);
    writer.write(obj.name);
    writer.write(obj.description);
    writer.write(obj.key);
    writer.write(obj.permissions);
    writer.write(obj.createdAt);
    writer.write(obj.lastUsedAt);
    writer.write(obj.isActive);
  }
}

class ApiPermissionAdapter extends TypeAdapter<ApiPermission> {
  @override
  final typeId = 11;

  @override
  ApiPermission read(BinaryReader reader) {
    return ApiPermission.values[reader.readInt()];
  }

  @override
  void write(BinaryWriter writer, ApiPermission obj) {
    writer.writeInt(obj.index);
  }
}
