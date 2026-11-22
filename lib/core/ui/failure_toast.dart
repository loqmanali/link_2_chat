import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:link_2_chat/core/ui/failure_message.dart';
import 'package:link_2_chat/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// Shows [failure] as a snack bar in the app language. If a toast kit is
/// copied into the project (`--kits toast`), switch this one function to it.
void showFailureToast(BuildContext context, Object failure) {
  final message = failureMessage(AppLocalizations.of(context), failure);
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// True once [next] is a settled failure. A loading state copies the previous
/// error, so `hasError` alone would re-toast the old failure on a new submit.
bool isFreshFailure(AsyncValue<Object?> next) =>
    next.hasError && !next.isLoading;
