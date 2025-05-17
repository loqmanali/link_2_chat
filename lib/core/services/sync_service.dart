import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../config/constants.dart';
import '../models/phone_entry.dart';
import 'supabase_service.dart';

/// Service to handle synchronization between local Hive storage and Supabase
class SyncService {
  static const String _pendingSyncBox = 'pending_sync';
  static const String _pendingPhoneEntriesKey = 'pending_phone_entries';
  static const String _lastSyncKey = 'last_sync_timestamp';

  // Singleton instance
  static final SyncService _instance = SyncService._internal();

  factory SyncService() => _instance;

  SyncService._internal();

  final SupabaseService _supabaseService = SupabaseService();
  final Connectivity _connectivity = Connectivity();

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _syncTimer;

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  final _syncStatusController = StreamController<SyncStatus>.broadcast();
  Stream<SyncStatus> get syncStatusStream => _syncStatusController.stream;

  /// Initialize the sync service
  Future<void> initialize() async {
    try {
      // Make sure Supabase is initialized
      if (!_supabaseService.isInitialized) {
        await _supabaseService.initialize();
      }

      // Open pending sync box
      await Hive.openBox<dynamic>(_pendingSyncBox);

      // Listen for connectivity changes
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        _handleConnectivityChange,
      );

      // Check initial connectivity
      final results = await _connectivity.checkConnectivity();
      final result =
          results.isNotEmpty ? results.first : ConnectivityResult.none;
      if (result != ConnectivityResult.none) {
        // Try to sync when app starts and we have connectivity
        scheduleSyncWithServer();
      }

      // Set up periodic sync (every 15 minutes)
      _syncTimer = Timer.periodic(const Duration(minutes: 15), (_) {
        scheduleSyncWithServer();
      });

      debugPrint('Sync service initialized');
    } catch (e) {
      debugPrint('Error initializing sync service: $e');
    }
  }

  /// Handle connectivity changes
  void _handleConnectivityChange(List<ConnectivityResult> results) {
    // Use the first result to determine connectivity status
    final result = results.isNotEmpty ? results.first : ConnectivityResult.none;

    if (result != ConnectivityResult.none) {
      debugPrint('Connection restored. Attempting to sync...');
      scheduleSyncWithServer();
    } else {
      debugPrint('Connection lost. Operating in offline mode.');
      _syncStatusController.add(
        SyncStatus(
          isOnline: false,
          lastSyncTime: _getLastSyncTime(),
          message: 'Operating in offline mode',
        ),
      );
    }
  }

  /// Schedule sync with server
  Future<void> scheduleSyncWithServer() async {
    if (_isSyncing) {
      debugPrint('Sync already in progress, skipping...');
      return;
    }

    try {
      final connectivityResults = await _connectivity.checkConnectivity();
      final connectivityResult =
          connectivityResults.isNotEmpty
              ? connectivityResults.first
              : ConnectivityResult.none;
      if (connectivityResult == ConnectivityResult.none) {
        debugPrint('No internet connection, skipping sync');
        return;
      }

      final isAuthenticated = await _supabaseService.isAuthenticated();
      if (!isAuthenticated) {
        debugPrint('Not authenticated with Supabase, skipping sync');
        return;
      }

      _isSyncing = true;
      _syncStatusController.add(
        SyncStatus(
          isOnline: true,
          lastSyncTime: _getLastSyncTime(),
          message: 'Syncing with server...',
          inProgress: true,
        ),
      );

      await syncPhoneEntries();

      // Update last sync time
      final syncBox = Hive.box<dynamic>(_pendingSyncBox);
      await syncBox.put(_lastSyncKey, DateTime.now().toIso8601String());

      _isSyncing = false;
      _syncStatusController.add(
        SyncStatus(
          isOnline: true,
          lastSyncTime: DateTime.now(),
          message: 'Sync completed successfully',
          inProgress: false,
        ),
      );

      debugPrint('Sync completed successfully');
    } catch (e) {
      _isSyncing = false;
      _syncStatusController.add(
        SyncStatus(
          isOnline: true,
          lastSyncTime: _getLastSyncTime(),
          message: 'Sync failed: ${e.toString()}',
          inProgress: false,
          hasError: true,
        ),
      );

      debugPrint('Error during sync: $e');
    }
  }

  /// Sync phone entries between local storage and Supabase
  Future<void> syncPhoneEntries() async {
    try {
      // Get pending phone entries from local storage
      final syncBox = Hive.box<dynamic>(_pendingSyncBox);
      final pendingEntries = List<PhoneEntry>.from(
        syncBox.get(_pendingPhoneEntriesKey, defaultValue: <PhoneEntry>[]),
      );

      if (pendingEntries.isNotEmpty) {
        debugPrint('Found ${pendingEntries.length} pending entries to sync');

        // Upload each pending entry to Supabase
        final remainingEntries = <PhoneEntry>[];

        for (final entry in pendingEntries) {
          try {
            final savedEntry = await _supabaseService.savePhoneEntry(entry);
            if (savedEntry == null) {
              // If upload failed, keep in pending list
              remainingEntries.add(entry);
              debugPrint(
                'Error saving phone entry to Supabase, will retry later',
              );
            }
          } catch (e) {
            // If error occurs, keep in pending list
            debugPrint('Error saving phone entry: $e');
            remainingEntries.add(entry);

            // If we encounter a policy recursion error, break the loop to avoid multiple errors
            if (e.toString().contains(
              'infinite recursion detected in policy',
            )) {
              debugPrint(
                'Detected policy recursion error, pausing sync process',
              );
              break;
            }
          }
        }

        // Update pending entries with any that failed to sync
        await syncBox.put(_pendingPhoneEntriesKey, remainingEntries);

        debugPrint(
          'Synced ${pendingEntries.length - remainingEntries.length} entries, '
          '${remainingEntries.length} remaining',
        );
      }

      try {
        // Get newest entries from server and merge with local
        final serverEntries = await _supabaseService.getPhoneEntries(
          limit: 100,
        );

        if (serverEntries.isNotEmpty) {
          final entriesBox = await Hive.openBox<PhoneEntry>(
            AppConstants.phoneEntriesBox,
          );
          final localEntries = entriesBox.values.toList();

          // Simple merging strategy: keep all local entries and add any server entries
          // that don't exist locally (based on timestamp and phone number)
          for (final serverEntry in serverEntries) {
            final exists = localEntries.any(
              (localEntry) =>
                  localEntry.phoneNumber == serverEntry.phoneNumber &&
                  localEntry.countryCode == serverEntry.countryCode &&
                  localEntry.timestamp.isAtSameMomentAs(serverEntry.timestamp),
            );

            if (!exists) {
              await entriesBox.add(serverEntry);
              debugPrint(
                'Added server entry to local storage: ${serverEntry.phoneNumber}',
              );
            }
          }
        }
      } catch (e) {
        // Catch errors when fetching from server but don't fail the entire sync
        debugPrint('Error getting phone entries from server: $e');
        // Don't rethrow here to allow sync to complete partially
      }
    } catch (e) {
      debugPrint('Error syncing phone entries: $e');
      // We'll still mark sync as complete but with an error
      // Don't rethrow to prevent cascading failures
    }
  }

  /// Save a phone entry (locally and queue for sync if offline)
  Future<PhoneEntry?> savePhoneEntry(PhoneEntry entry) async {
    try {
      // Always save to local Hive storage first
      final entriesBox = await Hive.openBox<PhoneEntry>(
        AppConstants.phoneEntriesBox,
      );
      await entriesBox.add(entry);

      // Check connectivity
      final connectivityResults = await _connectivity.checkConnectivity();
      final connectivityResult =
          connectivityResults.isNotEmpty
              ? connectivityResults.first
              : ConnectivityResult.none;
      final isOnline = connectivityResult != ConnectivityResult.none;

      if (isOnline && await _supabaseService.isAuthenticated()) {
        // If online and authenticated, save to Supabase directly
        final savedEntry = await _supabaseService.savePhoneEntry(entry);
        return savedEntry ?? entry;
      } else {
        // If offline or not authenticated, add to pending sync queue
        final syncBox = Hive.box<dynamic>(_pendingSyncBox);
        final pendingEntries = List<PhoneEntry>.from(
          syncBox.get(_pendingPhoneEntriesKey, defaultValue: <PhoneEntry>[]),
        );

        pendingEntries.add(entry);
        await syncBox.put(_pendingPhoneEntriesKey, pendingEntries);

        debugPrint(
          'Saved phone entry to local storage and added to sync queue',
        );
        return entry;
      }
    } catch (e) {
      debugPrint('Error saving phone entry: $e');
      return null;
    }
  }

  /// Get the last sync time
  DateTime? _getLastSyncTime() {
    try {
      final syncBox = Hive.box<dynamic>(_pendingSyncBox);
      final lastSyncStr = syncBox.get(_lastSyncKey) as String?;

      if (lastSyncStr != null) {
        return DateTime.parse(lastSyncStr);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting last sync time: $e');
      return null;
    }
  }

  /// Dispose of resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _syncTimer?.cancel();
    _syncStatusController.close();
  }
}

/// Class to represent sync status
class SyncStatus {
  final bool isOnline;
  final DateTime? lastSyncTime;
  final String message;
  final bool inProgress;
  final bool hasError;

  SyncStatus({
    required this.isOnline,
    this.lastSyncTime,
    required this.message,
    this.inProgress = false,
    this.hasError = false,
  });
}
