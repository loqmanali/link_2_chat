import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:link_2_chat/core/local_db/local_database.dart';
import 'package:link_2_chat/core/local_db/meta_store.dart';
import 'package:link_2_chat/core/local_db/migrations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> _createNotes(DatabaseExecutor db) =>
    db.execute('CREATE TABLE notes (id INTEGER PRIMARY KEY, body TEXT)');

Future<void> _noteTitle(DatabaseExecutor db) =>
    addColumn(db, 'notes', 'title', 'TEXT');

void main() {
  sqfliteFfiInit();
  final factory = databaseFactoryFfi;

  test('a fresh install applies every migration', () async {
    final db = await LocalDatabase.open(
      factory: factory,
      path: inMemoryDatabasePath,
    );
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table'",
    );
    expect(tables.map((t) => t['name']), contains('meta'));
    await db.close();
  });

  test('an upgrade applies only the missing migrations', () async {
    final dir = Directory.systemTemp.createTempSync('db_test_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final path = '${dir.path}/app.db';
    final first = <Migration>[...migrations, const Migration(8, _createNotes)];
    var db = await LocalDatabase.open(
      factory: factory,
      path: path,
      steps: first,
    );
    await db.insert('notes', {'body': 'kept'});
    await db.close();

    db = await LocalDatabase.open(
      factory: factory,
      path: path,
      steps: [...first, const Migration(9, _noteTitle)],
    );
    final rows = await db.query('notes');
    expect(rows.single['body'], 'kept'); // not recreated
    expect(rows.single.containsKey('title'), isTrue); // migration 3 ran
    await db.close();
  });

  test('addColumn is idempotent', () async {
    final db = await LocalDatabase.open(
      factory: factory,
      path: inMemoryDatabasePath,
      steps: [...migrations, const Migration(8, _createNotes)],
    );
    await addColumn(db, 'notes', 'title', 'TEXT');
    await addColumn(
      db,
      'notes',
      'title',
      'TEXT',
    ); // would throw if it were bare
    await db.close();
  });

  test('migrations with a gap are refused', () async {
    await expectLater(
      LocalDatabase.open(
        factory: factory,
        path: inMemoryDatabasePath,
        steps: const [Migration(1, _createNotes), Migration(3, _noteTitle)],
      ),
      throwsA(isA<AssertionError>()),
    );
  });

  test('the shipped migrations are numbered without a gap', () {
    for (var i = 0; i < migrations.length; i++) {
      expect(migrations[i].version, i + 1);
    }
  });

  test('MetaStore reads, replaces and deletes a key', () async {
    final db = await LocalDatabase.open(
      factory: factory,
      path: inMemoryDatabasePath,
    );
    final meta = MetaStore(db);
    expect(await meta.read('k'), isNull);
    await meta.write('k', 'a');
    await meta.write('k', 'b');
    expect(await meta.read('k'), 'b');
    await meta.delete('k');
    expect(await meta.read('k'), isNull);
    await db.close();
  });
}
