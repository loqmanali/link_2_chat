import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/phone_entry.dart';
import '../models/user_stats.dart';
import 'sync_service.dart';

class AnalyticsService {
  static const String _phoneEntriesBoxName = 'phone_entries';
  static const String _statsBoxName = 'user_stats';
  static const String _userStatsKey = 'user_stats';

  static Box<PhoneEntry>? _entriesBox;
  static Box<UserStats>? _statsBox;

  static final SyncService _syncService = SyncService();

  /// Initialize the Hive boxes needed for the service
  static Future<void> init() async {
    if (!Hive.isBoxOpen(_phoneEntriesBoxName)) {
      _entriesBox = await Hive.openBox<PhoneEntry>(_phoneEntriesBoxName);
    }

    if (!Hive.isBoxOpen(_statsBoxName)) {
      _statsBox = await Hive.openBox<UserStats>(_statsBoxName);
    }

    // Initialize the sync service
    await _syncService.initialize();
  }

  /// Close Hive boxes if they are open
  static Future<void> close() async {
    await _entriesBox?.close();
    await _statsBox?.close();
  }

  /// Save a new phone entry and update statistics
  static Future<void> savePhoneEntry(PhoneEntry entry) async {
    await init();

    // Use the sync service to save the entry (handles both local and remote)
    await _syncService.savePhoneEntry(entry);

    // Update stats
    final currentStats = await getStats();
    final updatedStats = currentStats.addEntry(
      entry.countryCode,
      entry.platform,
    );
    await _statsBox?.put(_userStatsKey, updatedStats);

    // Update SharedPreferences for quick access to count
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('total_links', updatedStats.totalGeneratedLinks);
  }

  /// Get user statistics
  static Future<UserStats> getStats() async {
    await init();

    // Get or create stats
    final stats = _statsBox?.get(_userStatsKey);
    return stats ?? UserStats();
  }

  /// Get recent phone entries
  static Future<List<PhoneEntry>> getRecentEntries({int limit = 10}) async {
    await init();

    final entries = _entriesBox?.values.toList() ?? [];

    // Sort by timestamp descending (newest first)
    entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // Limit the number of entries
    return entries.take(limit).toList();
  }

  /// Get total number of links generated
  static Future<int> getTotalLinksCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('total_links') ?? 0;
  }

  /// Get top countries by usage
  static Future<List<MapEntry<String, int>>> getTopCountries({
    int limit = 5,
  }) async {
    final stats = await getStats();
    return stats.getTopCountries(limit);
  }

  /// Clear all stored data
  static Future<void> clearAllData() async {
    await init();

    await _entriesBox?.clear();
    await _statsBox?.clear();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('total_links');
  }

  /// Get sync status stream
  static Stream<SyncStatus> getSyncStatusStream() {
    return _syncService.syncStatusStream;
  }

  /// Manually trigger sync with server
  static Future<void> syncWithServer() async {
    await _syncService.scheduleSyncWithServer();
  }

  /// Check if currently syncing
  static bool isSyncing() {
    return _syncService.isSyncing;
  }
}
