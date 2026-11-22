import 'dart:ui' show Locale;

/// The app languages in the order they are offered on the settings screen.
const List<Locale> supportedLanguages = [Locale('en'), Locale('ar')];

/// A language written in itself — "English", "العربية" — never translated to
/// the current app language (that is what language pickers do).
String languageName(Locale locale) => switch (locale.languageCode) {
  'ar' => 'العربية',
  'en' => 'English',
  _ => locale.languageCode,
};
