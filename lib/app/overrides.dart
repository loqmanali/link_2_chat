import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:link_2_chat/core/environment/app_environment.dart';
import 'package:link_2_chat/core/session/session.dart';
import 'package:link_2_chat/core/session/session_providers.dart';
import 'package:link_2_chat/core/settings/app_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The throw-by-default providers, given their real values. `bootstrap.dart`
/// and the tests both build their `ProviderScope` from this list, so a new
/// throw-by-default provider is wired in one place.
List<Override> appOverrides({
  required AppEnvironment environment,
  required SharedPreferences preferences,
  required AppSession? session,
}) => [
  appEnvironmentProvider.overrideWithValue(environment),
  sharedPreferencesProvider.overrideWithValue(preferences),
  initialSessionProvider.overrideWithValue(session),
];
