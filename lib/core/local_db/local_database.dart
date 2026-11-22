import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:link_2_chat/core/local_db/migrations.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Opens the one local database and applies [Migration]s in order: all of them
/// on creation, only the missing ones on upgrade. The UI reads from this
/// database; the network fills it.
abstract final class LocalDatabase {
  static const String fileName = 'app.db';

  /// [factory] and [path] exist for tests (an FFI factory and a temp path);
  /// the app passes neither.
  static Future<Database> open({
    DatabaseFactory? factory,
    String? path,
    List<Migration>? steps,
  }) async {
    final all = steps ?? migrations;
    assert(
      [
        for (var i = 0; i < all.length; i++) all[i].version == i + 1,
      ].every((ok) => ok),
      'migrations must be numbered 1, 2, 3, ... without gaps',
    );
    final db = factory ?? databaseFactory;
    final location = path ?? p.join(await db.getDatabasesPath(), fileName);
    return db.openDatabase(
      location,
      options: OpenDatabaseOptions(
        version: all.length,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, version) => _apply(db, all, 0, version),
        onUpgrade: (db, from, to) => _apply(db, all, from, to),
      ),
    );
  }

  /// Deletes the database file and its journal files. For the "Reset local
  /// data" action when the database cannot be opened.
  static Future<void> delete({DatabaseFactory? factory, String? path}) async {
    final db = factory ?? databaseFactory;
    await db.deleteDatabase(
      path ?? p.join(await db.getDatabasesPath(), fileName),
    );
  }

  static Future<void> _apply(
    Database db,
    List<Migration> all,
    int from,
    int to,
  ) async {
    for (final step in all) {
      if (step.version > from && step.version <= to) await step.up(db);
    }
  }
}

/// The open database, opened once in `bootstrap.dart` and passed in.
final databaseProvider = Provider<Database>(
  (ref) => throw UnimplementedError('databaseProvider is not overridden'),
);
