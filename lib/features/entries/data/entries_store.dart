import 'dart:convert';

import 'package:link_2_chat/core/api/failure.dart';
import 'package:link_2_chat/core/json/json_reader.dart';
import 'package:link_2_chat/core/local_db/change_watcher.dart';
import 'package:link_2_chat/features/entries/domain/link_target.dart';
import 'package:link_2_chat/features/entries/domain/phone_entry.dart';
import 'package:link_2_chat/features/entries/domain/user_stats.dart';
import 'package:sqflite/sqflite.dart';

/// The link history and the usage counters, read and written in the local
/// sqlite database. Every write calls [ChangeWatcher.notify], so watching
/// screens re-read. Reads that fail throw [StorageFailure] — never a raw
/// sqlite error.
class EntriesStore {
  const EntriesStore(this._db, this._watcher);

  final Database _db;
  final ChangeWatcher _watcher;

  /// The history of [userId], newest first.
  Future<List<PhoneEntry>> history(String userId) async {
    try {
      final rows = await _db.query(
        'phone_entries',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'created_at DESC',
      );
      return [for (final row in rows) _entry(row)];
    } on Object catch (error) {
      throw StorageFailure('history failed: $error');
    }
  }

  /// The same as [history], re-read after every write.
  Stream<List<PhoneEntry>> watchHistory(String userId) =>
      _watcher.watch(() => history(userId));

  /// Saves one entry and bumps the user's counters in the same transaction.
  Future<void> record(PhoneEntry entry) async {
    try {
      await _db.transaction((txn) async {
        await txn.insert('phone_entries', _row(entry));
        final stats = await _stats(txn, entry.userId);
        await txn.insert(
          'user_stats',
          _statsRow(
            entry.userId,
            stats.recorded(
              countryCode: entry.countryCode,
              isWhatsapp: entry.platform == LinkPlatform.whatsapp,
              at: entry.createdAt,
            ),
          ),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      });
      _watcher.notify();
    } on Object catch (error) {
      throw StorageFailure('record failed: $error');
    }
  }

  /// Removes one entry (its counters stay: history cleanup, not a usage
  /// correction).
  Future<void> delete(String id) async {
    try {
      await _db.delete('phone_entries', where: 'id = ?', whereArgs: [id]);
      _watcher.notify();
    } on Object catch (error) {
      throw StorageFailure('delete failed: $error');
    }
  }

  /// Removes every entry of [userId].
  Future<void> clearHistory(String userId) async {
    try {
      await _db.delete(
        'phone_entries',
        where: 'user_id = ?',
        whereArgs: [userId],
      );
      _watcher.notify();
    } on Object catch (error) {
      throw StorageFailure('clearHistory failed: $error');
    }
  }

  /// The counters of [userId]; zeros before the first link.
  Future<UserStats> stats(String userId) async {
    try {
      return await _stats(_db, userId);
    } on Object catch (error) {
      throw StorageFailure('stats failed: $error');
    }
  }

  /// The same as [stats], re-read after every write.
  Stream<UserStats> watchStats(String userId) =>
      _watcher.watch(() => stats(userId));

  Future<UserStats> _stats(DatabaseExecutor db, String userId) async {
    final rows = await db.query(
      'user_stats',
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (rows.isEmpty) return const UserStats();
    final r = JsonReader.of(rows.single);
    // The json-encoded column of dial code -> count; keys are country codes,
    // so the map is read as the raw decoded object.
    final usage = JsonReader.of(jsonDecode(r.string('country_usage'))).json;
    return UserStats(
      totalGeneratedLinks: r.integer('total_generated_links'),
      whatsappLinks: r.integer('whatsapp_links'),
      telegramLinks: r.integer('telegram_links'),
      countryUsage: {
        for (final e in usage.entries) e.key: (e.value as num).toInt(),
      },
      lastUsed: DateTime.fromMillisecondsSinceEpoch(r.integer('last_used')),
    );
  }

  PhoneEntry _entry(Map<Object?, Object?> row) {
    final r = JsonReader.of(row);
    return PhoneEntry(
      id: r.string('id'),
      userId: r.string('user_id'),
      phoneNumber: r.string('phone_number'),
      countryCode: r.string('country_code'),
      countryName: r.string('country_name'),
      platform:
          r.string('platform') == LinkPlatform.whatsapp.name
              ? LinkPlatform.whatsapp
              : LinkPlatform.telegram,
      createdAt: DateTime.fromMillisecondsSinceEpoch(r.integer('created_at')),
    );
  }

  Map<String, Object?> _row(PhoneEntry e) => {
    'id': e.id,
    'user_id': e.userId,
    'phone_number': e.phoneNumber,
    'country_code': e.countryCode,
    'country_name': e.countryName,
    'platform': e.platform.name,
    'created_at': e.createdAt.millisecondsSinceEpoch,
  };

  Map<String, Object?> _statsRow(String userId, UserStats s) => {
    'user_id': userId,
    'total_generated_links': s.totalGeneratedLinks,
    'whatsapp_links': s.whatsappLinks,
    'telegram_links': s.telegramLinks,
    'country_usage': jsonEncode(s.countryUsage),
    'last_used': s.lastUsed?.millisecondsSinceEpoch ?? 0,
  };
}
