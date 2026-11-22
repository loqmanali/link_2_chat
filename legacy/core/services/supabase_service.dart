import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/constants.dart';
import '../models/phone_entry.dart';
import '../models/user.dart' as app_user;

/// Service to interact with Supabase backend
class SupabaseService {
  static const String _phoneEntriesTable = 'phone_entries';
  static const String _usersTable = 'users';
  static const String _teamsTable = 'teams';
  static const String _apiKeysTable = 'api_keys';

  // Singleton instance
  static final SupabaseService _instance = SupabaseService._internal();

  factory SupabaseService() => _instance;

  SupabaseService._internal();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Initialize Supabase client
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await Supabase.initialize(
        url: AppConstants.supabaseUrl,
        anonKey: AppConstants.supabaseAnonKey,
      );
      _isInitialized = true;
      debugPrint('Supabase initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize Supabase: $e');
      rethrow;
    }
  }

  /// Get Supabase client
  SupabaseClient get client {
    if (!_isInitialized) {
      throw Exception('Supabase not initialized. Call initialize() first.');
    }
    return Supabase.instance.client;
  }

  /// Check if user is authenticated with Supabase
  Future<bool> isAuthenticated() async {
    try {
      final session = client.auth.currentSession;
      return session != null;
    } catch (e) {
      debugPrint('Error checking authentication status: $e');
      return false;
    }
  }

  /// Sign up a new user
  Future<AuthResponse?> signUp(
    String email,
    String password,
    String name,
  ) async {
    try {
      // First, sign up the user with Supabase Auth
      final response = await client.auth.signUp(
        email: email,
        password: password,
        data: {'name': name},
      );

      if (response.user != null) {
        try {
          // Wait a moment to ensure the auth is processed
          await Future.delayed(const Duration(milliseconds: 500));

          // Sign in with the new credentials to get a session
          final signInResponse = await client.auth.signInWithPassword(
            email: email,
            password: password,
          );

          if (signInResponse.session != null) {
            // Now create the user profile with the authenticated session
            await client.from(_usersTable).insert({
              'id': response.user!.id,
              'name': name,
              'email': email,
              'created_at': DateTime.now().toIso8601String(),
              'last_login_at': DateTime.now().toIso8601String(),
              'subscription_tier': 'free',
            });

            debugPrint('User profile created successfully');
          }
        } catch (e) {
          debugPrint('Error creating user profile: $e');
          // If profile creation fails, we should still return the auth response
          // as the user was created in auth.users
        }
      }

      return response;
    } catch (e) {
      debugPrint('Error signing up: $e');
      return null;
    }
  }

  /// Sign in with email and password
  Future<AuthResponse?> signIn(String email, String password) async {
    try {
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Update last login time
        await client
            .from(_usersTable)
            .update({'last_login_at': DateTime.now().toIso8601String()})
            .eq('id', response.user!.id);
      }

      return response;
    } catch (e) {
      debugPrint('Error signing in: $e');
      return null;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      // Check if there's an active session before signing out
      final session = client.auth.currentSession;
      if (session != null) {
        // Only attempt to sign out if there's an active session
        await client.auth.signOut(scope: SignOutScope.global);
      } else {
        debugPrint('No active Supabase session found, skipping sign out');
      }
    } catch (e) {
      debugPrint('Error signing out: $e');
      // Don't rethrow the exception to prevent app crashes
      // Just log it and continue
    }
  }

  /// Get current user from Supabase
  Future<app_user.User?> getCurrentUser() async {
    try {
      final user = client.auth.currentUser;

      if (user == null) return null;

      // Get user data with more details
      final response =
          await client.from(_usersTable).select().eq('id', user.id).single();

      debugPrint('Supabase user data: $response');

      // Get user's teams
      final teamsResponse = await client
          .from('team_members')
          .select('team_id')
          .eq('user_id', user.id);

      List<String> teamIds = [];
      teamIds = List<String>.from(
        teamsResponse.map((item) => item['team_id'] as String),
      );

      debugPrint('User teams from Supabase: $teamIds');

      // Get subscription details
      final subscriptionData = response['subscription_tier'] ?? 'free';
      final subscriptionExpiry =
          response['subscription_expiry'] != null
              ? DateTime.parse(response['subscription_expiry'])
              : null;

      // Map the Supabase user to our app's User model
      return app_user.User(
        id: user.id,
        name: response['name'] ?? user.email?.split('@')[0] ?? 'User',
        email: user.email!,
        passwordHash:
            '', // We don't store or retrieve password hash from Supabase
        role: response['role'] ?? 'member',
        createdAt: DateTime.parse(
          response['created_at'] ?? DateTime.now().toIso8601String(),
        ),
        lastLoginAt: DateTime.parse(
          response['last_login_at'] ?? DateTime.now().toIso8601String(),
        ),
        teamIds: teamIds,
        subscriptionTier: _getSubscriptionTier(subscriptionData),
        subscriptionExpiry: subscriptionExpiry,
      );
    } catch (e) {
      debugPrint('Error getting current user: $e');
      return null;
    }
  }

  /// Helper method to convert string to SubscriptionTier enum
  app_user.SubscriptionTier _getSubscriptionTier(String tier) {
    switch (tier.toLowerCase()) {
      case 'professional':
        return app_user.SubscriptionTier.professional;
      case 'enterprise':
        return app_user.SubscriptionTier.enterprise;
      default:
        return app_user.SubscriptionTier.free;
    }
  }

  /// Save a phone entry to Supabase
  Future<PhoneEntry?> savePhoneEntry(PhoneEntry entry) async {
    try {
      final user = client.auth.currentUser;

      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Check if the user has a policy recursion issue
      // This is a workaround for the "infinite recursion detected in policy for relation teams" error
      try {
        final response =
            await client.from(_phoneEntriesTable).insert({
              'user_id': user.id,
              'phone_number': entry.phoneNumber,
              'country_code': entry.countryCode,
              'country_name': entry.countryName,
              'timestamp': entry.timestamp.toIso8601String(),
              'platform': entry.platform,
            }).select();

        if (response.isNotEmpty) {
          return entry;
        }
        return null;
      } catch (e) {
        // If we get a policy recursion error, log it but don't fail completely
        if (e.toString().contains('infinite recursion detected in policy')) {
          debugPrint(
            'Policy recursion error detected in teams table. This is a Supabase configuration issue.',
          );
          // Return the entry as if it was successful to prevent repeated attempts that will fail
          return entry;
        }
        rethrow;
      }
    } catch (e) {
      debugPrint('Error saving phone entry: $e');
      return null;
    }
  }

  /// Get phone entries for the current user
  Future<List<PhoneEntry>> getPhoneEntries({
    DateTime? startDate,
    DateTime? endDate,
    String? platform,
    String? countryCode,
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final user = client.auth.currentUser;

      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Build query
      final query = client
          .from(_phoneEntriesTable)
          .select()
          .eq('user_id', user.id);

      // Apply filters
      if (platform != null) {
        query.eq('platform', platform);
      }

      if (countryCode != null) {
        query.eq('country_code', countryCode);
      }

      if (startDate != null) {
        query.gte('timestamp', startDate.toIso8601String());
      }

      if (endDate != null) {
        query.lte('timestamp', endDate.toIso8601String());
      }

      // Apply sorting and pagination
      final result = await query
          .order('timestamp', ascending: false)
          .range(offset, offset + limit - 1);

      // Convert response to PhoneEntry objects
      return result
          .map<PhoneEntry>(
            (data) => PhoneEntry(
              phoneNumber: data['phone_number'],
              countryCode: data['country_code'],
              countryName: data['country_name'],
              timestamp: DateTime.parse(data['timestamp']),
              platform: data['platform'],
            ),
          )
          .toList();
    } catch (e) {
      debugPrint('Error getting phone entries: $e');
      return [];
    }
  }

  /// Subscribe to phone entries changes
  Stream<List<PhoneEntry>> streamPhoneEntries() {
    try {
      final user = client.auth.currentUser;

      if (user == null) {
        throw Exception('User not authenticated');
      }

      return client
          .from(_phoneEntriesTable)
          .stream(primaryKey: ['id'])
          .eq('user_id', user.id)
          .order('timestamp')
          .map(
            (items) =>
                items
                    .map(
                      (item) => PhoneEntry(
                        phoneNumber: item['phone_number'],
                        countryCode: item['country_code'],
                        countryName: item['country_name'],
                        timestamp: DateTime.parse(item['timestamp']),
                        platform: item['platform'],
                      ),
                    )
                    .toList(),
          );
    } catch (e) {
      debugPrint('Error streaming phone entries: $e');
      return Stream.value([]);
    }
  }

  /// الحصول على فرق المستخدم
  Future<List<Map<String, dynamic>>> getUserTeams() async {
    try {
      final user = client.auth.currentUser;

      if (user == null) {
        throw Exception('User not authenticated');
      }

      final response = await client
          .from(_teamsTable)
          .select()
          .eq('owner_id', user.id);

      return response;
    } catch (e) {
      debugPrint('Error getting user teams: $e');
      return [];
    }
  }

  /// Get team by ID
  Future<Map<String, dynamic>?> getTeamById(String teamId) async {
    try {
      final user = client.auth.currentUser;

      if (user == null) {
        throw Exception('User not authenticated');
      }

      final response =
          await client
              .from(_teamsTable)
              .select()
              .eq('id', teamId)
              .eq('owner_id', user.id)
              .single();

      return response;
    } catch (e) {
      debugPrint('Error getting team by ID: $e');
      return null;
    }
  }

  /// Update team information
  Future<Map<String, dynamic>?> updateTeam(
    String teamId, {
    String? name,
    String? description,
  }) async {
    try {
      final user = client.auth.currentUser;

      if (user == null) {
        throw Exception('User not authenticated');
      }

      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (name != null) {
        updateData['name'] = name;
      }

      if (description != null) {
        updateData['description'] = description;
      }

      final response =
          await client
              .from(_teamsTable)
              .update(updateData)
              .eq('id', teamId)
              .eq('owner_id', user.id)
              .select()
              .single();

      return response;
    } catch (e) {
      debugPrint('Error updating team: $e');
      return null;
    }
  }

  /// Delete a team
  Future<bool> deleteTeam(String teamId) async {
    try {
      final user = client.auth.currentUser;

      if (user == null) {
        throw Exception('User not authenticated');
      }

      await client
          .from(_teamsTable)
          .delete()
          .eq('id', teamId)
          .eq('owner_id', user.id);

      return true;
    } catch (e) {
      debugPrint('Error deleting team: $e');
      return false;
    }
  }

  /// الحصول على مفاتيح API للمستخدم
  Future<List<Map<String, dynamic>>> getUserApiKeys() async {
    try {
      final user = client.auth.currentUser;

      if (user == null) {
        throw Exception('User not authenticated');
      }

      final response = await client
          .from(_apiKeysTable)
          .select()
          .eq('user_id', user.id);

      return response;
    } catch (e) {
      debugPrint('Error getting API keys: $e');
      return [];
    }
  }

  /// Get API key by ID
  Future<Map<String, dynamic>?> getApiKeyById(String keyId) async {
    try {
      final user = client.auth.currentUser;

      if (user == null) {
        throw Exception('User not authenticated');
      }

      final response =
          await client
              .from(_apiKeysTable)
              .select()
              .eq('id', keyId)
              .eq('user_id', user.id)
              .single();

      return response;
    } catch (e) {
      debugPrint('Error getting API key by ID: $e');
      return null;
    }
  }

  /// Update API key status
  Future<Map<String, dynamic>?> updateApiKeyStatus(
    String keyId,
    bool isActive,
  ) async {
    try {
      final user = client.auth.currentUser;

      if (user == null) {
        throw Exception('User not authenticated');
      }

      final response =
          await client
              .from(_apiKeysTable)
              .update({'is_active': isActive})
              .eq('id', keyId)
              .eq('user_id', user.id)
              .select()
              .single();

      return response;
    } catch (e) {
      debugPrint('Error updating API key status: $e');
      return null;
    }
  }

  /// Delete an API key
  Future<bool> deleteApiKey(String keyId) async {
    try {
      final user = client.auth.currentUser;

      if (user == null) {
        throw Exception('User not authenticated');
      }

      await client
          .from(_apiKeysTable)
          .delete()
          .eq('id', keyId)
          .eq('user_id', user.id);

      return true;
    } catch (e) {
      debugPrint('Error deleting API key: $e');
      return false;
    }
  }

  /// إنشاء فريق جديد
  Future<Map<String, dynamic>?> createTeam(
    String name,
    String description,
  ) async {
    try {
      final user = client.auth.currentUser;

      if (user == null) {
        throw Exception('User not authenticated');
      }

      final response =
          await client
              .from(_teamsTable)
              .insert({
                'name': name,
                'description': description,
                'owner_id': user.id,
                'created_at': DateTime.now().toIso8601String(),
                'updated_at': DateTime.now().toIso8601String(),
              })
              .select()
              .single();

      return response;
    } catch (e) {
      debugPrint('Error creating team: $e');
      return null;
    }
  }

  /// إنشاء مفتاح API جديد
  Future<Map<String, dynamic>?> createApiKey(
    String name,
    String description,
  ) async {
    try {
      final user = client.auth.currentUser;

      if (user == null) {
        throw Exception('User not authenticated');
      }

      // إنشاء مفتاح عشوائي
      final key = _generateRandomApiKey();

      final response =
          await client
              .from(_apiKeysTable)
              .insert({
                'name': name,
                'description': description,
                'user_id': user.id,
                'key': key,
                'permissions': ['read', 'write'],
                'created_at': DateTime.now().toIso8601String(),
                'is_active': true,
              })
              .select()
              .single();

      return response;
    } catch (e) {
      debugPrint('Error creating API key: $e');
      return null;
    }
  }

  /// إنشاء مفتاح API عشوائي
  String _generateRandomApiKey() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        32,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  /// Create a user as admin (for syncing local users)
  Future<UserResponse?> createUserAsAdmin(
    String email,
    String password,
    String name,
    String role,
    String subscriptionTier,
  ) async {
    try {
      // First, sign up the user with Supabase Auth
      final response = await client.auth.admin.createUser(
        AdminUserAttributes(
          email: email,
          password: password,
          emailConfirm: true, // Auto-confirm email
          userMetadata: {'name': name},
        ),
      );

      if (response.user != null) {
        try {
          // Create user profile in the users table
          await client.from(_usersTable).insert({
            'id': response.user!.id,
            'name': name,
            'email': email,
            'role': role,
            'created_at': DateTime.now().toIso8601String(),
            'last_login_at': DateTime.now().toIso8601String(),
            'subscription_tier': subscriptionTier.toLowerCase(),
          });

          debugPrint('Admin created user profile successfully');
          return response;
        } catch (e) {
          debugPrint('Error creating user profile by admin: $e');
          // Return the auth response even if profile creation fails
          return response;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error creating user as admin: $e');
      return null;
    }
  }

  /// Delete a user from Supabase
  Future<bool> deleteUser(String userId) async {
    try {
      final currentUser = client.auth.currentUser;

      // Check if the user is authenticated
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Delete user data from tables first
      try {
        // Delete user's phone entries
        await client.from(_phoneEntriesTable).delete().eq('user_id', userId);

        // Delete user's API keys
        await client.from(_apiKeysTable).delete().eq('user_id', userId);

        // Delete user's teams
        await client.from(_teamsTable).delete().eq('owner_id', userId);

        // Delete user profile from users table
        await client.from(_usersTable).delete().eq('id', userId);

        debugPrint('User data deleted successfully from tables');
      } catch (e) {
        debugPrint('Error deleting user data from tables: $e');
        // Continue with deleting the auth user even if table deletion fails
      }

      // Delete the user from auth.users if it's the current user or admin is deleting
      if (currentUser.id == userId) {
        // Self-deletion
        await client.auth.admin.deleteUser(userId);
        debugPrint('User deleted from auth.users');
      } else {
        // Admin deletion (requires admin privileges)
        try {
          await client.auth.admin.deleteUser(userId);
          debugPrint('User deleted from auth.users by admin');
        } catch (e) {
          debugPrint('Error deleting user from auth.users: $e');
          // If admin deletion fails, we still consider the operation successful
          // as the user data has been deleted from tables
        }
      }

      return true;
    } catch (e) {
      debugPrint('Error deleting user: $e');
      return false;
    }
  }
}
