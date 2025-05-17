import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';

import '../../core/models/phone_entry.dart';

// Events
abstract class HistoryEvent {}

class LoadHistoryEvent extends HistoryEvent {}

class ClearHistoryEvent extends HistoryEvent {}

// State
class HistoryState {
  final List<PhoneEntry> entries;
  final bool isLoading;
  final String? error;

  HistoryState({required this.entries, this.isLoading = false, this.error});

  HistoryState copyWith({
    List<PhoneEntry>? entries,
    bool? isLoading,
    String? error,
  }) {
    return HistoryState(
      entries: entries ?? this.entries,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  static const String _boxName = 'phone_entries';

  HistoryBloc() : super(HistoryState(entries: [])) {
    on<LoadHistoryEvent>(_loadHistory);
    on<ClearHistoryEvent>(_clearHistory);
  }

  Future<void> _loadHistory(
    LoadHistoryEvent event,
    Emitter<HistoryState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true));

      // Open Hive box
      final box = await Hive.openBox<PhoneEntry>(_boxName);

      // Get entries and sort by timestamp (newest first)
      final entries =
          box.values.toList()
            ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

      emit(state.copyWith(entries: entries, isLoading: false));
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          error: 'Failed to load history: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _clearHistory(
    ClearHistoryEvent event,
    Emitter<HistoryState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true));

      // Open and clear Hive box
      final box = await Hive.openBox<PhoneEntry>(_boxName);
      await box.clear();

      emit(state.copyWith(entries: [], isLoading: false));
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          error: 'Failed to clear history: ${e.toString()}',
        ),
      );
    }
  }
}
