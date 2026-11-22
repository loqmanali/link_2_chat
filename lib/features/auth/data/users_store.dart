import 'dart:convert';

import 'package:link_2_chat/core/api/failure.dart';
import 'package:link_2_chat/core/json/json_reader.dart';
import 'package:link_2_chat/core/local_db/change_watcher.dart';
import 'package:link_2_chat/features/auth/domain/user.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

/// The device-local accounts, in the `users` table. Every write calls
/// [ChangeWatcher.notify]; read failures throw [StorageFailure], account
/// rules throw [AuthFailure] or [ValidationFailure].
class UsersStore {
  const UsersStore(this._db, this._watcher);

  final Database _db;
  final ChangeWatcher _watcher;

  /// The account with [email], or null. Emails are compared lower-cased.
  Future<User?> byEmail(String email) async {
    try {
      final rows = await _db.query(
        'users',
        where: 'email = ?',
        whereArgs: [email.trim().toLowerCase()],
        limit: 1,
      );
      return rows.isEmpty ? null : _user(rows.single);
    } on Object catch (error) {
      throw StorageFailure('byEmail failed: $error');
    }
  }

  /// The account with [id], or null.
  Future<User?> byId(String id) async {
    try {
      final rows = await _db.query(
        'users',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      return rows.isEmpty ? null : _user(rows.single);
    } on Object catch (error) {
      throw StorageFailure('byId failed: $error');
    }
  }

  /// The same as [byId], re-read after every write.
  Stream<User?> watchById(String id) => _watcher.watch(() => byId(id));

  /// Creates the account. A duplicate email throws [AuthFailure].
  Future<User> create({
    required String name,
    required String email,
    required String passwordHash,
  }) async {
    final normalized = email.trim().toLowerCase();
    final existing = await byEmail(normalized);
    if (existing != null) {
      throw const AuthFailure('This email is already registered.');
    }
    final now = DateTime.now();
    final user = User(
      id: const Uuid().v4(),
      name: name.trim(),
      email: normalized,
      passwordHash: passwordHash,
      createdAt: now,
      lastLoginAt: now,
    );
    try {
      await _db.insert('users', _row(user));
      _watcher.notify();
      return user;
    } on Object catch (error) {
      throw StorageFailure('create failed: $error');
    }
  }

  /// Renames the account and/or sets a new password hash.
  Future<void> updateProfile(
    String id, {
    String? name,
    String? passwordHash,
  }) async {
    try {
      final row = {
        if (name != null) 'name': name.trim(),
        if (passwordHash != null) 'password_hash': passwordHash,
      };
      if (row.isNotEmpty) {
        await _db.update('users', row, where: 'id = ?', whereArgs: [id]);
        _watcher.notify();
      }
    } on Object catch (error) {
      throw StorageFailure('updateProfile failed: $error');
    }
  }

  /// Records a successful login.
  Future<void> touchLogin(String id) async {
    try {
      await _db.update(
        'users',
        {'last_login_at': DateTime.now().millisecondsSinceEpoch},
        where: 'id = ?',
        whereArgs: [id],
      );
      _watcher.notify();
    } on Object catch (error) {
      throw StorageFailure('touchLogin failed: $error');
    }
  }

  /// Moves the account to [tier], with an optional expiry date.
  Future<void> updateSubscription(
    String id,
    SubscriptionTier tier,
    DateTime? expiry,
  ) async {
    try {
      await _db.update(
        'users',
        {
          'subscription_tier': tier.name,
          'subscription_expiry': expiry?.millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      _watcher.notify();
    } on Object catch (error) {
      throw StorageFailure('updateSubscription failed: $error');
    }
  }

  /// Removes the account and every row keyed to it locally. Returns whether
  /// the id existed.
  Future<bool> delete(String id) async {
    try {
      final count = await _db.delete('users', where: 'id = ?', whereArgs: [id]);
      _watcher.notify();
      return count > 0;
    } on Object catch (error) {
      throw StorageFailure('delete failed: $error');
    }
  }

  User _user(Map<Object?, Object?> row) {
    final r = JsonReader.of(row);
    // The column stores encoded json text; read the raw string and decode.
    final prefsJson = jsonDecode(r.string('preferences'));
    final prefsReader =
        prefsJson is Map<String, Object?>
            ? JsonReader.of(prefsJson)
            : prefsJson is Map
            ? JsonReader.of(prefsJson.cast<String, Object?>())
            : null;
    final expiry = r.integerOrNull('subscription_expiry');
    final lastLogin = r.integerOrNull('last_login_at');
    return User(
      id: r.string('id'),
      name: r.string('name'),
      email: r.string('email'),
      passwordHash: r.string('password_hash'),
      role: r.string('role'),
      subscriptionTier: SubscriptionTier.of(r.string('subscription_tier')),
      subscriptionExpiry:
          expiry == null ? null : DateTime.fromMillisecondsSinceEpoch(expiry),
      preferences:
          prefsReader == null
              ? const {}
              : {
                for (final e in prefsReader.json.entries)
                  if (e.value is String) e.key: e.value as String,
              },
      createdAt: DateTime.fromMillisecondsSinceEpoch(r.integer('created_at')),
      lastLoginAt:
          lastLogin == null
              ? null
              : DateTime.fromMillisecondsSinceEpoch(lastLogin),
    );
  }

  Map<String, Object?> _row(User u) => {
    'id': u.id,
    'name': u.name,
    'email': u.email,
    'password_hash': u.passwordHash,
    'role': u.role,
    'subscription_tier': u.subscriptionTier.name,
    'subscription_expiry': u.subscriptionExpiry?.millisecondsSinceEpoch,
    'preferences': jsonEncode(u.preferences),
    'created_at': u.createdAt.millisecondsSinceEpoch,
    'last_login_at': u.lastLoginAt?.millisecondsSinceEpoch ?? 0,
  };
}
