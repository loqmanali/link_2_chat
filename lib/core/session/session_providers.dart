import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:link_2_chat/core/session/session.dart';
import 'package:link_2_chat/core/session/session_store.dart';

/// Platform seam: the real preferences-backed store; tests override it.
final sessionStoreProvider = Provider<SessionStore>(
  (ref) => const SessionStore(),
);

/// The session read from storage before the first frame (`bootstrap.dart`
/// overrides this), so routing never waits on storage.
final initialSessionProvider = Provider<AppSession?>((ref) => null);

/// The signed-in session, or null when signed out. The auth actions call
/// [signedIn] and [signedOut]; the router's redirect watches it.
class SessionController extends Notifier<AppSession?> {
  @override
  AppSession? build() => ref.read(initialSessionProvider);

  /// Persists a new session and makes it current.
  Future<void> signedIn(AppSession session) async {
    await ref.read(sessionStoreProvider).write(session);
    state = session;
  }

  /// Signs out locally: clears storage and state.
  Future<void> signedOut() async {
    await ref.read(sessionStoreProvider).clear();
    state = null;
  }

  /// Follows a change the data layer already persisted (null when the
  /// account was deleted or the session ended).
  void follow(AppSession? session) => state = session;
}

final sessionControllerProvider =
    NotifierProvider<SessionController, AppSession?>(SessionController.new);
