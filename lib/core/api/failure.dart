/// What a data-layer call can fail with. Thrown by the data layer, switched
/// on (exhaustively) by `failureMessage`; screens never poke at the details.
sealed class Failure implements Exception {
  const Failure(this.message);

  /// A fallback sentence. Not translated; screens use their own strings and
  /// fall back to this only for an error they do not know.
  final String message;
}

/// The credentials were rejected or the action is not allowed for this
/// account (wrong password, duplicate email, ...).
final class AuthFailure extends Failure {
  const AuthFailure(super.message);

  @override
  String toString() => 'AuthFailure($message)';
}

/// A local read or write failed (the device disk, the sqlite file).
final class StorageFailure extends Failure {
  const StorageFailure([super.message = 'Local storage failed.']);

  @override
  String toString() => 'StorageFailure($message)';
}

/// The user's input did not satisfy a rule the data layer enforces
/// (malformed email, too-short password, invalid phone number).
final class ValidationFailure extends Failure {
  const ValidationFailure(super.message);

  @override
  String toString() => 'ValidationFailure($message)';
}
