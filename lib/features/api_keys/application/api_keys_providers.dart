import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:link_2_chat/core/api/failure.dart';
import 'package:link_2_chat/core/local_db/change_watcher.dart';
import 'package:link_2_chat/core/local_db/local_database.dart';
import 'package:link_2_chat/core/session/session_providers.dart';
import 'package:link_2_chat/features/api_keys/data/api_keys_store.dart';
import 'package:link_2_chat/features/api_keys/domain/api_key.dart';

/// The change ticks for the `api_keys` table.
final apiKeysWatcherProvider = Provider<ChangeWatcher>((ref) {
  final watcher = ChangeWatcher();
  ref.onDispose(watcher.close);
  return watcher;
});

/// The API keys store, over the local database opened in `bootstrap.dart`.
final apiKeysStoreProvider = Provider<ApiKeysStore>(
  (ref) => ApiKeysStore(
    ref.watch(databaseProvider),
    ref.watch(apiKeysWatcherProvider),
  ),
);

/// One screenful of API keys.
class ApiKeysState {
  const ApiKeysState({this.keys = const AsyncValue.loading()});

  final AsyncValue<List<ApiKey>> keys;
}

/// The signed-in account's keys, re-read after every write.
final apiKeysProvider = NotifierProvider<ApiKeysController, ApiKeysState>(
  ApiKeysController.new,
);

class ApiKeysController extends Notifier<ApiKeysState> {
  @override
  ApiKeysState build() {
    final session = ref.watch(sessionControllerProvider);
    if (session == null) return const ApiKeysState();
    final subscription = ref
        .watch(apiKeysStoreProvider)
        .watchKeysForUser(session.userId)
        .listen(
          (keys) => state = ApiKeysState(keys: AsyncValue.data(keys)),
          onError:
              (Object error) =>
                  state = ApiKeysState(
                    keys: AsyncValue<List<ApiKey>>.error(
                      error,
                      StackTrace.current,
                    ),
                  ),
        );
    ref.onDispose(subscription.cancel);
    return const ApiKeysState();
  }
}

/// Creates a key. At least one permission is required. The freshly created
/// key comes back from [CreateApiKeyAction.create] so the screen can reveal
/// it exactly once.
final createApiKeyActionProvider =
    AsyncNotifierProvider<CreateApiKeyAction, void>(
      CreateApiKeyAction.new,
      retry: (_, _) => null,
    );

class CreateApiKeyAction extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<ApiKey?> create({
    required String name,
    required String description,
    required List<ApiPermission> permissions,
  }) async {
    state = const AsyncLoading();
    ApiKey? created;
    state = await AsyncValue.guard(() async {
      final session = ref.read(sessionControllerProvider);
      if (session == null || session.isGuest) {
        throw const AuthFailure('User not authenticated.');
      }
      if (name.trim().isEmpty) {
        throw const ValidationFailure('Please enter a name for your API key.');
      }
      if (permissions.isEmpty) {
        throw const ValidationFailure('Please select at least one permission.');
      }
      created = await ref
          .read(apiKeysStoreProvider)
          .create(
            userId: session.userId,
            name: name,
            description: description,
            permissions: permissions,
          );
    });
    return created;
  }
}

/// Deletes one key.
final deleteApiKeyActionProvider =
    AsyncNotifierProvider<DeleteApiKeyAction, void>(
      DeleteApiKeyAction.new,
      retry: (_, _) => null,
    );

class DeleteApiKeyAction extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> delete(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(apiKeysStoreProvider).delete(id),
    );
  }
}

/// Enables or disables one key.
final toggleApiKeyActionProvider =
    AsyncNotifierProvider<ToggleApiKeyAction, void>(
      ToggleApiKeyAction.new,
      retry: (_, _) => null,
    );

class ToggleApiKeyAction extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> toggle({required String id, required bool isActive}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(apiKeysStoreProvider).setActive(id, isActive),
    );
  }
}
