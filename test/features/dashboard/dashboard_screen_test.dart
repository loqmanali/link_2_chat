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
import 'package:link_2_chat/features/dashboard/dashboard.dart';
import 'package:link_2_chat/features/entries/data/entries_store.dart';
import 'package:link_2_chat/features/entries/domain/link_target.dart';
import 'package:link_2_chat/features/entries/domain/phone_entry.dart';
import 'package:link_2_chat/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// The dashboard tab against a real local database: seeded entries show up as
/// the total counter, the per-platform counters and the top-country bars.
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

  testWidgets('seeded entries appear as counters, platforms and countries', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(const {});
    final dir = Directory.systemTemp.createTempSync('dashboard_screen_test_');
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
      await store.record(entry('b', countryCode: '+20'));
      await store.record(entry('c', platform: LinkPlatform.telegram));
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
        child: const _TestApp(child: DashboardScreen()),
      ),
    );
    // Let the watch streams do their first real reads, then rebuild frames.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 150)),
    );
    await tester.pump();
    await tester.pump();

    // The total counter says 3.
    expect(find.text('Total Links Generated'), findsOneWidget);
    expect(find.text('3'), findsAtLeastNWidgets(1));

    // Both platforms show with their counts.
    expect(find.text('WhatsApp'), findsWidgets);
    expect(find.text('Telegram'), findsWidgets);
    expect(find.text('(2)'), findsOneWidget);
    expect(find.text('(1)'), findsOneWidget);

    // The most-used country (+20, two links) is listed.
    expect(find.text('+20'), findsOneWidget);

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
