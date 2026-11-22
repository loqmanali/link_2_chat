import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:link_2_chat/core/local_db/change_watcher.dart';
import 'package:link_2_chat/core/local_db/local_database.dart';
import 'package:link_2_chat/features/entries/data/entries_store.dart';

/// The change ticks for everything the [EntriesStore] writes. One watcher for
/// the app so a write anywhere refreshes every watching screen.
final entriesWatcherProvider = Provider<ChangeWatcher>((ref) {
  final watcher = ChangeWatcher();
  ref.onDispose(watcher.close);
  return watcher;
});

/// The history and counters store, over the local database opened in
/// `bootstrap.dart`. Tests override [databaseProvider] with an in-memory
/// database instead of this store.
final entriesStoreProvider = Provider<EntriesStore>(
  (ref) => EntriesStore(
    ref.watch(databaseProvider),
    ref.watch(entriesWatcherProvider),
  ),
);
