import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/models/user.dart';
import '../../core/services/auth_service.dart';

// Events
abstract class SubscriptionEvent {}

class LoadUserSubscriptionEvent extends SubscriptionEvent {}

class UpdateSubscriptionEvent extends SubscriptionEvent {
  final SubscriptionTier tier;
  final DateTime? expiryDate;

  UpdateSubscriptionEvent(this.tier, this.expiryDate);
}

// States
class SubscriptionState {
  final SubscriptionTier? currentTier;
  final DateTime? expiryDate;
  final bool isLoading;
  final String? error;

  SubscriptionState({
    this.currentTier,
    this.expiryDate,
    this.isLoading = false,
    this.error,
  });

  SubscriptionState copyWith({
    SubscriptionTier? currentTier,
    DateTime? expiryDate,
    bool? isLoading,
    String? error,
  }) {
    return SubscriptionState(
      currentTier: currentTier ?? this.currentTier,
      expiryDate: expiryDate ?? this.expiryDate,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  bool get hasActiveSubscription {
    if (currentTier == SubscriptionTier.free) return true;
    if (expiryDate == null) return false;
    return expiryDate!.isAfter(DateTime.now());
  }
}

// BLoC
class SubscriptionBloc extends Bloc<SubscriptionEvent, SubscriptionState> {
  final AuthService _authService = AuthService();

  SubscriptionBloc() : super(SubscriptionState()) {
    on<LoadUserSubscriptionEvent>(_loadUserSubscription);
    on<UpdateSubscriptionEvent>(_updateSubscription);
  }

  Future<void> _loadUserSubscription(
    LoadUserSubscriptionEvent event,
    Emitter<SubscriptionState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true, error: null));

      final user = await _authService.getCurrentUser();

      if (user == null) {
        emit(state.copyWith(isLoading: false, error: 'User not authenticated'));
        return;
      }

      emit(
        state.copyWith(
          currentTier: user.subscriptionTier,
          expiryDate: user.subscriptionExpiry,
          isLoading: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          error: 'Failed to load subscription: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _updateSubscription(
    UpdateSubscriptionEvent event,
    Emitter<SubscriptionState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true, error: null));

      final user = await _authService.getCurrentUser();

      if (user == null) {
        emit(state.copyWith(isLoading: false, error: 'User not authenticated'));
        return;
      }

      final updatedUser = user.copyWith(
        subscriptionTier: event.tier,
        subscriptionExpiry: event.expiryDate,
      );

      final result = await _authService.updateUser(updatedUser);

      if (result == null) {
        emit(
          state.copyWith(
            isLoading: false,
            error: 'Failed to update subscription',
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          currentTier: result.subscriptionTier,
          expiryDate: result.subscriptionExpiry,
          isLoading: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          error: 'Failed to update subscription: ${e.toString()}',
        ),
      );
    }
  }
}
