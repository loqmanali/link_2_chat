import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../models/api_key.dart';
import '../models/phone_entry.dart';
import 'auth_service.dart';
import 'team_service.dart';

class ApiService {
  static const String _apiKeysBox = 'api_keys';

  // Singleton instance
  static final ApiService _instance = ApiService._internal();

  factory ApiService() => _instance;

  ApiService._internal();

  // Generate a new API key for a user
  Future<ApiKey?> generateApiKey(
    String userId,
    String name,
    String description,
    List<ApiPermission> permissions,
  ) async {
    try {
      final box = await Hive.openBox<ApiKey>(_apiKeysBox);

      // Check if user exists
      final authService = AuthService();
      final user = await authService.getUser(userId);

      if (user == null) {
        return null;
      }

      // Check if user can create API keys based on subscription
      if (!user.subscriptionTier.hasApiAccess) {
        throw Exception('Your subscription does not allow API access');
      }

      // Generate API key (in a real app, this would be more secure)
      final keyString = _generateSecureToken();

      final apiKey = ApiKey(
        id: const Uuid().v4(),
        userId: userId,
        name: name,
        description: description,
        key: keyString,
        permissions: permissions,
        createdAt: DateTime.now(),
        lastUsedAt: null,
        isActive: true,
      );

      await box.put(apiKey.id, apiKey);

      return apiKey;
    } catch (e) {
      print('Error generating API key: $e');
      return null;
    }
  }

  // Get all API keys for a user
  Future<List<ApiKey>> getUserApiKeys(String userId) async {
    try {
      final box = await Hive.openBox<ApiKey>(_apiKeysBox);

      return box.values.where((key) => key.userId == userId).toList();
    } catch (e) {
      print('Error getting user API keys: $e');
      return [];
    }
  }

  // Update an API key
  Future<ApiKey?> updateApiKey(
    String keyId, {
    String? name,
    String? description,
    List<ApiPermission>? permissions,
    bool? isActive,
    DateTime? lastUsedAt,
  }) async {
    try {
      final box = await Hive.openBox<ApiKey>(_apiKeysBox);
      final apiKey = box.get(keyId);

      if (apiKey == null) {
        return null;
      }

      final updatedKey = apiKey.copyWith(
        name: name ?? apiKey.name,
        description: description ?? apiKey.description,
        permissions: permissions ?? apiKey.permissions,
        isActive: isActive ?? apiKey.isActive,
        lastUsedAt: lastUsedAt ?? apiKey.lastUsedAt,
      );

      await box.put(keyId, updatedKey);

      return updatedKey;
    } catch (e) {
      print('Error updating API key: $e');
      return null;
    }
  }

  // Delete an API key
  Future<bool> deleteApiKey(String keyId) async {
    try {
      final box = await Hive.openBox<ApiKey>(_apiKeysBox);

      await box.delete(keyId);

      return true;
    } catch (e) {
      print('Error deleting API key: $e');
      return false;
    }
  }

  // Verify an API key and check permissions
  Future<bool> verifyApiKey(String keyString, ApiPermission permission) async {
    try {
      final box = await Hive.openBox<ApiKey>(_apiKeysBox);

      // Find the key that matches
      final keys = box.values.where((key) => key.key == keyString).toList();

      if (keys.isEmpty) {
        return false;
      }

      final apiKey = keys.first;

      // Check if key is active
      if (!apiKey.isActive) {
        return false;
      }

      // Check user subscription
      final authService = AuthService();
      final user = await authService.getUser(apiKey.userId);

      if (user == null ||
          !user.hasActiveSubscription ||
          !user.subscriptionTier.hasApiAccess) {
        return false;
      }

      // Check permissions
      if (!apiKey.permissions.contains(permission)) {
        return false;
      }

      // Update last used timestamp
      await updateApiKey(apiKey.id, lastUsedAt: DateTime.now());

      return true;
    } catch (e) {
      print('Error verifying API key: $e');
      return false;
    }
  }

