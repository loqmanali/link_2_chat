import 'package:link_2_chat/core/design/app_context.dart';
import 'package:link_2_chat/core/design/app_spacing.dart';
import 'package:material_ui/material_ui.dart';

/// One widget for the three non-content states of a screen: loading, empty and
/// error. Pick the named constructor; the layout is shared.
class AppStateView extends StatelessWidget {
  const AppStateView.loading({super.key})
    : message = null,
      retryLabel = null,
      onRetry = null,
      _isError = false;

  const AppStateView.empty({required String this.message, super.key})
    : retryLabel = null,
      onRetry = null,
      _isError = false;

  const AppStateView.error({
    required String this.message,
    required String this.retryLabel,
    required VoidCallback this.onRetry,
    super.key,
  }) : _isError = true;

  final String? message;
  final String? retryLabel;
  final VoidCallback? onRetry;
  final bool _isError;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final text = message;
    return Center(
      child: Padding(
        padding: const EdgeInsetsDirectional.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (text == null)
              const CircularProgressIndicator()
            else ...[
              Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _isError ? colors.danger : colors.textMuted,
                ),
              ),
              if (_isError) ...[
                const SizedBox(height: AppSpacing.lg),
                OutlinedButton(onPressed: onRetry, child: Text(retryLabel!)),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
