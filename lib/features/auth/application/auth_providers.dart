import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:link_2_chat/core/api/failure.dart';
import 'package:link_2_chat/core/local_db/change_watcher.dart';
import 'package:link_2_chat/core/local_db/local_database.dart';
import 'package:link_2_chat/core/session/session.dart';
import 'package:link_2_chat/core/session/session_providers.dart';
import 'package:link_2_chat/core/settings/app_preferences.dart';
import 'package:link_2_chat/features/auth/data/users_store.dart';
import 'package:link_2_chat/features/auth/domain/password_hasher.dart';
import 'package:link_2_chat/features/auth/domain/user.dart';

/// The change ticks for the `users` table.
final authWatcherProvider = Provider<ChangeWatcher>((ref) {
  final watcher = ChangeWatcher();
  ref.onDispose(watcher.close);
  return watcher;
});

/// The device-local accounts, over the local database opened in
/// `bootstrap.dart`.
final usersStoreProvider = Provider<UsersStore>(
  (ref) =>
      UsersStore(ref.watch(databaseProvider), ref.watch(authWatcherProvider)),
);

/// The signed-in account row, or null for a guest or a signed-out visitor.
/// Re-reads whenever the store writes.
final currentUserProvider = StreamProvider<User?>((ref) {
  final session = ref.watch(sessionControllerProvider);
  if (session == null || session.isGuest) return Stream.value(null);
  return ref.watch(usersStoreProvider).watchById(session.userId);
});

/// The effective tier: the account's plan, or free for guests.
final subscriptionTierProvider = Provider<SubscriptionTier>((ref) {
  final user = ref.watch(currentUserProvider).value;
  return user?.subscriptionTier ?? SubscriptionTier.free;
});

/// Signs a local account in: finds the account, checks the hash, records the
/// login. Throws [AuthFailure] on unknown email or a wrong password.
final signInActionProvider = AsyncNotifierProvider<SignInAction, void>(
  SignInAction.new,
  retry: (_, _) => null,
);

class SignInAction extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> signIn({required String email, required String password}) =>
      AsyncValue.guard(() async {
        final store = ref.read(usersStoreProvider);
        final user = await store.byEmail(email);
        if (user == null || user.passwordHash != hashPassword(password)) {
          throw const AuthFailure('Invalid email or password.');
        }
        await store.touchLogin(user.id);
        await ref
            .read(sessionControllerProvider.notifier)
            .signedIn(AppSession(userId: user.id, isGuest: false));
      });
}

/// Creates a local account and signs it in.
final signUpActionProvider = AsyncNotifierProvider<SignUpAction, void>(
  SignUpAction.new,
  retry: (_, _) => null,
);

class SignUpAction extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) => AsyncValue.guard(() async {
    if (password.length < 6) {
      throw const ValidationFailure('Password must be at least 6 characters.');
    }
    final user = await ref
        .read(usersStoreProvider)
        .create(name: name, email: email, passwordHash: hashPassword(password));
    await ref
        .read(sessionControllerProvider.notifier)
        .signedIn(AppSession(userId: user.id, isGuest: false));
  });
}

/// Enters the app without an account: limited locally, marked in the session.
final guestSignInActionProvider =
    AsyncNotifierProvider<GuestSignInAction, void>(
      GuestSignInAction.new,
      retry: (_, _) => null,
    );

class GuestSignInAction extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> enterAsGuest() => AsyncValue.guard(() async {
    // Reset the guest link budget each time guest mode is entered, matching
    // the pre-refactor login screen.
    await ref.read(sharedPreferencesProvider).setInt('guest_link_count', 0);
    await ref
        .read(sessionControllerProvider.notifier)
        .signedIn(const AppSession(userId: 'guest', isGuest: true));
  });
}

/// Signs out to the public screens.
final signOutActionProvider = AsyncNotifierProvider<SignOutAction, void>(
  SignOutAction.new,
  retry: (_, _) => null,
);

class SignOutAction extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> signOut() => AsyncValue.guard(() async {
    await ref.read(sessionControllerProvider.notifier).signedOut();
  });
}

/// Edits the signed-in account's profile (name and/or password).
final updateProfileActionProvider =
    AsyncNotifierProvider<UpdateProfileAction, void>(
      UpdateProfileAction.new,
      retry: (_, _) => null,
    );

class UpdateProfileAction extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> updateProfile({String? name, String? newPassword}) =>
      AsyncValue.guard(() async {
        final session = ref.read(sessionControllerProvider);
        if (session == null || session.isGuest) {
          throw const AuthFailure('No signed-in account.');
        }
        await ref
            .read(usersStoreProvider)
            .updateProfile(
              session.userId,
              name: name,
              passwordHash:
                  newPassword == null || newPassword.isEmpty
                      ? null
                      : hashPassword(newPassword),
            );
      });
}

/// Deletes the signed-in account with everything it owns locally, then signs
/// out. The password must match — it is the only confirmation the app has.
final deleteAccountActionProvider =
    AsyncNotifierProvider<DeleteAccountAction, void>(
      DeleteAccountAction.new,
      retry: (_, _) => null,
    );

class DeleteAccountAction extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> delete({required String password}) => AsyncValue.guard(() async {
    final session = ref.read(sessionControllerProvider);
    if (session == null || session.isGuest) {
      throw const AuthFailure('No signed-in account.');
    }
    final store = ref.read(usersStoreProvider);
    final user = await store.byId(session.userId);
    if (user == null || user.passwordHash != hashPassword(password)) {
      throw const AuthFailure('Incorrect password.');
    }
    await store.delete(user.id);
    await ref.read(sessionControllerProvider.notifier).signedOut();
  });
}
