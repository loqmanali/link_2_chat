/// The API-key domain. Pure Dart: the store persists rows, this file holds
/// the shape carried over from the pre-refactor `ApiKey` (its permission
/// display strings live in the presentation's l10n mapping now).
library;

/// What an API key may do on behalf of its owner.
enum ApiPermission {
  generateLinks,
  viewAnalytics,
  viewHistory,
  exportData,
  viewTeamData,
  manageTeam;

  static ApiPermission? of(String name) {
    for (final permission in ApiPermission.values) {
      if (permission.name == name) return permission;
    }
    return null;
  }
}

/// A key the user hands to an external integration. The full key lives only
/// in this device's database; the UI shows it once at creation and masks it
/// afterwards.
class ApiKey {
  const ApiKey({
    required this.id,
    required this.userId,
    required this.name,
    this.description = '',
    required this.key,
    this.permissions = const [],
    required this.createdAt,
    this.lastUsedAt,
    this.isActive = true,
  });

  final String id;
  final String userId;
  final String name;
  final String description;
  final String key;
  final List<ApiPermission> permissions;
  final DateTime createdAt;
  final DateTime? lastUsedAt;
  final bool isActive;

  /// The key as the cards show it: head and tail with the middle hidden,
  /// exactly the pre-refactor masking.
  String get maskedKey {
    if (key.length <= 16) return key;
    return '${key.substring(0, 8)}...${key.substring(key.length - 8)}';
  }

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
  }) => ApiKey(
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
