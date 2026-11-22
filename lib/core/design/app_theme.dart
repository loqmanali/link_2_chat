import 'package:link_2_chat/core/design/app_colors.dart';
import 'package:link_2_chat/core/design/app_radii.dart';
import 'package:material_ui/material_ui.dart';

/// Light and dark [ThemeData]. The full token set is carried by the
/// [AppColors] theme extension; the Material [ColorScheme] is only the mapping
/// Material widgets need.
abstract final class AppTheme {
  static ThemeData light() => _build(AppColors.light(), Brightness.light);

  static ThemeData dark() => _build(AppColors.dark(), Brightness.dark);

  static ThemeData _build(AppColors c, Brightness brightness) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: c.primary,
      onPrimary: c.onPrimary,
      secondary: c.primary,
      onSecondary: c.onPrimary,
      error: c.danger,
      onError: c.onDanger,
      surface: c.card,
      onSurface: c.text,
      outline: c.line,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.page,
      extensions: [c],
      appBarTheme: AppBarTheme(
        backgroundColor: c.page,
        foregroundColor: c.text,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: c.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          side: BorderSide(color: c.line),
        ),
      ),
    );
  }
}
