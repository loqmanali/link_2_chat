import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:universal_html/html.dart' as html;

import '../models/phone_entry.dart';
import 'auth_service.dart';
import 'team_service.dart';

class EnhancedAnalyticsService {
  static const String _entriesBox = 'phone_entries';
  static const String _analyticsBox = 'analytics_data';

  // Singleton instance
  static final EnhancedAnalyticsService _instance =
      EnhancedAnalyticsService._internal();

  factory EnhancedAnalyticsService() => _instance;

  EnhancedAnalyticsService._internal();

  // Save an entry to analytics
  Future<void> savePhoneEntry(PhoneEntry entry, {String? teamId}) async {
    try {
      final box = await Hive.openBox<PhoneEntry>(_entriesBox);
      await box.add(entry);

      // Update team analytics if a teamId is provided
      if (teamId != null) {
        await _updateTeamAnalytics(teamId, entry);
      }

      // Update global usage statistics
      await _updateUsageStats(entry);
    } catch (e) {
      print('Error saving phone entry: $e');
    }
  }

  // Get all entries for a user
  Future<List<PhoneEntry>> getUserEntries({
    DateTime? startDate,
    DateTime? endDate,
    String? platform,
    String? countryCode,
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final box = await Hive.openBox<PhoneEntry>(_entriesBox);
      List<PhoneEntry> entries = box.values.toList();

      // Apply filters
      if (startDate != null) {
        entries = entries.where((e) => e.timestamp.isAfter(startDate)).toList();
      }

      if (endDate != null) {
        entries = entries.where((e) => e.timestamp.isBefore(endDate)).toList();
      }

      if (platform != null) {
        entries = entries.where((e) => e.platform == platform).toList();
      }

      if (countryCode != null) {
        entries = entries.where((e) => e.countryCode == countryCode).toList();
      }

      // Sort by date (newest first)
      entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      // Apply pagination
      if (entries.length > offset) {
        final end = offset + limit;
        entries = entries.sublist(
          offset,
          end < entries.length ? end : entries.length,
        );
      } else {
        entries = [];
      }

      return entries;
    } catch (e) {
      print('Error getting user entries: $e');
      return [];
    }
  }

  // Get team entries
  Future<List<PhoneEntry>> getTeamEntries(
    String teamId, {
    DateTime? startDate,
    DateTime? endDate,
    String? platform,
    String? countryCode,
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      // Get team data
      final teamService = TeamService();
      final team = await teamService.getTeam(teamId);

      if (team == null) return [];

      // Get entries for all team members
      final authService = AuthService();
      final owner = await authService.getUser(team.ownerId);

      List<PhoneEntry> allEntries = [];

      // Add owner's entries
      if (owner != null) {
        final box = await Hive.openBox<PhoneEntry>(_entriesBox);
        final entries = box.values.toList();
        // We would need to add user ID to PhoneEntry model to filter by user
        // For now, this is a placehol
        allEntries.addAll(entries);
      }

      // Apply filters
      if (startDate != null) {
        allEntries =
            allEntries.where((e) => e.timestamp.isAfter(startDate)).toList();
      }

      if (endDate != null) {
        allEntries =
            allEntries.where((e) => e.timestamp.isBefore(endDate)).toList();
      }

      if (platform != null) {
        allEntries = allEntries.where((e) => e.platform == platform).toList();
      }

      if (countryCode != null) {
        allEntries =
            allEntries.where((e) => e.countryCode == countryCode).toList();
      }

      // Sort by date (newest first)
      allEntries.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      // Apply pagination
      if (allEntries.length > offset) {
        final end = offset + limit;
        allEntries = allEntries.sublist(
          offset,
          end < allEntries.length ? end : allEntries.length,
        );
      } else {
        allEntries = [];
      }

      return allEntries;
    } catch (e) {
      print('Error getting team entries: $e');
      return [];
    }
  }

  // Get analytics data
  Future<Map<String, dynamic>> getAnalytics({
    DateTime? startDate,
    DateTime? endDate,
    String? platform,
    String? teamId,
  }) async {
    try {
      final now = DateTime.now();
      final start = startDate ?? now.subtract(const Duration(days: 30));
      final end = endDate ?? now;

      // Get entries based on filters
      List<PhoneEntry> entries;
      if (teamId != null) {
        entries = await getTeamEntries(
          teamId,
          startDate: start,
          endDate: end,
          platform: platform,
        );
      } else {
        entries = await getUserEntries(
          startDate: start,
          endDate: end,
          platform: platform,
        );
      }

      // Basic metrics
      final totalEntries = entries.length;
      final whatsappCount =
          entries.where((e) => e.platform == 'whatsapp').length;
      final telegramCount =
          entries.where((e) => e.platform == 'telegram').length;

      // Group by date for time series
      final dailyData = <String, int>{};
      final dateFormat = DateFormat('yyyy-MM-dd');

      // Initialize daily data with zeros for all dates in the range
      for (
        var day = start;
        day.isBefore(end.add(const Duration(days: 1)));
        day = day.add(const Duration(days: 1))
      ) {
        dailyData[dateFormat.format(day)] = 0;
      }

      // Count entries by day
      for (final entry in entries) {
        final day = dateFormat.format(entry.timestamp);
        dailyData[day] = (dailyData[day] ?? 0) + 1;
      }

      // Group by country
      final countryData = <String, int>{};
      for (final entry in entries) {
        countryData[entry.countryName] =
            (countryData[entry.countryName] ?? 0) + 1;
      }

      // Group by hour of day
      final hourlyData = List<int>.filled(24, 0);
      for (final entry in entries) {
        final hour = entry.timestamp.hour;
        hourlyData[hour]++;
      }

      // Group by weekday
      final weekdayData = List<int>.filled(7, 0);
      for (final entry in entries) {
        final weekday = entry.timestamp.weekday - 1; // 0 = Monday, 6 = Sunday
        weekdayData[weekday]++;
      }

      // Create the analytics data object
      return {
        'totalEntries': totalEntries,
        'platforms': {'whatsapp': whatsappCount, 'telegram': telegramCount},
        'dailyData': dailyData,
        'countryData': countryData,
        'hourlyData': hourlyData,
        'weekdayData': weekdayData,
        'startDate': start.toIso8601String(),
        'endDate': end.toIso8601String(),
      };
    } catch (e) {
      print('Error getting analytics: $e');
      return {};
    }
  }

