import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:link_2_chat/core/local_db/change_watcher.dart';
import 'package:link_2_chat/core/local_db/local_database.dart';
import 'package:link_2_chat/features/entries/data/entries_store.dart';
import 'package:link_2_chat/features/entries/domain/link_target.dart';
import 'package:link_2_chat/features/entries/domain/phone_entry.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  final factory = databaseFactoryFfi;

  late EntriesStore store;

  setUp(() async {
    // A fresh file per test: an in-memory database is shared by every open
    // of the same path in one process, which would leak rows across tests.
    final dir = Directory.systemTemp.createTempSync('entries_test_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final db = await LocalDatabase.open(
      factory: factory,
      path: '${dir.path}/app.db',
    );
    store = EntriesStore(db, ChangeWatcher());
  });

  PhoneEntry entry(
    String id, {
    String userId = 'u1',
    String countryCode = '+20',
    LinkPlatform platform = LinkPlatform.whatsapp,
    int minutesAgo = 0,
  }) => PhoneEntry(
    id: id,
    userId: userId,
    phoneNumber: '1001234567',
    countryCode: countryCode,
    countryName: 'Egypt',
    platform: platform,
    createdAt: DateTime.fromMillisecondsSinceEpoch(
      DateTime(2026, 1, 1).millisecondsSinceEpoch - minutesAgo * 60000,
    ),
  );

  test('record stores an entry and history returns it newest first', () async {
    await store.record(entry('a', minutesAgo: 10));
    await store.record(entry('b', minutesAgo: 5));

    final history = await store.history('u1');
    expect(history.map((e) => e.id), ['b', 'a']);
    expect(history.first.link, 'https://wa.me/201001234567');
  });

  test('history only shows the requesting user', () async {
    await store.record(entry('a'));
    await store.record(entry('b', userId: 'u2'));

    expect((await store.history('u1')).map((e) => e.id), ['a']);
    expect((await store.history('u2')).map((e) => e.id), ['b']);
  });

  test(
    'delete removes one entry; clearHistory removes all of the user',
    () async {
      await store.record(entry('a'));
      await store.record(entry('b'));

      await store.delete('a');
      expect((await store.history('u1')).map((e) => e.id), ['b']);

      await store.clearHistory('u1');
      expect(await store.history('u1'), isEmpty);
    },
  );

  test('counters accumulate per platform and per country', () async {
    await store.record(entry('a'));
    await store.record(entry('b', platform: LinkPlatform.telegram));
    await store.record(entry('c', countryCode: '+49'));

    final stats = await store.stats('u1');
    expect(stats.totalGeneratedLinks, 3);
    expect(stats.whatsappLinks, 2);
    expect(stats.telegramLinks, 1);
    expect(stats.countryUsage, {'+20': 2, '+49': 1});
    expect(stats.getTopCountries(1).single.key, '+20');
    expect(stats.isEmpty, isFalse);
  });

  test('stats of a fresh user are empty', () async {
    final stats = await store.stats('nobody');
    expect(stats.isEmpty, isTrue);
    expect(stats.totalGeneratedLinks, 0);
  });

  test('watchHistory re-emits after a write', () async {
    final seen = <int>[];
    final sub = store.watchHistory('u1').listen((l) => seen.add(l.length));
    await pumpEventQueue();

    await store.record(entry('a'));
    await pumpEventQueue();

    expect(seen, [0, 1]);
    await sub.cancel();
  });
}
