import 'package:material_ui/material_ui.dart';

/// The brand colour, carried over from the pre-refactor `AppTheme`.
/// Every other colour is derived from it; change it here, nowhere else.
const Color brandPrimary = Color(0xFF4CAF50);

/// Platform brand colours for the two link targets. Brightness-independent:
/// they must always match the real WhatsApp and Telegram brands.
const Color brandWhatsapp = Color(0xFF25D366);
const Color brandTelegram = Color(0xFF0088CC);

/// Every colour the UI uses, light and dark. Read it with `context.appColors`.
/// Widgets never write a colour literal.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.primary,
    required this.onPrimary,
    required this.page,
    required this.card,
    required this.text,
    required this.textMuted,
    required this.line,
    required this.danger,
    required this.onDanger,
    required this.success,
    required this.accent,
    required this.whatsapp,
    required this.telegram,
  });

  factory AppColors.light([Color primary = brandPrimary]) {
    final scheme = ColorScheme.fromSeed(seedColor: primary);
    return AppColors(
      primary: primary,
      onPrimary: scheme.onPrimary,
      page: const Color(0xFFF7F7F9),
      card: const Color(0xFFFFFFFF),
      text: const Color(0xFF16181D),
      textMuted: const Color(0xFF626773),
      line: const Color(0xFFE2E4EA),
      danger: const Color(0xFFC62828),
      onDanger: const Color(0xFFFFFFFF),
      success: const Color(0xFF2E7D32),
      accent: const Color(0xFFFF9800),
      whatsapp: brandWhatsapp,
      telegram: brandTelegram,
    );
  }

  factory AppColors.dark([Color primary = brandPrimary]) {
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
    );
    return AppColors(
      // The dark scheme's primary is the seed re-toned to read on a dark page.
      primary: scheme.primary,
      onPrimary: scheme.onPrimary,
      page: const Color(0xFF101114),
      card: const Color(0xFF1A1C21),
      text: const Color(0xFFECEDF1),
      textMuted: const Color(0xFF9A9FAB),
      line: const Color(0xFF2B2E36),
      danger: const Color(0xFFEF9A9A),
      onDanger: const Color(0xFF2A0F0D),
      success: const Color(0xFF81C784),
      accent: const Color(0xFFFFB74D),
      whatsapp: brandWhatsapp,
      telegram: brandTelegram,
    );
  }

  final Color primary;
  final Color onPrimary;

  /// The ground behind every screen.
  final Color page;

  /// Surfaces that sit on the page: cards, fields, sheets.
  final Color card;
  final Color text;
  final Color textMuted;
  final Color line;
  final Color danger;
  final Color onDanger;
  final Color success;

  /// Highlights (badges, chart accents) that are not primary.
  final Color accent;

  /// The WhatsApp brand colour (link buttons, platform badges).
  final Color whatsapp;

  /// The Telegram brand colour (link buttons, platform badges).
  final Color telegram;

  @override
  AppColors copyWith({
    Color? primary,
    Color? onPrimary,
    Color? page,
    Color? card,
    Color? text,
    Color? textMuted,
    Color? line,
    Color? danger,
    Color? onDanger,
    Color? success,
    Color? accent,
    Color? whatsapp,
    Color? telegram,
  }) => AppColors(
    primary: primary ?? this.primary,
    onPrimary: onPrimary ?? this.onPrimary,
    page: page ?? this.page,
    card: card ?? this.card,
    text: text ?? this.text,
    textMuted: textMuted ?? this.textMuted,
    line: line ?? this.line,
    danger: danger ?? this.danger,
    onDanger: onDanger ?? this.onDanger,
    success: success ?? this.success,
    accent: accent ?? this.accent,
    whatsapp: whatsapp ?? this.whatsapp,
    telegram: telegram ?? this.telegram,
  );

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      page: Color.lerp(page, other.page, t)!,
      card: Color.lerp(card, other.card, t)!,
      text: Color.lerp(text, other.text, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      line: Color.lerp(line, other.line, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      onDanger: Color.lerp(onDanger, other.onDanger, t)!,
      success: Color.lerp(success, other.success, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      whatsapp: Color.lerp(whatsapp, other.whatsapp, t)!,
      telegram: Color.lerp(telegram, other.telegram, t)!,
    );
  }
}
