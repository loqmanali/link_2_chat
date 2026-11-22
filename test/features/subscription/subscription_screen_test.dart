import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:link_2_chat/core/design/app_theme.dart';
import 'package:link_2_chat/core/json/json_reader.dart';
import 'package:link_2_chat/core/local_db/change_watcher.dart';
import 'package:link_2_chat/core/local_db/local_database.dart';
import 'package:link_2_chat/core/session/session.dart';
import 'package:link_2_chat/core/session/session_providers.dart';
import 'package:link_2_chat/core/settings/app_preferences.dart';
import 'package:link_2_chat/features/auth/auth.dart';
import 'package:link_2_chat/features/auth/data/users_store.dart';
import 'package:link_2_chat/features/subscription/domain/plan.dart';
import 'package:link_2_chat/features/subscription/presentation/routes.dart';
import 'package:link_2_chat/features/subscription/presentation/subscription_screen.dart';
import 'package:link_2_chat/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// `UsersStore` with the account-row reads corrected (the `preferences`
/// column is json text the shipped store does not decode — see
/// `sign_in_screen_test.dart`). DELETE once the data layer is fixed.
class TestUsersStore extends UsersStore {
  TestUsersStore(super.db, super.watcher) : _db = db, _watcher = watcher;

  final Database _db;
  final ChangeWatcher _watcher;

  @override
  Future<User?> byEmail(String email) =>
      _by('email = ?', [email.trim().toLowerCase()]);

  @override
  Future<User?> byId(String id) => _by('id = ?', [id]);

  @override
  Stream<User?> watchById(String id) => _watcher.watch(() => byId(id));

  Future<User?> _by(String where, List<Object?> args) async {
    final rows = await _db.query(
      'users',
      where: where,
      whereArgs: args,
      limit: 1,
    );
    return rows.isEmpty ? null : _user(rows.single);
  }

  User _user(Map<Object?, Object?> row) {
    final r = JsonReader.of(row);
    final prefs =
        (jsonDecode(r.string('preferences')) as Map).cast<String, String>();
    final expiry = r.integerOrNull('subscription_expiry');
    final lastLogin = r.integerOrNull('last_login_at');
    return User(
      id: r.string('id'),
      name: r.string('name'),
      email: r.string('email'),
      passwordHash: r.string('password_hash'),
      role: r.string('role'),
      subscriptionTier: SubscriptionTier.of(r.string('subscription_tier')),
      subscriptionExpiry:
          expiry == null ? null : DateTime.fromMillisecondsSinceEpoch(expiry),
      preferences: prefs,
      createdAt: DateTime.fromMillisecondsSinceEpoch(r.integer('created_at')),
      lastLoginAt:
          lastLogin == null
              ? null
              : DateTime.fromMillisecondsSinceEpoch(lastLogin),
    );
  }
}

void main() {
  sqfliteFfiInit();
  final factory = databaseFactoryFfi;

  late Directory dir;
  late Database db;
  late TestUsersStore users;
  late SharedPreferences preferences;
  late ProviderContainer container;
  var containerReady = false;
  late String userId;
  late User seededUser;

  Future<void> pumpScreen(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: subscriptionPath,
      routes: [
        ...subscriptionRoutes,
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
          usersStoreProvider.overrideWithValue(users),
          sharedPreferencesProvider.overrideWithValue(preferences),
          // The screen's live account stream would issue its first sqlite
          // read on the fake test clock, which never completes; pin it to
          // the seeded row instead.
          currentUserProvider.overrideWith((ref) => Stream.value(seededUser)),
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
      tester.element(find.byType(SubscriptionScreen)),
    );
    containerReady = true;
  }

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('subscription_screen_test_');
    addTearDown(() => dir.deleteSync(recursive: true));
    db = await LocalDatabase.open(factory: factory, path: '${dir.path}/app.db');
    addTearDown(db.close);
    users = TestUsersStore(db, ChangeWatcher());
    final user = await users.create(
      name: 'Sara',
      email: 'sara@example.com',
      passwordHash: hashPassword('secret123'),
    );
    userId = user.id;
    await users.updateSubscription(userId, SubscriptionTier.professional, null);
    seededUser = (await users.byId(userId))!;
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
  });

  tearDown(() {
    if (containerReady) container.dispose();
  });

  testWidgets('a premium account sees its plan banner and the catalog', (
    tester,
  ) async {
    await pumpScreen(tester);
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Subscription Plans'), findsOneWidget);
    expect(find.text('Current Plan: Professional'), findsOneWidget);
    expect(find.text('Status: Active'), findsOneWidget);
    expect(find.text('No expiration date'), findsOneWidget);
    for (final plan in planCatalog) {
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Text &&
              widget.data != null &&
              planNames[plan.tier] == widget.data,
        ),
        findsOneWidget,
        reason: 'missing plan card for ${plan.tier.name}',
      );
    }
    expect(find.text('\$4.99'), findsOneWidget);
    expect(find.text('POPULAR'), findsOneWidget);
    expect(find.text('Current Plan'), findsOneWidget);
  });

  testWidgets('confirming a downgrade moves the account row to the tier', (
    tester,
  ) async {
    await pumpScreen(tester);
    await tester.pump(const Duration(milliseconds: 100));
    // The plan change is refused without a signed-in session, so enter one.
    await tester.runAsync(() async {
      await container
          .read(sessionControllerProvider.notifier)
          .signedIn(AppSession(userId: userId, isGuest: false));
    });
    await tester.pump();

    // Professional -> Basic reads as a downgrade. Both the Free and the
    // Basic card carry a Downgrade button; take the Basic card's, scrolling
    // it into view first.
    final basicCard = find.ancestor(
      of: find.text('Basic'),
      matching: find.byType(Card),
    );
    final downgradeButton = find.descendant(
      of: basicCard,
      matching: find.text('Downgrade'),
    );
    await tester.ensureVisible(downgradeButton);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(downgradeButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Downgrade Plan?'), findsOneWidget);
    // The confirm button shares its label with the card button behind the
    // dialog, so pick the one inside the dialog. The store write happens on
    // the real event loop; read the row there too.
    User? updated;
    await tester.runAsync(() async {
      unawaited(
        tester.tap(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.text('Downgrade'),
          ),
        ),
      );
      final deadline = DateTime.now().add(const Duration(seconds: 5));
      while ((updated = await users.byId(userId))?.subscriptionTier !=
          SubscriptionTier.basic) {
        if (DateTime.now().isAfter(deadline)) break;
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(updated?.subscriptionTier, SubscriptionTier.basic);
  });
}

/// The English plan names, to match rendered card titles.
const planNames = {
  SubscriptionTier.free: 'Free',
  SubscriptionTier.basic: 'Basic',
  SubscriptionTier.professional: 'Professional',
  SubscriptionTier.enterprise: 'Enterprise',
};
