import 'package:hive/hive.dart';

@HiveType(typeId: 0)
class PhoneEntry {
  @HiveField(0)
  final String phoneNumber;

  @HiveField(1)
  final String countryCode;

  @HiveField(2)
  final String countryName;

  @HiveField(3)
  final DateTime timestamp;

  @HiveField(4)
  final String platform; // "whatsapp" or "telegram"

  PhoneEntry({
    required this.phoneNumber,
    required this.countryCode,
    required this.countryName,
    required this.timestamp,
    required this.platform,
  });

  // Create a full phone number including country code
  String get fullPhoneNumber => '$countryCode$phoneNumber';

  // Generate WhatsApp link
  String get whatsappLink =>
      'https://wa.me/${fullPhoneNumber.replaceAll('+', '')}';

  // Generate Telegram link
  String get telegramLink =>
      'https://t.me/${fullPhoneNumber.replaceAll('+', '')}';

  // Get the actual link based on the platform
  String get link => platform == 'whatsapp' ? whatsappLink : telegramLink;

  // Factory method to create a copy with different values
  PhoneEntry copyWith({
    String? phoneNumber,
    String? countryCode,
    String? countryName,
    DateTime? timestamp,
    String? platform,
  }) {
    return PhoneEntry(
      phoneNumber: phoneNumber ?? this.phoneNumber,
      countryCode: countryCode ?? this.countryCode,
      countryName: countryName ?? this.countryName,
      timestamp: timestamp ?? this.timestamp,
      platform: platform ?? this.platform,
    );
  }

  // Convert to JSON format
  Map<String, dynamic> toJson() {
    return {
      'phoneNumber': phoneNumber,
      'countryCode': countryCode,
      'countryName': countryName,
      'timestamp': timestamp.toIso8601String(),
      'platform': platform,
    };
  }

  // Create from JSON
  factory PhoneEntry.fromJson(Map<String, dynamic> json) {
    return PhoneEntry(
      phoneNumber: json['phoneNumber'],
      countryCode: json['countryCode'],
      countryName: json['countryName'],
      timestamp: DateTime.parse(json['timestamp']),
      platform: json['platform'],
    );
  }
}

// Manual adapter implementation for Hive
class PhoneEntryAdapter extends TypeAdapter<PhoneEntry> {
  @override
  final typeId = 0;

  @override
  PhoneEntry read(BinaryReader reader) {
    return PhoneEntry(
      phoneNumber: reader.read(),
      countryCode: reader.read(),
      countryName: reader.read(),
      timestamp: reader.read(),
      platform: reader.read(),
    );
  }

  @override
  void write(BinaryWriter writer, PhoneEntry obj) {
    writer.write(obj.phoneNumber);
    writer.write(obj.countryCode);
    writer.write(obj.countryName);
    writer.write(obj.timestamp);
    writer.write(obj.platform);
  }
}
