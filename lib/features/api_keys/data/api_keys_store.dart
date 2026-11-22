import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:link_2_chat/core/api/failure.dart';
import 'package:link_2_chat/core/json/json_reader.dart';
import 'package:link_2_chat/core/local_db/change_watcher.dart';
import 'package:link_2_chat/features/api_keys/domain/api_key.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

/// The API keys, in the `api_keys` table. The `permissions` column is a json
/// array of permission names; the `key` column stores the full key (this
/// device is its own vault). Every write calls [ChangeWatcher.notify]; read
/// failures throw [StorageFailure].
class ApiKeysStore {
  const ApiKeysStore(this._db, this._watcher);

  final Database _db;
  final ChangeWatcher _watcher;

  /// Every key of [userId], newest first.
  Future<List<ApiKey>> keysForUser(String userId) async {
    try {
      final rows = await _db.query(
        'api_keys',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'created_at DESC',
      );
      return [for (final row in rows) _key(row)];
    } on Object catch (error) {
      throw StorageFailure('keysForUser failed: $error');
    }
  }

  /// The same as [keysForUser], re-read after every write.
  Stream<List<ApiKey>> watchKeysForUser(String userId) =>
      _watcher.watch(() => keysForUser(userId));

  /// Creates a key with a fresh secret formatted like the pre-refactor one
  /// (a sha256 over random bytes and the current time). Validation of the
  /// permissions is the action layer's job.
  Future<ApiKey> create({
    required String userId,
    required String name,
    required String description,
    required List<ApiPermission> permissions,
  }) async {
    final apiKey = ApiKey(
      id: const Uuid().v4(),
      userId: userId,
      name: name.trim(),
      description: description.trim(),
      key: _generateToken(),
      permissions: permissions,
      createdAt: DateTime.now(),
    );
    try {
      await _db.insert('api_keys', _row(apiKey));
      _watcher.notify();
      return apiKey;
    } on Object catch (error) {
      throw StorageFailure('create failed: $error');
    }
  }

  /// Removes the key. Returns whether the id existed.
  Future<bool> delete(String id) async {
    try {
      final count = await _db.delete(
        'api_keys',
        where: 'id = ?',
        whereArgs: [id],
      );
      _watcher.notify();
      return count > 0;
    } on Object catch (error) {
      throw StorageFailure('delete failed: $error');
    }
  }

  /// Enables or disables the key without deleting it.
  Future<void> setActive(String id, bool isActive) async {
    try {
      await _db.update(
        'api_keys',
        {'is_active': isActive ? 1 : 0},
        where: 'id = ?',
        whereArgs: [id],
      );
      _watcher.notify();
    } on Object catch (error) {
      throw StorageFailure('setActive failed: $error');
    }
  }

  /// The same secret scheme the pre-refactor `ApiService` used: sha256 over
  /// 32 random bytes and the current time.
  String _generateToken() {
    final random = DateTime.now().microsecondsSinceEpoch;
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    return sha256.convert(utf8.encode('$random$timestamp')).toString();
  }

  ApiKey _key(Map<Object?, Object?> row) {
    final r = JsonReader.of(row);
    final lastUsed = r.integerOrNull('last_used_at');
    // The permissions column is a plain json array of names.
    final decoded = jsonDecode(r.string('permissions'));
    final names = <ApiPermission>[];
    if (decoded is List<Object?>) {
      for (final name in decoded) {
        final permission = ApiPermission.of('$name');
        if (permission != null) names.add(permission);
      }
    }
    return ApiKey(
      id: r.string('id'),
      userId: r.string('user_id'),
      name: r.string('name'),
      description: r.string('description'),
      key: r.string('key'),
      permissions: names,
      createdAt: DateTime.fromMillisecondsSinceEpoch(r.integer('created_at')),
      lastUsedAt:
          lastUsed == null
              ? null
              : DateTime.fromMillisecondsSinceEpoch(lastUsed),
      isActive: r.integer('is_active') == 1,
    );
  }

  Map<String, Object?> _row(ApiKey k) => {
    'id': k.id,
    'user_id': k.userId,
    'name': k.name,
    'description': k.description,
    'key': k.key,
    'permissions': jsonEncode([for (final p in k.permissions) p.name]),
    'is_active': k.isActive ? 1 : 0,
    'created_at': k.createdAt.millisecondsSinceEpoch,
    'last_used_at': k.lastUsedAt?.millisecondsSinceEpoch,
  };
}
