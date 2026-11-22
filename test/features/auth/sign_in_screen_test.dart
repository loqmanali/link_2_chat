import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:link_2_chat/core/design/app_theme.dart';
import 'package:link_2_chat/core/local_db/change_watcher.dart';
import 'package:link_2_chat/core/local_db/local_database.dart';
import 'package:link_2_chat/core/session/session.dart';
import 'package:link_2_chat/core/session/session_providers.dart';
import 'package:link_2_chat/core/settings/app_preferences.dart';
import 'package:link_2_chat/features/auth/auth.dart';
import 'package:link_2_chat/features/auth/data/users_store.dart';
import 'package:link_2_chat/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  final factory = databaseFactoryFfi;

  late Directory dir;
  late Database db;
  late UsersStore users;
  late SharedPreferences preferences;
  late ProviderContainer container;
  var containerReady = false;
  late String userId;

  Future<void> pumpScreen(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: authSignInPath,
      routes: [
        ...authRoutes,
        // Where the redirect would land after a sign-in; the assertion reads
        // the session, it never waits for navigation.
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: SizedBox()),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),

          sharedPreferencesProvider.overrideWithValue(preferences),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    container = ProviderScope.containerOf(
      tester.element(find.byType(SignInScreen)),
    );
    containerReady = true;
  }

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('sign_in_screen_test_');
    addTearDown(() => dir.deleteSync(recursive: true));
    db = await LocalDatabase.open(factory: factory, path: '${dir.path}/app.db');
    addTearDown(db.close);
    users = UsersStore(db, ChangeWatcher());
    final user = await users.create(
      name: 'Sara',
      email: 'sara@example.com',
      passwordHash: hashPassword('secret123'),
    );
    userId = user.id;
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
  });

  tearDown(() {
    if (containerReady) container.dispose();
  });

  testWidgets(
    'the right credentials sign the account in as a non-guest session',
    (tester) async {
      await pumpScreen(tester);
      // The actions start in their async build; one pump settles the button.
      await tester.pump(const Duration(milliseconds: 100));

      await tester.enterText(find.byType(TextField).at(0), 'sara@example.com');
      await tester.enterText(find.byType(TextField).at(1), 'secret123');
      // The action reads the sqlite file over real async, which the fake
      // test clock never drives; tap and wait on the real event loop.
      await tester.runAsync(() async {
        unawaited(tester.tap(find.text('Login')));
        final deadline = DateTime.now().add(const Duration(seconds: 5));
        while (container.read(sessionControllerProvider) == null) {
          if (DateTime.now().isAfter(deadline)) break;
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final session = container.read(sessionControllerProvider);
      expect(session, AppSession(userId: userId, isGuest: false));
    },
  );

  testWidgets('a wrong password leaves the visitor signed out', (tester) async {
    await pumpScreen(tester);
    await tester.pump(const Duration(milliseconds: 100));

    await tester.enterText(find.byType(TextField).at(0), 'sara@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'wrong-password');
    await tester.runAsync(() async {
      unawaited(tester.tap(find.text('Login')));
      final deadline = DateTime.now().add(const Duration(seconds: 5));
      while (!container.read(signInActionProvider).hasError) {
        if (DateTime.now().isAfter(deadline)) break;
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final session = container.read(sessionControllerProvider);
    expect(session, isNull);
  });

  // Blocked upstream: the shipped auth actions return `Future<void>` and
  // never publish the failure on their provider (`state = await
  // AsyncValue.guard(...)` is missing), so the `ref.listen` in the screen
  // never fires and no toast can render. Re-enable once the actions publish
  // their state.
  testWidgets('a wrong password toasts the auth failure', (tester) async {
    await pumpScreen(tester);
    await tester.pump(const Duration(milliseconds: 100));

    await tester.enterText(find.byType(TextField).at(0), 'sara@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'wrong-password');
    // The store read needs the real event loop: tap inside runAsync and wait
    // for the action to publish its failure there.
    await tester.runAsync(() async {
      unawaited(tester.tap(find.text('Login')));
      final deadline = DateTime.now().add(const Duration(seconds: 5));
      while (!container.read(signInActionProvider).hasError) {
        if (DateTime.now().isAfter(deadline)) break;
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    });
    // ignore: avoid_print
    print('ACTION AFTER POLL: ${container.read(signInActionProvider)}');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    // ignore: avoid_print
    print('ACTION AFTER PUMP: ${container.read(signInActionProvider)}');
    final snackTexts =
        tester
            .widgetList<Text>(find.byType(Text))
            .map((t) => t.data ?? '')
            .where((t) => t.isNotEmpty)
            .toList();
    // ignore: avoid_print
    print('SNACK AREA TEXTS: $snackTexts');

    expect(find.textContaining('Invalid email or password'), findsOneWidget);
  });

  testWidgets('an empty form shows the inline validation sentences', (
    tester,
  ) async {
    await pumpScreen(tester);
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('Login'));
    await tester.pump();

    expect(find.text('Please enter your email'), findsOneWidget);
    expect(find.text('Please enter your password'), findsOneWidget);
    expect(container.read(sessionControllerProvider), isNull);
  });
}
