import 'dart:io';

import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:link_2_chat/core/design/app_theme.dart';
import 'package:link_2_chat/core/local_db/local_database.dart';
import 'package:link_2_chat/core/session/session.dart';
import 'package:link_2_chat/core/session/session_providers.dart';
import 'package:link_2_chat/core/settings/app_preferences.dart';
import 'package:link_2_chat/features/entries/entries.dart';
import 'package:link_2_chat/features/home/home.dart';
import 'package:link_2_chat/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:phone_form_field/phone_form_field.dart' show IsoCode;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// The home tab against a real local database: a valid number generates one
/// recorded link (and bumps the guest budget), a spent guest budget blocks
/// the next link with the localized limit sentence.
///
/// Every sqlite call runs inside `tester.runAsync`: the FFI database needs
/// the real event loop, which the fake test clock does not drive.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  final factory = databaseFactoryFfi;

  /// A fresh container over a fresh temp database and prefs; the session is
  /// the guest 'guest' account.
  Future<ProviderContainer> makeContainer(
    WidgetTester tester,
    Map<String, Object> prefsSeed,
  ) async {
    SharedPreferences.setMockInitialValues(prefsSeed);
    final dir = Directory.systemTemp.createTempSync('home_screen_test_');
    addTearDown(() => dir.deleteSync(recursive: true));

    late Database db;
    late SharedPreferences prefs;
    await tester.runAsync(() async {
      prefs = await SharedPreferences.getInstance();
      db = await LocalDatabase.open(
        factory: factory,
        path: '${dir.path}/app.db',
      );
    });

    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(prefs),
        initialSessionProvider.overrideWithValue(
          const AppSession(userId: 'guest', isGuest: true),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  PhoneDraft validDraft() => const PhoneDraft(
    isoCode: IsoCode.EG,
    phoneNumber: '1001234567',
    countryCode: '+20',
    countryName: 'Egypt',
    isValid: true,
  );

  testWidgets('a valid number records the entry and shows the result card', (
    tester,
  ) async {
    final container = await makeContainer(tester, {'guest_link_count': 0});
    final store = container.read(entriesStoreProvider);
    final prefs = container.read(sharedPreferencesProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const _TestApp(child: HomeScreen()),
      ),
    );
    await tester.pump();

    container.read(homeControllerProvider.notifier).phoneChanged(validDraft());
    await tester.pump();

    await tester.tap(find.text('WhatsApp'));
    // The action writes to sqlite on the real event loop; give it time.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 150)),
    );
    await tester.pump();

    // The card is on screen with the platform title.
    expect(find.text('Your WhatsApp Link'), findsOneWidget);
    // The link of the entry.
    expect(find.text('https://wa.me/201001234567'), findsOneWidget);

    // The entry was recorded with the full number and platform.
    var history = <PhoneEntry>[];
    await tester.runAsync(() async {
      history = await store.history('guest');
    });
    expect(history, hasLength(1));
    expect(history.single.phoneNumber, '1001234567');
    expect(history.single.countryCode, '+20');
    expect(history.single.platform, LinkPlatform.whatsapp);
    expect(history.single.link, 'https://wa.me/201001234567');

    // The guest budget moved 0 -> 1.
    expect(prefs.getInt('guest_link_count'), 1);

    await tester.runAsync(() => container.read(databaseProvider).close());
  });

  testWidgets('a spent guest budget blocks the next link', (tester) async {
    final container = await makeContainer(tester, {'guest_link_count': 2});
    final store = container.read(entriesStoreProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const _TestApp(child: HomeScreen()),
      ),
    );
    await tester.pump();

    container.read(homeControllerProvider.notifier).phoneChanged(validDraft());
    await tester.pump();

    await tester.tap(find.text('WhatsApp'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 150)),
    );
    await tester.pump();

    // The localized limit sentence is shown (the ARB sentence wraps lines).
    expect(
      find.textContaining('Guest users can only generate 2 links'),
      findsOneWidget,
    );
    // ...no result card appeared and no row landed.
    expect(find.text('Your WhatsApp Link'), findsNothing);
    var historyEmpty = false;
    await tester.runAsync(() async {
      historyEmpty = (await store.history('guest')).isEmpty;
    });
    expect(historyEmpty, isTrue);

    await tester.runAsync(() => container.read(databaseProvider).close());
  });

  testWidgets('the generate buttons stay disabled for an invalid number', (
    tester,
  ) async {
    final container = await makeContainer(tester, {'guest_link_count': 0});
    final store = container.read(entriesStoreProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const _TestApp(child: HomeScreen()),
      ),
    );
    await tester.pump();

    container
        .read(homeControllerProvider.notifier)
        .phoneChanged(
          const PhoneDraft(
            isoCode: IsoCode.EG,
            phoneNumber: '123',
            countryCode: '+20',
            countryName: 'Egypt',
            isValid: false,
          ),
        );
    await tester.pump();

    // The field shows the invalid-number sentence...
    expect(find.text('Please enter a valid phone number'), findsOneWidget);
    // ...and tapping the button records nothing.
    await tester.tap(find.text('WhatsApp'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 150)),
    );
    await tester.pump();
    var historyEmpty = false;
    await tester.runAsync(() async {
      historyEmpty = (await store.history('guest')).isEmpty;
    });
    expect(historyEmpty, isTrue);

    await tester.runAsync(() => container.read(databaseProvider).close());
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
