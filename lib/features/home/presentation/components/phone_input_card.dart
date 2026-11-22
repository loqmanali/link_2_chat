import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:link_2_chat/core/design/app_context.dart';
import 'package:link_2_chat/core/design/app_radii.dart';
import 'package:link_2_chat/core/design/app_spacing.dart';
import 'package:link_2_chat/features/home/application/home_providers.dart';
import 'package:link_2_chat/features/home/domain/phone_draft.dart';
import 'package:link_2_chat/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:phone_form_field/country_selector.dart';
import 'package:phone_form_field/phone_form_field.dart';

/// The labelled phone field with its country selector, paste shortcut and the
/// invalid-number error. Replaces the pre-refactor `intl_phone_field` input;
/// the structured value is written straight into `homeControllerProvider`.
class PhoneInputCard extends ConsumerStatefulWidget {
  const PhoneInputCard({super.key});

  @override
  ConsumerState<PhoneInputCard> createState() => _PhoneInputCardState();
}

class _PhoneInputCardState extends ConsumerState<PhoneInputCard> {
  // A State may own what Flutter makes it own (text controllers, focus); the
  // phone value itself lives in Riverpod.
  final PhoneController _controller = PhoneController(
    initialValue: const PhoneNumber(isoCode: IsoCode.US, nsn: ''),
  );
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(PhoneNumber value) {
    ref
        .read(homeControllerProvider.notifier)
        .phoneChanged(
          PhoneDraft.fromField(value, _countryName(context, value.isoCode)),
        );
  }

  /// Feeds pasted text ('+20 100 123 4567') into the field and the state,
  /// like the pre-refactor paste button did.
  Future<void> _paste() async {
    final data = await Clipboard.getData('text/plain');
    final text = data?.text;
    if (text == null) return;
    final draft = PhoneDraft.fromPastedText(text);
    if (draft == null || !mounted) return;
    _controller.value = PhoneNumber(
      isoCode: draft.isoCode,
      nsn: draft.phoneNumber,
    );
    ref.read(homeControllerProvider.notifier).phoneChanged(draft);
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    final input = ref.watch(homeControllerProvider);
    final showError = input.phone.isNotEmpty && !input.isValid;
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.md),
      borderSide: BorderSide(color: color, width: 1.5),
    );
    return Container(
      padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: colors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.homePhoneLabel,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colors.textMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          PhoneFormField(
            controller: _controller,
            focusNode: _focusNode,
            onChanged: _onChanged,
            keyboardType: TextInputType.phone,
            countrySelectorNavigator:
                const CountrySelectorNavigator.bottomSheet(),
            decoration: InputDecoration(
              hintText: l10n.homePhoneHint,
              errorText: showError ? l10n.homeInvalidNumber : null,
              filled: true,
              fillColor: colors.page,
              enabledBorder: border(colors.line),
              focusedBorder: border(colors.primary),
              errorBorder: border(colors.danger),
              focusedErrorBorder: border(colors.danger),
              suffixIcon: IconButton(
                icon: const Icon(Icons.paste_rounded),
                tooltip: l10n.homePasteTooltip,
                onPressed: _paste,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: _paste,
              icon: const Icon(Icons.content_paste_rounded, size: 20),
              label: Text(l10n.homePasteButton),
            ),
          ),
        ],
      ),
    );
  }
}

/// The country display name in the app language, when the selector's
/// localization is wired in, falling back to the ISO code.
String _countryName(BuildContext context, IsoCode isoCode) =>
    CountrySelectorLocalization.of(context)?.countryName(isoCode) ??
    isoCode.name;