  // API endpoint: Generate a link
  Future<Map<String, dynamic>> generateLink(
    String apiKey,
    String phoneNumber,
    String platform,
  ) async {
    try {
      // Verify API key has permission
      final hasPermission = await verifyApiKey(
        apiKey,
        ApiPermission.generateLinks,
      );

      if (!hasPermission) {
        return {
          'success': false,
          'error': 'Invalid API key or insufficient permissions',
        };
      }

      // Generate link based on platform
      String link;

      if (platform.toLowerCase() == 'whatsapp') {
        // Remove any non-digit characters
        final cleanNumber = phoneNumber.replaceAll(RegExp(r'\D'), '');
        link = 'https://wa.me/$cleanNumber';
      } else if (platform.toLowerCase() == 'telegram') {
        // Remove any non-digit characters
        final cleanNumber = phoneNumber.replaceAll(RegExp(r'\D'), '');
        link = 'https://t.me/$cleanNumber';
      } else {
        return {
          'success': false,
          'error': 'Invalid platform. Use "whatsapp" or "telegram"',
        };
      }

      return {
        'success': true,
        'data': {
          'platform': platform.toLowerCase(),
          'phone_number': phoneNumber,
          'link': link,
          'generated_at': DateTime.now().toIso8601String(),
        },
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Error generating link: ${e.toString()}',
      };
    }
  }

  // API endpoint: Get user history
  Future<Map<String, dynamic>> getUserHistory(
    String apiKey, {
    int limit = 10,
    int offset = 0,
  }) async {
    try {
      // Verify API key has permission
      final hasPermission = await verifyApiKey(
        apiKey,
        ApiPermission.viewHistory,
      );

      if (!hasPermission) {
        return {
          'success': false,
          'error': 'Invalid API key or insufficient permissions',
        };
      }

      // Find the API key to get the user ID
      final box = await Hive.openBox<ApiKey>(_apiKeysBox);
      final keys = box.values.where((key) => key.key == apiKey).toList();

      if (keys.isEmpty) {
        return {'success': false, 'error': 'Invalid API key'};
      }

      // Get user's history from Hive
      final entriesBox = await Hive.openBox<PhoneEntry>('phone_entries');
      final entries = entriesBox.values.toList();

      // Sort by date (newest first)
      entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      // Apply pagination
      final paginatedEntries = entries.skip(offset).take(limit).toList();

      return {
        'success': true,
        'data': {
          'entries': paginatedEntries.map((e) => e.toJson()).toList(),
          'total': entries.length,
          'limit': limit,
          'offset': offset,
        },
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Error getting history: ${e.toString()}',
      };
    }
  }

  // API endpoint: Get team data
  Future<Map<String, dynamic>> getTeamData(String apiKey, String teamId) async {
    try {
      // Verify API key has permission
      final hasPermission = await verifyApiKey(
        apiKey,
        ApiPermission.viewTeamData,
      );

      if (!hasPermission) {
        return {
          'success': false,
          'error': 'Invalid API key or insufficient permissions',
        };
      }

      // Find the API key to get the user ID
      final box = await Hive.openBox<ApiKey>(_apiKeysBox);
      final keys = box.values.where((key) => key.key == apiKey).toList();

      if (keys.isEmpty) {
        return {'success': false, 'error': 'Invalid API key'};
      }

      final userId = keys.first.userId;

      // Check if user is a member of the team
      final teamService = TeamService();
      final team = await teamService.getTeam(teamId);

      if (team == null) {
        return {'success': false, 'error': 'Team not found'};
      }

      if (!team.hasMember(userId)) {
        return {'success': false, 'error': 'You are not a member of this team'};
      }

      // Return team data
      return {
        'success': true,
        'data': {'team': team.toJson()},
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Error getting team data: ${e.toString()}',
      };
    }
  }

  // Helper method to generate a secure token
  String _generateSecureToken() {
    final random = Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    final bytes = base64Url.encode(values);
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final hash = sha256.convert(utf8.encode(bytes + timestamp));
    return hash.toString();
  }
}
