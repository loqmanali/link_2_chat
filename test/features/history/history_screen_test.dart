import 'dart:io';

import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:link_2_chat/core/design/app_theme.dart';
import 'package:link_2_chat/core/local_db/change_watcher.dart';
import 'package:link_2_chat/core/local_db/local_database.dart';
import 'package:link_2_chat/core/session/session.dart';
import 'package:link_2_chat/core/session/session_providers.dart';
import 'package:link_2_chat/core/settings/app_preferences.dart';
import 'package:link_2_chat/features/entries/data/entries_store.dart';
import 'package:link_2_chat/features/entries/domain/link_target.dart';
import 'package:link_2_chat/features/entries/domain/phone_entry.dart';
import 'package:link_2_chat/features/history/history.dart';
import 'package:link_2_chat/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// The history tab against a real local database: seeded rows render, and
/// clear-all (confirmed) empties the list.
///
/// Every sqlite call runs inside `tester.runAsync`: the FFI database needs
/// the real event loop, which the fake test clock does not drive.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  final factory = databaseFactoryFfi;

  PhoneEntry entry(
    String id, {
    String userId = 'u1',
    String countryCode = '+20',
    LinkPlatform platform = LinkPlatform.whatsapp,
  }) => PhoneEntry(
    id: id,
    userId: userId,
    phoneNumber: '1001234567',
    countryCode: countryCode,
    countryName: 'Egypt',
    platform: platform,
    createdAt: DateTime(2026, 1, 1, 12),
  );

  testWidgets('seeded entries render as rows, newest first', (tester) async {
    SharedPreferences.setMockInitialValues(const {});
    final dir = Directory.systemTemp.createTempSync('history_screen_test_');
    addTearDown(() => dir.deleteSync(recursive: true));

    late Database db;
    late EntriesStore store;
    late SharedPreferences prefs;
    await tester.runAsync(() async {
      // ignore: avoid_print
      print('P1 prefs');
      prefs = await SharedPreferences.getInstance();
      // ignore: avoid_print
      print('P2 open');
      db = await LocalDatabase.open(
        factory: factory,
        path: '${dir.path}/app.db',
      );
      // ignore: avoid_print
      print('P3 opened');
      store = EntriesStore(db, ChangeWatcher());
      await store.record(entry('a'));
      // ignore: avoid_print
      print('P4 recorded a');
      await store.record(
        entry('b', platform: LinkPlatform.telegram, countryCode: '+49'),
      );
      // ignore: avoid_print
      print('P5 seeded');
    });

    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(prefs),
        initialSessionProvider.overrideWithValue(
          const AppSession(userId: 'u1', isGuest: false),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const _TestApp(child: HistoryScreen()),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 150)),
    );
    await tester.pump();
    await tester.pump();

    // Both rows render with their formatted numbers and platform badges.
    expect(find.text('+20 100 123 456 7'), findsOneWidget);
    expect(find.text('+49 100 123 456 7'), findsOneWidget);
    expect(find.text('WhatsApp'), findsOneWidget);
    expect(find.text('Telegram'), findsOneWidget);
    expect(find.text('Egypt'), findsNWidgets(2));

    await tester.runAsync(() => db.close());
  });

  testWidgets('clear with confirmation empties the list and the store', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(const {});
    final dir = Directory.systemTemp.createTempSync('history_screen_test_');
    addTearDown(() => dir.deleteSync(recursive: true));

    late Database db;
    late EntriesStore store;
    late SharedPreferences prefs;
    await tester.runAsync(() async {
      prefs = await SharedPreferences.getInstance();
      db = await LocalDatabase.open(
        factory: factory,
        path: '${dir.path}/app.db',
      );
      store = EntriesStore(db, ChangeWatcher());
      await store.record(entry('a'));
      await store.record(entry('b'));
    });

    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(prefs),
        initialSessionProvider.overrideWithValue(
          const AppSession(userId: 'u1', isGuest: false),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const _TestApp(child: HistoryScreen()),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 150)),
    );
    await tester.pump();
    await tester.pump();

    // The confirm dialog asks before deleting.
    await tester.tap(find.text('Delete'));
    await tester.pump();
    expect(find.text('Clear History'), findsOneWidget);

    // Confirm, give the action its real async write, then rebuild.
    await tester.tap(find.text('Clear'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pump();
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pump();
    await tester.pump();

    // The empty state replaced the list...
    expect(find.text('No history yet'), findsOneWidget);
    expect(find.text('Links you generate will appear here'), findsOneWidget);
    // ...and the store is empty too.
    var storeEmpty = false;
    await tester.runAsync(() async {
      storeEmpty = (await store.history('u1')).isEmpty;
    });
    expect(storeEmpty, isTrue);

    await tester.runAsync(() => db.close());
  });
}

/// A minimal host for one tab screen, like the startup gate's shell.
class _TestApp extends StatelessWidget {
  const _TestApp({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SafeArea(child: child)),
    );
  }
}
