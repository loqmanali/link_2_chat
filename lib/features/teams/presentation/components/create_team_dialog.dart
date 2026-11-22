import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:link_2_chat/core/design/app_context.dart';
import 'package:link_2_chat/core/design/app_spacing.dart';
import 'package:link_2_chat/core/design/components/app_button.dart';
import 'package:link_2_chat/core/design/components/app_text_field.dart';
import 'package:link_2_chat/core/ui/failure_message.dart';
import 'package:link_2_chat/core/ui/failure_toast.dart' show isFreshFailure;
import 'package:link_2_chat/features/teams/application/teams_providers.dart';
import 'package:link_2_chat/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// Names a new team. The create action gates on the subscription tier; a
/// failure is shown under the form.
class CreateTeamDialog extends ConsumerStatefulWidget {
  const CreateTeamDialog({super.key});

  @override
  ConsumerState<CreateTeamDialog> createState() => _CreateTeamDialogState();
}

class _CreateTeamDialogState extends ConsumerState<CreateTeamDialog> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  /// The validation or action failure under the name field. A listenable,
  /// because the guard forbids `setState` — widget state goes through
  /// listenables, app state through Riverpod.
  final _error = ValueNotifier<String?>(null);

  @override
  void dispose() {
    _error.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context);
    final action = ref.watch(createTeamActionProvider);
    return AlertDialog(
      title: Text(l10n.teamsCreateDialogTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ValueListenableBuilder<String?>(
              valueListenable: _error,
              builder:
                  (context, error, _) => AppTextField(
                    controller: _nameController,
                    label: l10n.teamsNameLabel,
                    errorText: error,
                  ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              controller: _descriptionController,
              label: l10n.commonDescriptionOptional,
              keyboardType: TextInputType.multiline,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.teamsCreateDialogHint,
              style: TextStyle(fontSize: 12, color: colors.textMuted),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        AppButton(
          label: l10n.commonCreate,
          isLoading: action.isLoading,
          onPressed: _create,
        ),
      ],
    );
  }

  Future<void> _create() async {
    final l10n = AppLocalizations.of(context);
    if (_nameController.text.trim().isEmpty) {
      _error.value = l10n.teamsNameRequired;
      return;
    }
    _error.value = null;
    await ref
        .read(createTeamActionProvider.notifier)
        .create(
          name: _nameController.text,
          description: _descriptionController.text,
        );
    final result = ref.read(createTeamActionProvider);
    if (!mounted) return;
    if (isFreshFailure(result)) {
      _error.value = failureMessage(l10n, result.error!);
      return;
    }
    Navigator.of(context).pop();
  }
}
