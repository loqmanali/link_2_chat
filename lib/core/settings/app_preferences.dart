import 'dart:ui' show Locale;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart' show ThemeMode;
import 'package:shared_preferences/shared_preferences.dart';

/// Overridden in `bootstrap.dart` with the instance read before the first
/// frame, so the saved language and theme apply without a flash.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) =>
      throw UnimplementedError('sharedPreferencesProvider is not overridden'),
);

/// The chosen language, or null to follow the phone.
class LocaleController extends Notifier<Locale?> {
  static const String key = 'pref.language';

  @override
  Locale? build() {
    final code = ref.read(sharedPreferencesProvider).getString(key);
    return code == null ? null : Locale(code);
  }

  Future<void> choose(Locale? locale) async {
    state = locale;
    final prefs = ref.read(sharedPreferencesProvider);
    if (locale == null) {
      await prefs.remove(key);
    } else {
      await prefs.setString(key, locale.languageCode);
    }
  }
}

final localeControllerProvider = NotifierProvider<LocaleController, Locale?>(
  LocaleController.new,
);

/// Light, dark, or whatever the phone is set to (the default).
class ThemeModeController extends Notifier<ThemeMode> {
  static const String key = 'pref.theme_mode';

  @override
  ThemeMode build() =>
      ThemeMode.values.asNameMap()[ref
          .read(sharedPreferencesProvider)
          .getString(key)] ??
      ThemeMode.system;

  Future<void> choose(ThemeMode mode) async {
    state = mode;
    await ref.read(sharedPreferencesProvider).setString(key, mode.name);
  }
}

final themeModeControllerProvider =
    NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);
