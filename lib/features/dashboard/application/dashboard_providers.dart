import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:link_2_chat/core/session/session_providers.dart';
import 'package:link_2_chat/features/entries/entries.dart';

/// The counters and lists the dashboard tab shows. A snapshot of the two
/// streams; the recent list is bounded like the pre-refactor
/// `maxRecentEntries`.
class DashboardState {
  const DashboardState({
    this.totalLinks = 0,
    this.whatsappLinks = 0,
    this.telegramLinks = 0,
    this.topCountries = const [],
    this.recentEntries = const [],
    this.isLoading = false,
    this.error,
  });

  final int totalLinks;
  final int whatsappLinks;
  final int telegramLinks;

  /// The most-used countries, best first (dial code -> count).
  final List<MapEntry<String, int>> topCountries;
  final List<PhoneEntry> recentEntries;

  /// True until the first data of both streams arrived.
  final bool isLoading;

  /// The last read failure, when a stream errored.
  final Object? error;

  bool get isEmpty => totalLinks == 0;

  DashboardState copyWith({
    int? totalLinks,
    int? whatsappLinks,
    int? telegramLinks,
    List<MapEntry<String, int>>? topCountries,
    List<PhoneEntry>? recentEntries,
    bool? isLoading,
    bool clearError = false,
    Object? error,
  }) => DashboardState(
    totalLinks: totalLinks ?? this.totalLinks,
    whatsappLinks: whatsappLinks ?? this.whatsappLinks,
    telegramLinks: telegramLinks ?? this.telegramLinks,
    topCountries: topCountries ?? this.topCountries,
    recentEntries: recentEntries ?? this.recentEntries,
    isLoading: isLoading ?? this.isLoading,
    error: clearError ? null : (error ?? this.error),
  );

  @override
  bool operator ==(Object other) =>
      other is DashboardState &&
      other.totalLinks == totalLinks &&
      other.whatsappLinks == whatsappLinks &&
      other.telegramLinks == telegramLinks &&
      other.isLoading == isLoading &&
      other.error == error &&
      _sameTopCountries(other.topCountries, topCountries) &&
      _sameEntries(other.recentEntries, recentEntries);

  /// Element-wise comparisons: a list change (a clear, a new link) must
  /// rebuild even when the scalars stay equal.
  static bool _sameTopCountries(
    List<MapEntry<String, int>> a,
    List<MapEntry<String, int>> b,
  ) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].key != b[i].key || a[i].value != b[i].value) return false;
    }
    return true;
  }

  static bool _sameEntries(List<PhoneEntry> a, List<PhoneEntry> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode =>
      Object.hash(totalLinks, whatsappLinks, telegramLinks, isLoading, error);

  @override
  String toString() =>
      'DashboardState($totalLinks links, recent: ${recentEntries.length})';
}

/// Watches the signed-in account's counters and history, one stream each —
/// the store re-reads after every write, so this never polls. Each stream
/// feeds its part of the state as it arrives.
class DashboardController extends Notifier<DashboardState> {
  /// The pre-refactor cap on the recent list.
  static const int maxRecentEntries = 10;

  static const int _maxTopCountries = 5;

  StreamSubscription<UserStats>? _statsSub;
  StreamSubscription<List<PhoneEntry>>? _historySub;
  bool _statsArrived = false;
  bool _historyArrived = false;

  @override
  DashboardState build() {
    _statsSub?.cancel();
    _historySub?.cancel();
    _statsArrived = false;
    _historyArrived = false;
    final session = ref.watch(sessionControllerProvider);
    if (session == null) return const DashboardState();
    final store = ref.read(entriesStoreProvider);
    _statsSub = store
        .watchStats(session.userId)
        .listen(
          (stats) => state = _withStats(stats),
          onError: (Object error) => state = state.copyWith(error: error),
        );
    _historySub = store
        .watchHistory(session.userId)
        .listen(
          (entries) => state = _withHistory(entries),
          onError: (Object error) => state = state.copyWith(error: error),
        );
    ref.onDispose(() {
      _statsSub?.cancel();
      _historySub?.cancel();
    });
    return const DashboardState(isLoading: true);
  }

  DashboardState _withStats(UserStats stats) {
    _statsArrived = true;
    return state.copyWith(
      totalLinks: stats.totalGeneratedLinks,
      whatsappLinks: stats.whatsappLinks,
      telegramLinks: stats.telegramLinks,
      topCountries: stats.getTopCountries(_maxTopCountries),
      isLoading: !(_statsArrived && _historyArrived),
    );
  }

  DashboardState _withHistory(List<PhoneEntry> entries) {
    _historyArrived = true;
    return state.copyWith(
      recentEntries: entries.take(maxRecentEntries).toList(),
      isLoading: !(_statsArrived && _historyArrived),
    );
  }
}

final dashboardControllerProvider =
    NotifierProvider<DashboardController, DashboardState>(
      DashboardController.new,
    );
