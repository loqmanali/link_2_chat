import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:link_2_chat/core/api/failure.dart';
import 'package:link_2_chat/core/session/session_providers.dart';
import 'package:link_2_chat/core/settings/app_preferences.dart';
import 'package:link_2_chat/features/entries/entries.dart';
import 'package:link_2_chat/features/home/domain/guest_limit_failure.dart';
import 'package:link_2_chat/features/home/domain/phone_draft.dart';
import 'package:uuid/uuid.dart';

/// What the home screen shows. The pre-refactor `HomeBloc` state with the
/// loading flag and the error message removed: loading lives on the action
/// (`generateLinkActionProvider`), failures arrive through the screen's
/// `ref.listen`, not through the state.
class HomeState {
  const HomeState({
    this.phone = '',
    this.countryCode = '',
    this.countryName = '',
    this.isValid = false,
    this.generatedEntry,
    this.isShowingQr = false,
  });

  /// The national number as typed (digits only).
  final String phone;
  final String countryCode;
  final String countryName;

  /// Whether the number passes the length rule.
  final bool isValid;

  /// The last link generated in this visit, null before the first one.
  final PhoneEntry? generatedEntry;

  /// Whether the QR code of [generatedEntry] is expanded under the buttons.
  final bool isShowingQr;

  HomeState copyWith({
    String? phone,
    String? countryCode,
    String? countryName,
    bool? isValid,
    PhoneEntry? generatedEntry,
    bool clearGeneratedEntry = false,
    bool? isShowingQr,
  }) => HomeState(
    phone: phone ?? this.phone,
    countryCode: countryCode ?? this.countryCode,
    countryName: countryName ?? this.countryName,
    isValid: isValid ?? this.isValid,
    generatedEntry:
        clearGeneratedEntry ? null : (generatedEntry ?? this.generatedEntry),
    isShowingQr: isShowingQr ?? this.isShowingQr,
  );

  @override
  bool operator ==(Object other) =>
      other is HomeState &&
      other.phone == phone &&
      other.countryCode == countryCode &&
      other.countryName == countryName &&
      other.isValid == isValid &&
      other.generatedEntry == generatedEntry &&
      other.isShowingQr == isShowingQr;

  @override
  int get hashCode => Object.hash(
    phone,
    countryCode,
    countryName,
    isValid,
    generatedEntry,
    isShowingQr,
  );

  @override
  String toString() =>
      'HomeState($countryCode $phone, valid: $isValid, '
      'entry: $generatedEntry, qr: $isShowingQr)';
}

/// The phone input and the generated-link panel. The field writes through
/// [phoneChanged]; the generate action writes through [linkGenerated].
class HomeController extends Notifier<HomeState> {
  @override
  HomeState build() => const HomeState();

  /// The field's value changed (typed, pasted, or country switched).
  void phoneChanged(PhoneDraft draft) =>
      state = state.copyWith(
        phone: draft.phoneNumber,
        countryCode: draft.countryCode,
        countryName: draft.countryName,
        isValid: draft.isValid,
      );

  /// A link was recorded; show its card.
  void linkGenerated(PhoneEntry entry) =>
      state = state.copyWith(generatedEntry: entry, isShowingQr: false);

  /// Expand or collapse the QR code of the generated link.
  void toggleQr() {
    if (state.generatedEntry == null) return;
    state = state.copyWith(isShowingQr: !state.isShowingQr);
  }

  @override
  String toString() => 'HomeController($state)';
}

final homeControllerProvider = NotifierProvider<HomeController, HomeState>(
  HomeController.new,
);

/// Generates one link: validates, enforces the guest budget, records the
/// entry and shows the card. Failures surface through the screen's
/// `ref.listen` — a [GuestLimitFailure] becomes the localized
/// `homeGuestLimit` sentence, a [ValidationFailure] `homeInvalidNumber`,
/// anything else `showFailureToast`.
final generateLinkActionProvider =
    AsyncNotifierProvider<GenerateLinkAction, void>(
      GenerateLinkAction.new,
      retry: (_, _) => null,
    );

class GenerateLinkAction extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> generate(LinkPlatform platform) async {
    state = await AsyncValue.guard(() async {
      final input = ref.read(homeControllerProvider);
      if (!input.isValid) {
        throw const ValidationFailure('The phone number is not valid.');
      }
      final session = ref.read(sessionControllerProvider);
      if (session == null) {
        throw const AuthFailure('No signed-in account.');
      }
      final prefs = ref.read(sharedPreferencesProvider);
      if (session.isGuest) {
        final count = prefs.getInt(GuestLinks.countKey) ?? 0;
        if (count >= GuestLinks.limit) {
          throw const GuestLimitFailure();
        }
      }
      final entry = PhoneEntry(
        id: const Uuid().v4(),
        userId: session.userId,
        phoneNumber: input.phone,
        countryCode: input.countryCode,
        countryName: input.countryName,
        platform: platform,
        createdAt: DateTime.now(),
      );
      await ref.read(entriesStoreProvider).record(entry);
      if (session.isGuest) {
        final count = prefs.getInt(GuestLinks.countKey) ?? 0;
        await prefs.setInt(GuestLinks.countKey, count + 1);
      }
      ref.read(homeControllerProvider.notifier).linkGenerated(entry);
    });
  }
}
