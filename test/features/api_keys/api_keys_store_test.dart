import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:link_2_chat/core/local_db/change_watcher.dart';
import 'package:link_2_chat/core/local_db/local_database.dart';
import 'package:link_2_chat/features/api_keys/data/api_keys_store.dart';
import 'package:link_2_chat/features/api_keys/domain/api_key.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  final factory = databaseFactoryFfi;

  late Database db;
  late ApiKeysStore store;

  setUp(() async {
    // A fresh file per test: an in-memory database is shared by every open
    // of the same path in one process, which would leak rows across tests.
    final dir = Directory.systemTemp.createTempSync('api_keys_test_');
    addTearDown(() => dir.deleteSync(recursive: true));
    db = await LocalDatabase.open(factory: factory, path: '${dir.path}/app.db');
    store = ApiKeysStore(db, ChangeWatcher());
  });

  Future<ApiKey> seedKey({
    String name = 'Mobile App',
    List<ApiPermission> permissions = const [
      ApiPermission.generateLinks,
      ApiPermission.viewHistory,
    ],
    String userId = 'u1',
  }) => store.create(
    userId: userId,
    name: name,
    description: 'For the mobile app',
    permissions: permissions,
  );

  test(
    'create stores a fresh key; keysForUser lists it newest first',
    () async {
      final first = await seedKey(name: 'First');
      final second = await seedKey(name: 'Second');

      expect(first.key, isNotEmpty);
      expect(first.key, isNot(equals(second.key)));
      expect(first.isActive, isTrue);
      expect(first.lastUsedAt, isNull);

      final keys = await store.keysForUser('u1');
      expect(keys.map((k) => k.name), ['Second', 'First']);
    },
  );

  test('keysForUser only shows the owning user', () async {
    await seedKey();
    await seedKey(userId: 'u2', name: 'Other user key');
    expect((await store.keysForUser('u1')).single.name, 'Mobile App');
    expect((await store.keysForUser('u2')).single.name, 'Other user key');
    expect(await store.keysForUser('nobody'), isEmpty);
  });

  test('permissions round-trip through the json array column', () async {
    const permissions = [
      ApiPermission.generateLinks,
      ApiPermission.viewAnalytics,
      ApiPermission.exportData,
      ApiPermission.viewTeamData,
      ApiPermission.manageTeam,
    ];
    await seedKey(permissions: permissions);

    final loaded = await store.keysForUser('u1');
    expect(loaded.single.permissions, permissions);
  });

  test('an unknown permission name in a row is skipped, not thrown', () async {
    final key = await seedKey();
    await db.update(
      'api_keys',
      {'permissions': '["generateLinks","timeTravel"]'},
      where: 'id = ?',
      whereArgs: [key.id],
    );
    final loaded = await store.keysForUser('u1');
    expect(loaded.single.permissions, [ApiPermission.generateLinks]);
  });

  test('setActive flips the switch without deleting the row', () async {
    final key = await seedKey();
    await store.setActive(key.id, false);
    expect((await store.keysForUser('u1')).single.isActive, isFalse);
    await store.setActive(key.id, true);
    expect((await store.keysForUser('u1')).single.isActive, isTrue);
  });

  test('delete removes the row and reports whether it existed', () async {
    final key = await seedKey();
    expect(await store.delete(key.id), isTrue);
    expect(await store.keysForUser('u1'), isEmpty);
    expect(await store.delete(key.id), isFalse);
  });

  test('maskedKey hides the middle like the pre-refactor card did', () {
    final key = ApiKey(
      id: 'k',
      userId: 'u',
      name: 'n',
      key: 'abcdefghijklmnopqrstuvwxyz',
      createdAt: DateTime(2026, 1, 1),
    );
    expect(key.maskedKey, 'abcdefgh...stuvwxyz');
  });

  test('watchKeysForUser re-emits after a write', () async {
    final seen = <int>[];
    final sub = store.watchKeysForUser('u1').listen((l) => seen.add(l.length));
    await pumpEventQueue();

    await seedKey();
    await pumpEventQueue();

    expect(seen, [0, 1]);
    await sub.cancel();
  });
}
