import 'package:link_2_chat/core/design/app_colors.dart';
import 'package:material_ui/material_ui.dart';

/// Reads the design tokens from the ambient [Theme].
extension AppBuildContext on BuildContext {
  /// The colour tokens of the active theme (`AppTheme.light` or `dark`).
  AppColors get appColors => Theme.of(this).extension<AppColors>()!;
}
