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
import 'package:link_2_chat/features/auth/auth.dart';
import 'package:link_2_chat/features/settings/application/settings_providers.dart';
import 'package:link_2_chat/features/settings/presentation/settings_screen.dart';
import 'package:link_2_chat/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// The signed-in account the screen renders. `testWidgets` runs in
/// fakeAsync, where sqlite futures never settle — so the seeded user is
/// also fed to [currentUserProvider] directly.
final _seededUser = User(
  id: 'u1',
  name: 'Layla',
  email: 'layla@example.com',
  passwordHash: 'hash',
  subscriptionTier: SubscriptionTier.professional,
  createdAt: DateTime(2026, 1, 1),
  lastLoginAt: DateTime(2026, 1, 2),
);

void main() {
  sqfliteFfiInit();
  final factory = databaseFactoryFfi;

  late Database db;
  late SharedPreferences prefs;

  setUp(() async {
    // A fresh file per test: an in-memory database is shared by every open
    // of the same path in one process, which would leak rows across tests.
    final dir = Directory.systemTemp.createTempSync('settings_test_');
    addTearDown(() => dir.deleteSync(recursive: true));
    db = await LocalDatabase.open(factory: factory, path: '${dir.path}/app.db');
    await db.insert('users', {
      'id': _seededUser.id,
      'name': _seededUser.name,
      'email': _seededUser.email,
      'password_hash': _seededUser.passwordHash,
      'role': _seededUser.role,
      'subscription_tier': _seededUser.subscriptionTier.name,
      'subscription_expiry': null,
      'preferences': '{}',
      'created_at': _seededUser.createdAt.millisecondsSinceEpoch,
      'last_login_at': _seededUser.lastLoginAt!.millisecondsSinceEpoch,
    });

    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  ProviderContainer makeContainer({required bool guest}) {
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        initialSessionProvider.overrideWithValue(
          guest
              ? const AppSession(userId: 'guest', isGuest: true)
              : const AppSession(userId: 'u1', isGuest: false),
        ),
        sharedPreferencesProvider.overrideWithValue(prefs),
        appVersionProvider.overrideWithValue(const AsyncValue.data('9.9.9')),
        if (!guest)
          currentUserProvider.overrideWith((ref) => Stream.value(_seededUser)),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  Future<ProviderContainer> pumpScreen(
    WidgetTester tester, {
    required bool guest,
  }) async {
    final container = makeContainer(guest: guest);
    // A tall viewport, so the whole settings list builds (a ListView never
    // builds what is scrolled away).
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: SettingsScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('section headers, profile and theme tiles render', (
    tester,
  ) async {
    await pumpScreen(tester, guest: false);

    // The English strings of the ARB (the test runs in English).
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Behavior'), findsOneWidget);
    expect(find.text('About'), findsOneWidget);
    expect(find.text('Subscription'), findsOneWidget);

    // The signed-in profile replaced the guest card.
    expect(find.text('Guest User'), findsNothing);
    expect(find.text('Layla'), findsOneWidget);
    expect(find.text('layla@example.com'), findsOneWidget);
    expect(find.text('Edit Profile'), findsOneWidget);

    // Theme tiles and language tiles are all there.
    expect(find.text('System'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('العربية'), findsOneWidget);

    // The behavior toggles and the about version from the override.
    expect(find.text('Save links history'), findsOneWidget);
    expect(find.text('Show QR code by default'), findsOneWidget);
    expect(find.text('9.9.9'), findsOneWidget);
  });

  testWidgets('a guest session shows the guest card instead of the profile', (
    tester,
  ) async {
    await pumpScreen(tester, guest: true);

    expect(find.text('Guest User'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Sign Up'), findsOneWidget);
    expect(find.text('Layla'), findsNothing);
  });

  testWidgets('picking a theme tile updates themeModeControllerProvider', (
    tester,
  ) async {
    final container = await pumpScreen(tester, guest: false);
    expect(container.read(themeModeControllerProvider), ThemeMode.system);

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(container.read(themeModeControllerProvider), ThemeMode.dark);
    expect(prefs.getString('pref.theme_mode'), 'dark');

    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();
    expect(container.read(themeModeControllerProvider), ThemeMode.light);
  });

  testWidgets('the behavior toggles write their legacy keys', (tester) async {
    final container = await pumpScreen(tester, guest: false);

    await tester.tap(find.text('Save links history'));
    await tester.pumpAndSettle();
    expect(container.read(saveHistoryControllerProvider), isFalse);
    expect(prefs.getBool('save_links_history'), isFalse);

    await tester.tap(find.text('Show QR code by default'));
    await tester.pumpAndSettle();
    expect(container.read(showQrControllerProvider), isTrue);
    expect(prefs.getBool('show_qr_by_default'), isTrue);
  });
}
