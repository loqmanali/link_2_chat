import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:link_2_chat/core/design/app_context.dart';
import 'package:link_2_chat/core/design/app_spacing.dart';
import 'package:link_2_chat/core/design/components/app_button.dart';
import 'package:link_2_chat/core/design/components/app_text_field.dart';
import 'package:link_2_chat/features/api_keys/application/api_keys_providers.dart';
import 'package:link_2_chat/features/api_keys/domain/api_key.dart';
import 'package:link_2_chat/features/api_keys/presentation/api_permission_text.dart';
import 'package:link_2_chat/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// Names a key and picks its permissions. Links and history are pre-ticked,
/// like the pre-refactor dialog; at least one permission must stay picked.
class CreateApiKeyDialog extends ConsumerStatefulWidget {
  const CreateApiKeyDialog({super.key});

  @override
  ConsumerState<CreateApiKeyDialog> createState() => _CreateApiKeyDialogState();
}

class _CreateApiKeyDialogState extends ConsumerState<CreateApiKeyDialog> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  /// The ticked permissions. A listenable, because the guard forbids
  /// `setState` — widget state goes through listenables.
  final _selected = ValueNotifier<Set<ApiPermission>>({
    // The pre-refactor defaults.
    ApiPermission.generateLinks,
    ApiPermission.viewHistory,
  });

  /// The validation error under the name field.
  final _error = ValueNotifier<String?>(null);

  @override
  void dispose() {
    _selected.dispose();
    _error.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _toggle(ApiPermission permission, bool on) {
    final next = {..._selected.value};
    if (on) {
      next.add(permission);
    } else {
      next.remove(permission);
    }
    _selected.value = next;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context);
    final action = ref.watch(createApiKeyActionProvider);
    return AlertDialog(
      title: Text(l10n.apiCreateKey),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ValueListenableBuilder<String?>(
              valueListenable: _error,
              builder:
                  (context, error, _) => AppTextField(
                    controller: _nameController,
                    label: l10n.apiKeyNameLabel,
                    errorText: error,
                  ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              controller: _descriptionController,
              label: l10n.commonDescriptionOptional,
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              l10n.commonPermissions,
              style: TextStyle(fontWeight: FontWeight.bold, color: colors.text),
            ),
            const SizedBox(height: AppSpacing.sm),
            ValueListenableBuilder<Set<ApiPermission>>(
              valueListenable: _selected,
              builder:
                  (context, selected, _) => Column(
                    children: [
                      for (final permission in ApiPermission.values)
                        CheckboxListTile(
                          title: Text(
                            permissionName(l10n, permission),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: colors.text,
                            ),
                          ),
                          subtitle: Text(
                            permissionDescription(l10n, permission),
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.textMuted,
                            ),
                          ),
                          value: selected.contains(permission),
                          onChanged:
                              (value) => _toggle(permission, value ?? false),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                    ],
                  ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.apiKeySecurityNote,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: colors.accent,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.apiKeySecurityWarning,
              style: TextStyle(fontSize: 12, color: colors.textMuted),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
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
      _error.value = l10n.apiKeyNameRequired;
      return;
    }
    final permissions = _selected.value.toList();
    if (permissions.isEmpty) {
      _error.value = l10n.apiKeySelectPermission;
      return;
    }
    _error.value = null;
    final created = await ref
        .read(createApiKeyActionProvider.notifier)
        .create(
          name: _nameController.text,
          description: _descriptionController.text,
          permissions: permissions,
        );
    if (!mounted) return;
    if (created == null) return; // the screen toasts the failure
    Navigator.pop(context, created);
  }
}
