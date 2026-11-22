import 'package:link_2_chat/features/entries/domain/link_target.dart';

/// One generated link in the history.
class PhoneEntry {
  const PhoneEntry({
    required this.id,
    required this.userId,
    required this.phoneNumber,
    required this.countryCode,
    required this.countryName,
    required this.platform,
    required this.createdAt,
  });

  final String id;

  /// The account that generated it (a device-local user id).
  final String userId;

  /// The national number, as typed (digits only after validation).
  final String phoneNumber;
  final String countryCode;

  /// Display name of the country the code belongs to.
  final String countryName;
  final LinkPlatform platform;

  /// When the link was generated.
  final DateTime createdAt;

  /// The number with its country code, cleaned for a link.
  String get fullPhoneNumber => '$countryCode$phoneNumber';

  String get link => LinkTarget.forPlatform(fullPhoneNumber, platform);

  PhoneEntry copyWith({
    String? id,
    String? userId,
    String? phoneNumber,
    String? countryCode,
    String? countryName,
    LinkPlatform? platform,
    DateTime? createdAt,
  }) => PhoneEntry(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    phoneNumber: phoneNumber ?? this.phoneNumber,
    countryCode: countryCode ?? this.countryCode,
    countryName: countryName ?? this.countryName,
    platform: platform ?? this.platform,
    createdAt: createdAt ?? this.createdAt,
  );

  @override
  bool operator ==(Object other) =>
      other is PhoneEntry &&
      other.id == id &&
      other.userId == userId &&
      other.phoneNumber == phoneNumber &&
      other.countryCode == countryCode &&
      other.countryName == countryName &&
      other.platform == platform &&
      other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    phoneNumber,
    countryCode,
    countryName,
    platform,
    createdAt,
  );

  @override
  String toString() => 'PhoneEntry($platform $countryCode$phoneNumber)';
}
