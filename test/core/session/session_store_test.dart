import 'package:flutter_test/flutter_test.dart';
import 'package:link_2_chat/core/session/session.dart';
import 'package:link_2_chat/core/session/session_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('write then read round-trips the session', () async {
    SharedPreferences.setMockInitialValues({});
    const store = SessionStore();
    const session = AppSession(userId: 'u1', isGuest: false);

    await store.write(session);
    expect(await store.read(), session);

    await store.clear();
    expect(await store.read(), isNull);
  });

  test('a corrupted value reads as signed out and is removed', () async {
    SharedPreferences.setMockInitialValues({SessionStore.key: '{not json'});
    const store = SessionStore();

    expect(await store.read(), isNull);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(SessionStore.key), isNull);
  });

  test('the legacy keys migrate once into the versioned key', () async {
    SharedPreferences.setMockInitialValues({
      SessionStore.legacyUserIdKey: 'old-user',
      SessionStore.legacyGuestKey: true,
    });
    const store = SessionStore();

    final migrated = await store.read();
    expect(migrated, const AppSession(userId: 'old-user', isGuest: true));

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(SessionStore.key), isNotNull);
    expect(prefs.getString(SessionStore.legacyUserIdKey), isNull);
    expect(prefs.getBool(SessionStore.legacyGuestKey), isNull);
    // A second read comes from the versioned key and reads the same.
    expect(await store.read(), migrated);
  });

  test('no session anywhere reads null', () async {
    SharedPreferences.setMockInitialValues({});
    expect(await const SessionStore().read(), isNull);
  });
}
