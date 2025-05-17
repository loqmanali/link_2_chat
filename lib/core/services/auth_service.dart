import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/user.dart';
import 'supabase_service.dart';

class AuthService {
  static const String _boxName = 'users';
  static const String _currentUserKey = 'current_user_id';

  // Singleton instance
  static final AuthService _instance = AuthService._internal();

  factory AuthService() => _instance;

  AuthService._internal();

  // Get the current user
  Future<User?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(_currentUserKey);

      if (userId == null) return null;

      try {
        final box = await Hive.openBox<User>(_boxName);
        return box.get(userId);
      } catch (e) {
        // If there's a database error, clear the user's session
        print('Database error retrieving user: $e');
        await prefs.remove(_currentUserKey);
        return null;
      }
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  // Get user by ID
  Future<User?> getUser(String userId) async {
    try {
      final box = await Hive.openBox<User>(_boxName);
      return box.get(userId);
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  // Get all users
  Future<List<User>> getAllUsers() async {
    try {
      final box = await Hive.openBox<User>(_boxName);
      return box.values.toList();
    } catch (e) {
      print('Error getting all users: $e');
      return [];
    }
  }

  // Update user data
  Future<User?> updateUser(User user) async {
    try {
      final box = await Hive.openBox<User>(_boxName);
      await box.put(user.id, user);
      return user;
    } catch (e) {
      print('Error updating user: $e');
      return null;
    }
  }

  // Login with email and password
  Future<User?> login(String email, String password) async {
    try {
      final box = await Hive.openBox<User>(_boxName);

      // Find user by email
      final users = box.values.where(
        (user) => user.email == email.trim().toLowerCase(),
      );

      if (users.isEmpty) {
        return null; // User not found
      }

      final user = users.first;
      final passwordHash = _hashPassword(password);

      if (user.passwordHash != passwordHash) {
        return null; // Wrong password
      }

      // Update last login time
      final updatedUser = user.copyWith(lastLoginAt: DateTime.now());
      await box.put(user.id, updatedUser);

      // Save current user ID to preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currentUserKey, user.id);

      return updatedUser;
    } catch (e) {
      print('Login error: $e');
      return null;
    }
  }

  // Register a new user in local database only
  Future<User?> register(String name, String email, String password) async {
    try {
      final box = await Hive.openBox<User>(_boxName);

      // Check if email already exists
      final existingUsers = box.values.where(
        (user) => user.email == email.trim().toLowerCase(),
      );

      if (existingUsers.isNotEmpty) {
        return null; // Email already registered
      }

      final now = DateTime.now();
      final newUser = User(
        id: const Uuid().v4(),
        name: name.trim(),
        email: email.trim().toLowerCase(),
        passwordHash: _hashPassword(password),
        createdAt: now,
        lastLoginAt: now,
      );

      await box.put(newUser.id, newUser);

      // Automatically log in the new user
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currentUserKey, newUser.id);

      return newUser;
    } catch (e) {
      print('Registration error: $e');
      return null;
    }
  }

  // Register a new user in both Supabase and local database
  Future<User?> registerWithSupabase(
    String name,
    String email,
    String password,
  ) async {
    try {
      final supabaseService = SupabaseService();

      // Initialize Supabase if not already initialized
      if (!supabaseService.isInitialized) {
        await supabaseService.initialize();
      }

      // First try to register with Supabase
      final authResponse = await supabaseService.signUp(email, password, name);

      // If Supabase registration failed, return null
      if (authResponse == null || authResponse.user == null) {
        debugPrint('Supabase registration failed');
        return null;
      }

      // If Supabase registration succeeded, create local user
      // Even if profile creation in Supabase failed, we can still create a local user
      final now = DateTime.now();
      final newUser = User(
        id: authResponse.user!.id, // Use Supabase user ID
        name: name.trim(),
        email: email.trim().toLowerCase(),
        passwordHash: _hashPassword(password),
        role: 'member', // Default role
        createdAt: now,
        lastLoginAt: now,
        subscriptionTier: SubscriptionTier.free, // Default subscription tier
      );

      // Save to local database
      final box = await Hive.openBox<User>(_boxName);
      await box.put(newUser.id, newUser);

      // Automatically log in the new user
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currentUserKey, newUser.id);

      debugPrint(
        'User registered successfully in both Supabase and local database',
      );
      return newUser;
    } catch (e) {
      debugPrint('Supabase registration error: $e');
      return null;
    }
  }

