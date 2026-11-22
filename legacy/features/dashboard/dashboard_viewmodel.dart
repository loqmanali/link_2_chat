import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/models/phone_entry.dart';
import '../../core/services/analytics_service.dart';

// Events
abstract class DashboardEvent {}

class LoadDashboardDataEvent extends DashboardEvent {}

class RefreshDashboardDataEvent extends DashboardEvent {}

// States
class DashboardState {
  final int totalLinks;
  final int whatsAppLinks;
  final int telegramLinks;
  final List<MapEntry<String, int>> topCountries;
  final List<PhoneEntry> recentEntries;
  final bool isLoading;
  final String? errorMessage;

  DashboardState({
    this.totalLinks = 0,
    this.whatsAppLinks = 0,
    this.telegramLinks = 0,
    this.topCountries = const [],
    this.recentEntries = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  DashboardState copyWith({
    int? totalLinks,
    int? whatsAppLinks,
    int? telegramLinks,
    List<MapEntry<String, int>>? topCountries,
    List<PhoneEntry>? recentEntries,
    bool? isLoading,
    String? errorMessage,
  }) {
    return DashboardState(
      totalLinks: totalLinks ?? this.totalLinks,
      whatsAppLinks: whatsAppLinks ?? this.whatsAppLinks,
      telegramLinks: telegramLinks ?? this.telegramLinks,
      topCountries: topCountries ?? this.topCountries,
      recentEntries: recentEntries ?? this.recentEntries,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

// BLoC
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc() : super(DashboardState()) {
    on<LoadDashboardDataEvent>(_onLoadDashboardData);
    on<RefreshDashboardDataEvent>(_onRefreshDashboardData);
  }

  Future<void> _onLoadDashboardData(
    LoadDashboardDataEvent event,
    Emitter<DashboardState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    await _loadData(emit);
  }

  Future<void> _onRefreshDashboardData(
    RefreshDashboardDataEvent event,
    Emitter<DashboardState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    await _loadData(emit);
  }

  Future<void> _loadData(Emitter<DashboardState> emit) async {
    try {
      // Initialize analytics service
      await AnalyticsService.init();

      // Get user stats
      final stats = await AnalyticsService.getStats();

      // Get recent entries
      final recentEntries = await AnalyticsService.getRecentEntries(limit: 10);

      // Get top countries
      final topCountries = await AnalyticsService.getTopCountries(limit: 5);

      emit(
        state.copyWith(
          totalLinks: stats.totalGeneratedLinks,
          whatsAppLinks: stats.whatsappLinks,
          telegramLinks: stats.telegramLinks,
          topCountries: topCountries,
          recentEntries: recentEntries,
          isLoading: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          errorMessage: 'Error loading dashboard data: $e',
          isLoading: false,
        ),
      );
    }
  }
}
