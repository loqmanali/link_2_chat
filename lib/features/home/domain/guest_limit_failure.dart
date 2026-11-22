/// The guest link budget, carried over from the pre-refactor home viewmodel:
/// a guest may generate two links per guest session, counted in
/// `guest_link_count` (reset when guest mode is entered, see the auth guest
/// action).
abstract final class GuestLinks {
  /// The `SharedPreferences` counter key.
  static const String countKey = 'guest_link_count';

  /// How many links a guest may generate before they must register.
  static const int limit = 2;
}

/// The guest used up [GuestLinks.limit] links. `Failure` in core is sealed so
/// `failureMessage`'s switch stays exhaustive, so this is a plain exception
/// with no message: the screen that catches it shows its own localized
/// `homeGuestLimit` sentence; anything else goes through `showFailureToast`.
final class GuestLimitFailure implements Exception {
  const GuestLimitFailure();

  @override
  String toString() => 'GuestLimitFailure()';
}
