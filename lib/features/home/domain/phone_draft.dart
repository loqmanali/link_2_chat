import 'package:phone_form_field/phone_form_field.dart';

/// The phone input, extracted from the `phone_form_field` value. What the
/// rest of the feature needs: what to store, what to show, whether the
/// generate buttons may be enabled.
class PhoneDraft {
  const PhoneDraft({
    required this.isoCode,
    required this.phoneNumber,
    required this.countryCode,
    required this.countryName,
    required this.isValid,
  });

  /// The country's alpha-2 code (needed to feed a parsed draft back into the
  /// field's [PhoneController]).
  final IsoCode isoCode;

  /// The national number, digits only, as typed.
  final String phoneNumber;

  /// The dial code with a leading + ('+20').
  final String countryCode;

  /// Display name of the country the dial code belongs to.
  final String countryName;

  /// Whether the number passes the length rule.
  final bool isValid;

  /// Reads the field's structured value. [countryName] is the display name of
  /// the country when the selector's localization has it; callers without
  /// that localization fall back to the ISO code via [fromParsed].
  factory PhoneDraft.fromField(PhoneNumber value, String? countryName) =>
      PhoneDraft.fromParsed(value, countryName: countryName);

  /// The same, with an explicit fallback name.
  factory PhoneDraft.fromParsed(PhoneNumber value, {String? countryName}) {
    final digits = onlyDigits(value.nsn);
    return PhoneDraft(
      isoCode: value.isoCode,
      phoneNumber: digits,
      countryCode: '+${value.countryCode}',
      countryName:
          (countryName == null || countryName.isEmpty)
              ? value.isoCode.name
              : countryName,
      isValid: isValidNumber(digits),
    );
  }

  /// Parses pasted text ('+20 100 123 4567'); null when nothing usable is
  /// found. This replaces the pre-refactor manual dial-code scan: the parser
  /// guesses the country from the leading digits.
  static PhoneDraft? fromPastedText(String text) {
    final cleaned = text.trim();
    if (cleaned.isEmpty) return null;
    final PhoneNumber parsed;
    try {
      parsed = PhoneNumber.parse(cleaned);
    } on Object {
      return null;
    }
    final draft = PhoneDraft.fromParsed(parsed);
    return draft.phoneNumber.isEmpty ? null : draft;
  }

  /// Most numbers are 8-15 digits (the pre-refactor `PhoneUtils` rule).
  static bool isValidNumber(String digits) {
    final d = onlyDigits(digits);
    return d.length >= 8 && d.length <= 15;
  }

  static String onlyDigits(String text) =>
      text.replaceAll(RegExp(r'[^0-9]'), '');

  @override
  bool operator ==(Object other) =>
      other is PhoneDraft &&
      other.isoCode == isoCode &&
      other.phoneNumber == phoneNumber &&
      other.countryCode == countryCode &&
      other.countryName == countryName &&
      other.isValid == isValid;

  @override
  int get hashCode =>
      Object.hash(isoCode, phoneNumber, countryCode, countryName, isValid);

  @override
  String toString() => 'PhoneDraft($countryCode $phoneNumber)';
}
