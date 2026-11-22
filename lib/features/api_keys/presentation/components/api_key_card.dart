import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:link_2_chat/core/design/app_context.dart';
import 'package:link_2_chat/core/design/app_radii.dart';
import 'package:link_2_chat/core/design/app_spacing.dart';
import 'package:link_2_chat/features/api_keys/application/api_keys_providers.dart';
import 'package:link_2_chat/features/api_keys/domain/api_key.dart';
import 'package:link_2_chat/features/api_keys/presentation/api_permission_text.dart';
import 'package:link_2_chat/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// One API key: name and description, the active switch, the masked key with
/// its copy button, the permission chips, dates, and the delete action.
class ApiKeyCard extends ConsumerWidget {
  const ApiKeyCard({required this.apiKey, super.key});

  final ApiKey apiKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context);
    return Card(
      margin: const EdgeInsetsDirectional.only(bottom: AppSpacing.lg),
      color: colors.card,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        apiKey.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: colors.text,
                        ),
                      ),
                      if (apiKey.description.isNotEmpty)
                        Padding(
                          padding: const EdgeInsetsDirectional.only(
                            top: AppSpacing.xs,
                          ),
                          child: Text(
                            apiKey.description,
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.textMuted,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Switch(
                  value: apiKey.isActive,
                  onChanged:
                      (value) => ref
                          .read(toggleApiKeyActionProvider.notifier)
                          .toggle(id: apiKey.id, isActive: value),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colors.line),
          Padding(
            padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.apiKeyLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: colors.textMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: colors.page,
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                    border: Border.all(color: colors.line),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          apiKey.maskedKey,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 14,
                            color: colors.text,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.copy, size: 18, color: colors.primary),
                        onPressed: () => _copy(context, l10n.apiCopied),
                        tooltip: l10n.apiCopyTooltip,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.commonPermissions,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: colors.textMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final permission in apiKey.permissions)
                      Chip(
                        label: Text(
                          permissionName(l10n, permission),
                          style: TextStyle(fontSize: 12, color: colors.primary),
                        ),
                        backgroundColor: colors.primary.withValues(alpha: 0.08),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.calendar_today,
                  label: l10n.commonCreated,
                  value: _shortDate(apiKey.createdAt),
                ),
                if (apiKey.lastUsedAt != null)
                  _InfoRow(
                    icon: Icons.history,
                    label: l10n.apiLastUsed,
                    value: _shortDate(apiKey.lastUsedAt!),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _confirmDelete(context, ref, l10n),
                  icon: Icon(Icons.delete, color: colors.danger, size: 18),
                  label: Text(
                    l10n.commonDelete,
                    style: TextStyle(color: colors.danger),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _copy(BuildContext context, String confirmation) {
    Clipboard.setData(ClipboardData(text: apiKey.key));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(confirmation)));
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(l10n.apiDeleteKeyTitle),
            content: Text(l10n.apiDeleteKeyMessage(apiKey.name)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.commonCancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(l10n.commonDelete),
              ),
            ],
          ),
    );
    if (confirmed ?? false) {
      await ref.read(deleteApiKeyActionProvider.notifier).delete(apiKey.id);
    }
  }

  String _shortDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}

/// One "label: value" date line of the card.
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 14, color: colors.textMuted),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '$label: ',
            style: TextStyle(fontSize: 12, color: colors.textMuted),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: colors.text,
            ),
          ),
        ],
      ),
    );
  }
}
