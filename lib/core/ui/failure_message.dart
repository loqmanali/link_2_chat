import 'package:link_2_chat/core/api/failure.dart';
import 'package:link_2_chat/l10n/app_localizations.dart';

/// The sentence for [error] in the app language. The switch over [Failure] is
/// exhaustive: a new failure type is a compile error here until it has a
/// sentence.
String failureMessage(AppLocalizations l10n, Object error) {
  if (error is! Failure) return l10n.errorGeneric;
  return switch (error) {
    AuthFailure(:final message) when message.isNotEmpty => message,
    AuthFailure() => l10n.errorAuth,
    StorageFailure() => l10n.errorStorage,
    ValidationFailure(:final message) when message.isNotEmpty => message,
    ValidationFailure() => l10n.errorGeneric,
  };
}
