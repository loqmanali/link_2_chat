/// The subscription plans, carried over unchanged from the pre-refactor app.
enum SubscriptionTier {
  free,
  basic,
  professional,
  enterprise;

  static SubscriptionTier of(String name) => SubscriptionTier.values.firstWhere(
    (tier) => tier.name == name,
    orElse: () => SubscriptionTier.free,
  );
}

/// A device-local account. There is no server: the account lives in this
/// device's sqlite database, and its password hash is a plain sha256 of the
/// password — exactly the scheme the pre-refactor app used.
class User {
  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.passwordHash,
    this.role = 'member',
    this.subscriptionTier = SubscriptionTier.free,
    this.subscriptionExpiry,
    this.preferences = const {},
    required this.createdAt,
    this.lastLoginAt,
  });

  final String id;
  final String name;
  final String email;
  final String passwordHash;

  /// `member` today; kept because the UI badges read it.
  final String role;
  final SubscriptionTier subscriptionTier;
  final DateTime? subscriptionExpiry;
  final Map<String, String> preferences;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  /// Whether the subscription is a paid one and not expired.
  bool get isPremium {
    final paid = subscriptionTier != SubscriptionTier.free;
    final expiry = subscriptionExpiry;
    final expired = expiry != null && expiry.isBefore(DateTime.now());
    return paid && !expired;
  }

  User copyWith({
    String? name,
    String? passwordHash,
    String? role,
    SubscriptionTier? subscriptionTier,
    DateTime? subscriptionExpiry,
    Map<String, String>? preferences,
    DateTime? lastLoginAt,
  }) => User(
    id: id,
    name: name ?? this.name,
    email: email,
    passwordHash: passwordHash ?? this.passwordHash,
    role: role ?? this.role,
    subscriptionTier: subscriptionTier ?? this.subscriptionTier,
    subscriptionExpiry: subscriptionExpiry ?? this.subscriptionExpiry,
    preferences: preferences ?? this.preferences,
    createdAt: createdAt,
    lastLoginAt: lastLoginAt ?? this.lastLoginAt,
  );

  @override
  bool operator ==(Object other) =>
      other is User && other.id == id && other.lastLoginAt == lastLoginAt;

  @override
  int get hashCode => Object.hash(id, lastLoginAt);

  @override
  String toString() => 'User($email)';
}
