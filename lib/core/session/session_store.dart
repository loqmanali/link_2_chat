import 'dart:convert';

import 'package:link_2_chat/core/json/json_reader.dart';
import 'package:link_2_chat/core/session/session.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The one place the session is persisted. Kept in shared_preferences under a
/// versioned key — the same place the pre-refactor app kept it, so a user
/// upgrading keeps their session. An unreadable value is deleted and read as
/// "signed out". (The Supabase auth session itself is persisted by
/// `supabase_flutter`; this store records which profile the app is showing.)
class SessionStore {
  const SessionStore({SharedPreferences? preferences})
    : _preferences = preferences;

  static const String key = 'session.v2';

  // Legacy keys the pre-refactor app used; read once on migration.
  static const String legacyUserIdKey = 'current_user_id';
  static const String legacyGuestKey = 'is_guest_user';

  final SharedPreferences? _preferences;

  Future<SharedPreferences> _prefs() async =>
      _preferences ?? SharedPreferences.getInstance();

  Future<AppSession?> read() async {
    final prefs = await _prefs();
    final raw = prefs.getString(key);
    if (raw != null) {
      try {
        return AppSession.fromJson(
          JsonReader.of(jsonDecode(raw) as Map<String, Object?>),
        );
      } on Object {
        await prefs.remove(key);
      }
    }
    // Migrate the legacy keys once: the old app recorded the user id and the
    // guest flag separately.
    final legacyId = prefs.getString(legacyUserIdKey);
    if (legacyId != null) {
      final session = AppSession(
        userId: legacyId,
        isGuest: prefs.getBool(legacyGuestKey) ?? false,
      );
      await write(session);
      return session;
    }
    return null;
  }

  Future<void> write(AppSession session) async {
    final prefs = await _prefs();
    await prefs.setString(key, jsonEncode(session.toJson()));
    await prefs.remove(legacyUserIdKey);
    await prefs.remove(legacyGuestKey);
  }

  Future<void> clear() async {
    final prefs = await _prefs();
    await prefs.remove(key);
    await prefs.remove(legacyUserIdKey);
    await prefs.remove(legacyGuestKey);
  }
}