  // Login with Supabase and local database
  Future<User?> loginWithSupabase(String email, String password) async {
    try {
      final supabaseService = SupabaseService();

      // Initialize Supabase if not already initialized
      if (!supabaseService.isInitialized) {
        await supabaseService.initialize();
      }

      // First try to login with Supabase
      final authResponse = await supabaseService.signIn(email, password);

      // If Supabase login failed, return null
      if (authResponse == null || authResponse.user == null) {
        debugPrint('Supabase login failed');
        return null;
      }

      // Get user data from Supabase
      final supabaseUser = await supabaseService.getCurrentUser();

      if (supabaseUser == null) {
        debugPrint('Failed to get user data from Supabase');
        return null;
      }

      // Check if user exists in local database
      final box = await Hive.openBox<User>(_boxName);
      User? localUser = box.get(authResponse.user!.id);

      // If user doesn't exist locally, create from Supabase data
      if (localUser == null) {
        // Create local user from Supabase data
        localUser = User(
          id: authResponse.user!.id,
          name: supabaseUser.name,
          email: email.trim().toLowerCase(),
          passwordHash: _hashPassword(password), // Store password hash locally
          role: supabaseUser.role,
          createdAt: supabaseUser.createdAt,
          lastLoginAt: DateTime.now(),
          teamIds: supabaseUser.teamIds, // Copy team IDs from Supabase
          subscriptionTier: supabaseUser.subscriptionTier,
          subscriptionExpiry: supabaseUser.subscriptionExpiry,
        );

        // Save to local database
        await box.put(localUser.id, localUser);
      } else {
        // Update local user with latest data from Supabase
        localUser = localUser.copyWith(
          lastLoginAt: DateTime.now(),
          name: supabaseUser.name,
          role: supabaseUser.role,
          teamIds: supabaseUser.teamIds, // Update team IDs
          subscriptionTier:
              supabaseUser.subscriptionTier, // Update subscription
          subscriptionExpiry: supabaseUser.subscriptionExpiry,
        );
        await box.put(localUser.id, localUser);
      }

      // Save current user ID to preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currentUserKey, localUser.id);

      debugPrint('User logged in successfully with Supabase');
      debugPrint('User subscription tier: ${localUser.subscriptionTier}');
      debugPrint('User team IDs: ${localUser.teamIds}');

      return localUser;
    } catch (e) {
      debugPrint('Supabase login error: $e');
      return null;
    }
  }

  // Sync all local users with Supabase
  Future<Map<String, dynamic>> syncLocalUsersWithSupabase({
    required String adminEmail,
    required String adminPassword,
  }) async {
    final results = {
      'total': 0,
      'success': 0,
      'failed': 0,
      'skipped': 0,
      'details': <Map<String, dynamic>>[],
    };

    try {
      debugPrint('Starting local users sync with Supabase...');
      final supabaseService = SupabaseService();

      // Initialize Supabase if not already initialized
      if (!supabaseService.isInitialized) {
        await supabaseService.initialize();
      }

      // First login as admin to get proper permissions
      final adminLogin = await supabaseService.signIn(
        adminEmail,
        adminPassword,
      );
      if (adminLogin == null || adminLogin.user == null) {
        debugPrint('Failed to login as admin, cannot sync users');
        return {...results, 'error': 'Failed to login as admin user'};
      }

      // Get all local users
      final box = await Hive.openBox<User>(_boxName);
      final localUsers = box.values.toList();
      results['total'] = localUsers.length;

      debugPrint('Found ${localUsers.length} local users to sync');

      // For each local user, check if they exist in Supabase
      for (final user in localUsers) {
        try {
          // Skip users that have UUIDs (likely already synced with Supabase)
          if (user.id.length == 36 && user.id.contains('-')) {
            results['skipped'] = (results['skipped'] as int) + 1;
            (results['details'] as List<Map<String, dynamic>>).add({
              'email': user.email,
              'status': 'skipped',
              'reason': 'User already has a UUID',
            });
            continue;
          }

          // Generate a random password for the user (they can reset it later)
          final randomPassword = _generateRandomPassword();

          // Try to create the user in Supabase
          final userResponse = await supabaseService.createUserAsAdmin(
            user.email,
            randomPassword,
            user.name,
            user.role,
            user.subscriptionTier.name,
          );

          if (userResponse != null && userResponse.user != null) {
            // Update the local user with the Supabase user ID
            final updatedUser = user.copyWith(
              id: userResponse.user!.id,
              // Keep the original passwordHash so local login still works
            );

            await box.put(userResponse.user!.id, updatedUser);
            // Delete the old entry with the non-UUID key
            await box.delete(user.id);

            results['success'] = (results['success'] as int) + 1;
            (results['details'] as List<Map<String, dynamic>>).add({
              'email': user.email,
              'status': 'success',
              'newId': userResponse.user!.id,
            });

            debugPrint('Successfully synced user: ${user.email}');
          } else {
            results['failed'] = (results['failed'] as int) + 1;
            (results['details'] as List<Map<String, dynamic>>).add({
              'email': user.email,
              'status': 'failed',
              'reason': 'Failed to create user in Supabase',
            });

            debugPrint('Failed to sync user: ${user.email}');
          }
        } catch (e) {
          results['failed'] = (results['failed'] as int) + 1;
          (results['details'] as List<Map<String, dynamic>>).add({
            'email': user.email,
            'status': 'error',
            'reason': e.toString(),
          });

          debugPrint('Error syncing user ${user.email}: $e');
        }
      }

      // Login back as the original user if there was one
      final prefs = await SharedPreferences.getInstance();
      final currentUserId = prefs.getString(_currentUserKey);
      if (currentUserId != null) {
        final currentUser = box.get(currentUserId);
        if (currentUser != null) {
          // We don't have the plain password, so we can't log back in automatically
          // The user will need to login again
          await prefs.remove(_currentUserKey);
        }
      }

      // Sign out the admin user
      await supabaseService.signOut();

      debugPrint(
        'User sync completed: ${results['success']} of ${results['total']} users synced',
      );
      return results;
    } catch (e) {
      debugPrint('Error during user sync: $e');
      return {...results, 'error': e.toString()};
    }
  }

