import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:link_2_chat/core/session/session_providers.dart';
import 'package:link_2_chat/features/entries/entries.dart';

/// The link history of the signed-in account, newest first, live from the
/// store.
class HistoryState {
  const HistoryState({
    this.entries = const [],
    this.isLoading = false,
    this.error,
  });

  final List<PhoneEntry> entries;

  /// True until the first read arrives.
  final bool isLoading;

  /// The last read failure, when the stream errored.
  final Object? error;

  HistoryState copyWith({
    List<PhoneEntry>? entries,
    bool? isLoading,
    bool clearError = false,
    Object? error,
  }) => HistoryState(
    entries: entries ?? this.entries,
    isLoading: isLoading ?? this.isLoading,
    error: clearError ? null : (error ?? this.error),
  );

  @override
  bool operator ==(Object other) =>
      other is HistoryState &&
      other.isLoading == isLoading &&
      other.error == error &&
      _sameEntries(other.entries, entries);

  @override
  int get hashCode => Object.hash(isLoading, error, entries.length);

  /// Element-wise comparison: the entries change (a clear, a new link) must
  /// rebuild the list even when loading and error stay the same.
  static bool _sameEntries(List<PhoneEntry> a, List<PhoneEntry> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  String toString() => 'HistoryState(${entries.length} entries)';
}

/// Watches the signed-in account's history, one stream — the store re-reads
/// after every write, so this never polls.
class HistoryController extends Notifier<HistoryState> {
  StreamSubscription<List<PhoneEntry>>? _sub;

  @override
  HistoryState build() {
    _sub?.cancel();
    final session = ref.watch(sessionControllerProvider);
    if (session == null) return const HistoryState();
    _sub = ref
        .read(entriesStoreProvider)
        .watchHistory(session.userId)
        .listen(
          (entries) => state = HistoryState(entries: entries),
          onError:
              (Object error) =>
                  state = HistoryState(error: error, isLoading: false),
        );
    ref.onDispose(() {
      _sub?.cancel();
    });
    return const HistoryState(isLoading: true);
  }
}

final historyControllerProvider =
    NotifierProvider<HistoryController, HistoryState>(HistoryController.new);

/// Clears every entry of the signed-in account, after the screen's confirm
/// dialog said so.
final clearHistoryActionProvider =
    AsyncNotifierProvider<ClearHistoryAction, void>(
      ClearHistoryAction.new,
      retry: (_, _) => null,
    );

class ClearHistoryAction extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> clear() async {
    state = await AsyncValue.guard(() async {
      final session = ref.read(sessionControllerProvider);
      if (session == null) return;
      await ref.read(entriesStoreProvider).clearHistory(session.userId);
    });
  }
}
