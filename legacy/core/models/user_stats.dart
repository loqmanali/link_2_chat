import 'package:hive/hive.dart';

@HiveType(typeId: 1)
class UserStats {
  @HiveField(0)
  final int totalGeneratedLinks;

  @HiveField(1)
  final int whatsappLinks;

  @HiveField(2)
  final int telegramLinks;

  @HiveField(3)
  final Map<String, int> countryUsage; // Country code -> count

  @HiveField(4)
  final DateTime lastUsed;

  UserStats({
    this.totalGeneratedLinks = 0,
    this.whatsappLinks = 0,
    this.telegramLinks = 0,
    Map<String, int>? countryUsage,
    DateTime? lastUsed,
  }) : countryUsage = countryUsage ?? {},
       lastUsed = lastUsed ?? DateTime.now();

  // Add a new phone entry to statistics
  UserStats addEntry(String countryCode, String platform) {
    // Update country usage
    final updatedCountryUsage = Map<String, int>.from(countryUsage);
    updatedCountryUsage[countryCode] =
        (updatedCountryUsage[countryCode] ?? 0) + 1;

    // Return updated stats
    return UserStats(
      totalGeneratedLinks: totalGeneratedLinks + 1,
      whatsappLinks: whatsappLinks + (platform == 'whatsapp' ? 1 : 0),
      telegramLinks: telegramLinks + (platform == 'telegram' ? 1 : 0),
      countryUsage: updatedCountryUsage,
      lastUsed: DateTime.now(),
    );
  }

  // Get top countries by usage
  List<MapEntry<String, int>> getTopCountries([int limit = 5]) {
    final list =
        countryUsage.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    return list.take(limit).toList();
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'totalGeneratedLinks': totalGeneratedLinks,
      'whatsappLinks': whatsappLinks,
      'telegramLinks': telegramLinks,
      'countryUsage': countryUsage,
      'lastUsed': lastUsed.toIso8601String(),
    };
  }

  // Create from JSON
  factory UserStats.fromJson(Map<String, dynamic> json) {
    final countryUsageMap = (json['countryUsage'] as Map).cast<String, int>();

    return UserStats(
      totalGeneratedLinks: json['totalGeneratedLinks'],
      whatsappLinks: json['whatsappLinks'],
      telegramLinks: json['telegramLinks'],
      countryUsage: countryUsageMap,
      lastUsed: DateTime.parse(json['lastUsed']),
    );
  }
}

// Manual adapter implementation for Hive
class UserStatsAdapter extends TypeAdapter<UserStats> {
  @override
  final typeId = 1;

  @override
  UserStats read(BinaryReader reader) {
    return UserStats(
      totalGeneratedLinks: reader.read(),
      whatsappLinks: reader.read(),
      telegramLinks: reader.read(),
      countryUsage: Map<String, int>.from(reader.read()),
      lastUsed: reader.read(),
    );
  }

  @override
  void write(BinaryWriter writer, UserStats obj) {
    writer.write(obj.totalGeneratedLinks);
    writer.write(obj.whatsappLinks);
    writer.write(obj.telegramLinks);
    writer.write(obj.countryUsage);
    writer.write(obj.lastUsed);
  }
}
