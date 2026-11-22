import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:link_2_chat/core/local_db/local_database.dart';
import 'package:sqflite/sqflite.dart';

/// Key-value facts about this installation, in the `meta` table: the install
/// id, a cached config, a sync cursor. Not for secrets (those go to
/// `SessionStore`) and not for user preferences (those use shared_preferences).
class MetaStore {
  const MetaStore(this._db);

  final Database _db;

  Future<String?> read(String key) async {
    final rows = await _db.query(
      'meta',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
    );
    return rows.isEmpty ? null : rows.single['value'] as String?;
  }

  Future<void> write(String key, String value) => _db.insert('meta', {
    'key': key,
    'value': value,
  }, conflictAlgorithm: ConflictAlgorithm.replace);

  Future<void> delete(String key) =>
      _db.delete('meta', where: 'key = ?', whereArgs: [key]);
}

final metaStoreProvider = Provider<MetaStore>(
  (ref) => MetaStore(ref.watch(databaseProvider)),
);

/// Keys of the `meta` table.
abstract final class MetaKeys {
  static const String installId = 'install_id';
}