  // Generate a random password
  String _generateRandomPassword() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        12, // 12 character password
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  // Logout
  Future<bool> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_currentUserKey);

      // Clear any other session data
      await prefs.remove('last_sync_time');

      // Also logout from Supabase if initialized
      try {
        final supabaseService = SupabaseService();
        if (supabaseService.isInitialized) {
          await supabaseService.signOut();
        }
      } catch (e) {
        debugPrint('Error logging out from Supabase: $e');
        // Continue with local logout even if Supabase logout fails
      }

      return true;
    } catch (e) {
      print('Logout error: $e');
      return false;
    }
  }

  // Update user profile
  Future<User?> updateProfile(
    String userId, {
    String? name,
    String? email,
    String? newPassword,
  }) async {
    try {
      final box = await Hive.openBox<User>(_boxName);
      final user = box.get(userId);

      if (user == null) return null;

      // If changing email, check if it's already taken
      if (email != null && email != user.email) {
        final existingUsers = box.values.where(
          (u) => u.email == email.trim().toLowerCase() && u.id != userId,
        );

        if (existingUsers.isNotEmpty) {
          return null; // Email already in use
        }
      }

      final updatedUser = user.copyWith(
        name: name ?? user.name,
        email: email?.trim().toLowerCase() ?? user.email,
        passwordHash:
            newPassword != null
                ? _hashPassword(newPassword)
                : user.passwordHash,
      );

      await box.put(userId, updatedUser);
      return updatedUser;
    } catch (e) {
      print('Update profile error: $e');
      return null;
    }
  }

  // Simple password hashing
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  // Delete user account
  Future<bool> deleteAccount(String userId, {String? password}) async {
    try {
      // Get the user
      final box = await Hive.openBox<User>(_boxName);
      final user = box.get(userId);

      if (user == null) return false;

      // If password is provided, verify it
      if (password != null) {
        final passwordHash = _hashPassword(password);
        if (user.passwordHash != passwordHash) {
          return false; // Wrong password
        }
      }

      // Try to delete from Supabase if initialized
      try {
        final supabaseService = SupabaseService();
        if (supabaseService.isInitialized) {
          // Only attempt to delete from Supabase if the user ID looks like a UUID
          // which suggests the user was synced with Supabase
          if (userId.length == 36 && userId.contains('-')) {
            await supabaseService.deleteUser(userId);
          }
        }
      } catch (e) {
        debugPrint('Error deleting user from Supabase: $e');
        // Continue with local deletion even if Supabase deletion fails
      }

      // Delete from local database
      await box.delete(userId);

      // Clear current user session
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_currentUserKey);

      return true;
    } catch (e) {
      debugPrint('Delete account error: $e');
      return false;
    }
  }
}
