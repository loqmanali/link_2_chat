import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl_phone_field/countries.dart';
import 'package:intl_phone_field/phone_number.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/models/phone_entry.dart';
import '../../core/services/analytics_service.dart';
import '../../core/services/telegram_service.dart';
import '../../core/services/whatsapp_service.dart';
import '../../core/utils/phone_utils.dart';

// Events
abstract class HomeEvent {}

class PhoneNumberChangedEvent extends HomeEvent {
  final PhoneNumber phoneNumber;

  PhoneNumberChangedEvent(this.phoneNumber);
}

class GenerateWhatsAppLinkEvent extends HomeEvent {}

class GenerateTelegramLinkEvent extends HomeEvent {}

class ShowQrCodeEvent extends HomeEvent {
  final String platform;

  ShowQrCodeEvent(this.platform);
}

class ResetEvent extends HomeEvent {}

class CleanupEvent extends HomeEvent {}

// States
class HomeState {
  final String phoneNumber;
  final String countryCode;
  final String countryName;
  final bool isValidNumber;
  final String? generatedLink;
  final String? currentPlatform;
  final bool isShowingQr;
  final bool isLoading;
  final String? errorMessage;

  HomeState({
    this.phoneNumber = '',
    this.countryCode = '',
    this.countryName = '',
    this.isValidNumber = false,
    this.generatedLink,
    this.currentPlatform,
    this.isShowingQr = false,
    this.isLoading = false,
    this.errorMessage,
  });

  HomeState copyWith({
    String? phoneNumber,
    String? countryCode,
    String? countryName,
    bool? isValidNumber,
    String? generatedLink,
    String? currentPlatform,
    bool? isShowingQr,
    bool? isLoading,
    String? errorMessage,
  }) {
    return HomeState(
      phoneNumber: phoneNumber ?? this.phoneNumber,
      countryCode: countryCode ?? this.countryCode,
      countryName: countryName ?? this.countryName,
      isValidNumber: isValidNumber ?? this.isValidNumber,
      generatedLink: generatedLink ?? this.generatedLink,
      currentPlatform: currentPlatform ?? this.currentPlatform,
      isShowingQr: isShowingQr ?? this.isShowingQr,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  String get fullPhoneNumber => '$countryCode$phoneNumber';
}

// BLoC
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final qrKey = GlobalKey();
  final phoneController = TextEditingController();
  bool _isControllerDisposed = false;

  HomeBloc() : super(HomeState()) {
    on<PhoneNumberChangedEvent>(_onPhoneNumberChanged);
    on<GenerateWhatsAppLinkEvent>(_onGenerateWhatsAppLink);
    on<GenerateTelegramLinkEvent>(_onGenerateTelegramLink);
    on<ShowQrCodeEvent>(_onShowQrCode);
    on<ResetEvent>(_onReset);
    on<CleanupEvent>(_onCleanup);
  }

  void _onPhoneNumberChanged(
    PhoneNumberChangedEvent event,
    Emitter<HomeState> emit,
  ) {
    final phoneNumber = event.phoneNumber.number;
    final countryCode = '+${event.phoneNumber.countryCode}';

    // Get country name from the country code
    final country = countries.firstWhere(
      (c) => c.dialCode == event.phoneNumber.countryCode,
      orElse: () => countries.first,
    );
    final countryName = country.name;

    final isValidNumber = PhoneUtils.isValidPhoneNumber(phoneNumber);

    emit(
      state.copyWith(
        phoneNumber: phoneNumber,
        countryCode: countryCode,
        countryName: countryName,
        isValidNumber: isValidNumber,
        errorMessage:
            isValidNumber ? null : 'Please enter a valid phone number',
      ),
    );
  }

  Future<void> _onGenerateWhatsAppLink(
    GenerateWhatsAppLinkEvent event,
    Emitter<HomeState> emit,
  ) async {
    if (!state.isValidNumber) {
      emit(state.copyWith(errorMessage: 'Please enter a valid phone number'));
      return;
    }

    // Check if guest user has exceeded limit
    if (await _checkGuestLinkLimit(emit)) {
      return;
    }

    emit(state.copyWith(isLoading: true));

    try {
      final link = WhatsAppService.generateLink(state.fullPhoneNumber);

      // Save to analytics
      final entry = PhoneEntry(
        phoneNumber: state.phoneNumber,
        countryCode: state.countryCode,
        countryName: state.countryName,
        timestamp: DateTime.now(),
        platform: 'whatsapp',
      );

      await AnalyticsService.savePhoneEntry(entry);

      // Increment link count for guest users
      await _incrementGuestLinkCount();

      emit(
        state.copyWith(
          generatedLink: link,
          currentPlatform: 'whatsapp',
          isLoading: false,
          isShowingQr: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          errorMessage: 'Error generating link: $e',
          isLoading: false,
        ),
      );
    }
  }

  Future<void> _onGenerateTelegramLink(
    GenerateTelegramLinkEvent event,
    Emitter<HomeState> emit,
  ) async {
    if (!state.isValidNumber) {
      emit(state.copyWith(errorMessage: 'Please enter a valid phone number'));
      return;
    }

    // Check if guest user has exceeded limit
    if (await _checkGuestLinkLimit(emit)) {
      return;
    }

    emit(state.copyWith(isLoading: true));

    try {
      final link = TelegramService.generateLink(state.fullPhoneNumber);

      // Save to analytics
      final entry = PhoneEntry(
        phoneNumber: state.phoneNumber,
        countryCode: state.countryCode,
        countryName: state.countryName,
        timestamp: DateTime.now(),
        platform: 'telegram',
      );

      await AnalyticsService.savePhoneEntry(entry);

      // Increment link count for guest users
      await _incrementGuestLinkCount();

      emit(
        state.copyWith(
          generatedLink: link,
          currentPlatform: 'telegram',
          isLoading: false,
          isShowingQr: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          errorMessage: 'Error generating link: $e',
          isLoading: false,
        ),
      );
    }
  }

  void _onShowQrCode(ShowQrCodeEvent event, Emitter<HomeState> emit) {
    if (!state.isValidNumber || state.generatedLink == null) {
      return;
    }

    emit(state.copyWith(isShowingQr: true, currentPlatform: event.platform));
  }

  void _onReset(ResetEvent event, Emitter<HomeState> emit) {
    phoneController.clear();
    emit(HomeState());
  }

  void _onCleanup(CleanupEvent event, Emitter<HomeState> emit) {
    // This will be called from the widget's useEffect cleanup
    // We'll let the close() method handle the actual disposal
  }

  @override
  Future<void> close() {
    if (!_isControllerDisposed) {
      _isControllerDisposed = true;
      phoneController.dispose();
    }
    return super.close();
  }

  // Check if guest user has exceeded link generation limit
  Future<bool> _checkGuestLinkLimit(Emitter<HomeState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    final isGuestUser = prefs.getBool('is_guest_user') ?? false;

    if (isGuestUser) {
      final linkCount = prefs.getInt('guest_link_count') ?? 0;
      if (linkCount >= 2) {
        emit(
          state.copyWith(
            errorMessage:
                'Guest users can only generate 2 links. Please register or login to continue.',
            isLoading: false,
          ),
        );
        return true;
      }
    }
    return false;
  }

  // Increment link count for guest users
  Future<void> _incrementGuestLinkCount() async {
    final prefs = await SharedPreferences.getInstance();
    final isGuestUser = prefs.getBool('is_guest_user') ?? false;

    if (isGuestUser) {
      final linkCount = prefs.getInt('guest_link_count') ?? 0;
      await prefs.setInt('guest_link_count', linkCount + 1);
    }
  }
}
