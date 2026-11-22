/// Aggregate usage counters for one account.
class UserStats {
  const UserStats({
    this.totalGeneratedLinks = 0,
    this.whatsappLinks = 0,
    this.telegramLinks = 0,
    Map<String, int>? countryUsage,
    this.lastUsed,
  }) : countryUsage = countryUsage ?? const {};

  final int totalGeneratedLinks;
  final int whatsappLinks;
  final int telegramLinks;

  /// Country dial code -> how many links used it.
  final Map<String, int> countryUsage;

  /// When the last link was generated; null before the first one.
  final DateTime? lastUsed;

  /// Whether anything has been generated yet.
  bool get isEmpty => totalGeneratedLinks == 0;

  /// The [limit] most-used countries, best first.
  List<MapEntry<String, int>> getTopCountries([int limit = 5]) {
    final list =
        countryUsage.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    return list.take(limit).toList();
  }

  /// A copy with one more generated link of [platform] from [countryCode].
  UserStats recorded({
    required String countryCode,
    required bool isWhatsapp,
    required DateTime at,
  }) {
    final updated = Map<String, int>.from(countryUsage)
      ..update(countryCode, (n) => n + 1, ifAbsent: () => 1);
    return UserStats(
      totalGeneratedLinks: totalGeneratedLinks + 1,
      whatsappLinks: whatsappLinks + (isWhatsapp ? 1 : 0),
      telegramLinks: telegramLinks + (isWhatsapp ? 0 : 1),
      countryUsage: updated,
      lastUsed: at,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is UserStats &&
      other.totalGeneratedLinks == totalGeneratedLinks &&
      other.whatsappLinks == whatsappLinks &&
      other.telegramLinks == telegramLinks &&
      other.lastUsed == lastUsed;

  @override
  int get hashCode =>
      Object.hash(totalGeneratedLinks, whatsappLinks, telegramLinks, lastUsed);

  @override
  String toString() => 'UserStats($totalGeneratedLinks links)';
}