  // Export data to CSV
  Future<void> exportToCsv({
    DateTime? startDate,
    DateTime? endDate,
    String? platform,
    String? teamId,
  }) async {
    try {
      // Get entries
      List<PhoneEntry> entries;
      if (teamId != null) {
        entries = await getTeamEntries(
          teamId,
          startDate: startDate,
          endDate: endDate,
          platform: platform,
        );
      } else {
        entries = await getUserEntries(
          startDate: startDate,
          endDate: endDate,
          platform: platform,
        );
      }

      // Create CSV header
      final csv = StringBuffer();
      csv.writeln('Phone Number,Country Code,Country Name,Platform,Timestamp');

      // Add entries
      for (final entry in entries) {
        csv.writeln(
          '${entry.phoneNumber},${entry.countryCode},${entry.countryName},${entry.platform},${entry.timestamp.toIso8601String()}',
        );
      }

      // Trigger download
      _downloadFile(
        csv.toString(),
        'link2chat_export_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv',
      );
    } catch (e) {
      print('Error exporting to CSV: $e');
    }
  }

  // Export data to JSON
  Future<void> exportToJson({
    DateTime? startDate,
    DateTime? endDate,
    String? platform,
    String? teamId,
    bool includeAnalytics = true,
  }) async {
    try {
      // Get entries
      List<PhoneEntry> entries;
      if (teamId != null) {
        entries = await getTeamEntries(
          teamId,
          startDate: startDate,
          endDate: endDate,
          platform: platform,
        );
      } else {
        entries = await getUserEntries(
          startDate: startDate,
          endDate: endDate,
          platform: platform,
        );
      }

      final Map<String, dynamic> exportData = {
        'entries': entries.map((e) => e.toJson()).toList(),
      };

      // Include analytics if requested
      if (includeAnalytics) {
        exportData['analytics'] = await getAnalytics(
          startDate: startDate,
          endDate: endDate,
          platform: platform,
          teamId: teamId,
        );
      }

      // Trigger download
      final jsonData = json.encode(exportData);
      _downloadFile(
        jsonData,
        'link2chat_export_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.json',
      );
    } catch (e) {
      print('Error exporting to JSON: $e');
    }
  }

  // Helper method to trigger download
  void _downloadFile(String content, String filename) {
    if (kIsWeb) {
      final blob = html.Blob([content]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', filename)
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      // Handle native platforms if needed
      print('File download is only supported on web platforms');
    }
  }

  // Update team analytics
  Future<void> _updateTeamAnalytics(String teamId, PhoneEntry entry) async {
    try {
      final box = await Hive.openBox<Map>(_analyticsBox);
      final key = 'team_$teamId';

      // Get existing data or create new
      final data = Map<String, dynamic>.from(box.get(key) ?? {});

      // Update total count
      data['totalEntries'] = (data['totalEntries'] ?? 0) + 1;

      // Update platform counts
      final platforms = Map<String, int>.from(data['platforms'] ?? {});
      platforms[entry.platform] = (platforms[entry.platform] ?? 0) + 1;
      data['platforms'] = platforms;

      // Update country counts
      final countries = Map<String, int>.from(data['countries'] ?? {});
      countries[entry.countryName] = (countries[entry.countryName] ?? 0) + 1;
      data['countries'] = countries;

      // Update recent entries
      List<Map<String, dynamic>> recentEntries =
          List<Map<String, dynamic>>.from(data['recentEntries'] ?? []);

      recentEntries.insert(0, entry.toJson());
      if (recentEntries.length > 10) {
        recentEntries = recentEntries.sublist(0, 10);
      }

      data['recentEntries'] = recentEntries;

      // Save updated data
      await box.put(key, data);
    } catch (e) {
      print('Error updating team analytics: $e');
    }
  }

  // Update global usage statistics
  Future<void> _updateUsageStats(PhoneEntry entry) async {
    try {
      final box = await Hive.openBox<Map>(_analyticsBox);
      final key = 'global_stats';

      // Get existing data or create new
      final data = Map<String, dynamic>.from(box.get(key) ?? {});

      // Update total count
      data['totalEntries'] = (data['totalEntries'] ?? 0) + 1;

      // Update platform counts
      final platforms = Map<String, int>.from(data['platforms'] ?? {});
      platforms[entry.platform] = (platforms[entry.platform] ?? 0) + 1;
      data['platforms'] = platforms;

      // Update country counts
      final countries = Map<String, int>.from(data['countries'] ?? {});
      countries[entry.countryName] = (countries[entry.countryName] ?? 0) + 1;
      data['countries'] = countries;

      // Update daily counts
      final date = DateFormat('yyyy-MM-dd').format(entry.timestamp);
      final dailyCounts = Map<String, int>.from(data['dailyCounts'] ?? {});
      dailyCounts[date] = (dailyCounts[date] ?? 0) + 1;
      data['dailyCounts'] = dailyCounts;

      // Save updated data
      await box.put(key, data);
    } catch (e) {
      print('Error updating global usage stats: $e');
    }
  }
}
