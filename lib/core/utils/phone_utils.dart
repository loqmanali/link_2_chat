import 'package:intl_phone_field/countries.dart';

class PhoneUtils {
  /// Formats a phone number with spaces for better readability
  ///
  /// [phoneNumber] is the raw phone number without formatting
  static String formatPhoneNumber(String phoneNumber) {
    // Remove any non-digit characters
    String digitsOnly = phoneNumber.replaceAll(RegExp(r'\D'), '');

    // Basic formatting: add a space every 3 digits
    StringBuffer buffer = StringBuffer();
    for (int i = 0; i < digitsOnly.length; i++) {
      if (i > 0 && i % 3 == 0) {
        buffer.write(' ');
      }
      buffer.write(digitsOnly[i]);
    }

    return buffer.toString();
  }

  /// Validates if a phone number is in a potentially valid format
  ///
  /// [phoneNumber] is the phone number to validate
  /// This is a basic check that ensures the number has a reasonable length
  static bool isValidPhoneNumber(String phoneNumber) {
    // Remove any non-digit characters
    String digitsOnly = phoneNumber.replaceAll(RegExp(r'\D'), '');

    // Most phone numbers around the world are between 8 and 15 digits
    return digitsOnly.length >= 8 && digitsOnly.length <= 15;
  }

  /// Gets a country by its dialing code
  ///
  /// [dialingCode] is the country code (e.g., '+1', '+44')
  /// Returns the country if found, null otherwise
  static Country? getCountryByDialCode(String dialingCode) {
    // Remove '+' if present
    String code = dialingCode.replaceAll('+', '');

    try {
      // Search through the countries list to find a matching dialing code
      return countries.firstWhere((country) => country.dialCode == code);
    } catch (e) {
      return null;
    }
  }

  /// Gets a country name by its dialing code
  ///
  /// [dialingCode] is the country code (e.g., '+1', '+44')
  /// Returns the country name if found, 'Unknown' otherwise
  static String getCountryNameByDialCode(String dialingCode) {
    Country? country = getCountryByDialCode(dialingCode);
    return country?.name ?? 'Unknown';
  }

  /// Extracts the likely country code from a phone number
  ///
  /// [phoneNumber] is the full phone number with country code
  /// This is a best-effort method and may not be accurate for all numbers
  static String extractCountryCode(String phoneNumber) {
    // Remove any non-digit characters
    String digitsOnly = phoneNumber.replaceAll(RegExp(r'\D'), '');

    // Try common country codes (most are 1-3 digits)
    for (var country in countries) {
      if (digitsOnly.startsWith(country.dialCode)) {
        return '+${country.dialCode}';
      }
    }

    // Default return if no match is found
    return '';
  }

  /// Splits a phone number into country code and national number
  ///
  /// [phoneNumber] is the full phone number
  /// Returns a map with 'countryCode' and 'nationalNumber' keys
  static Map<String, String> splitPhoneNumber(String phoneNumber) {
    String countryCode = extractCountryCode(phoneNumber);
    String nationalNumber = phoneNumber;

    // Remove country code from national number if found
    if (countryCode.isNotEmpty) {
      nationalNumber = phoneNumber.substring(
        phoneNumber.indexOf(countryCode.replaceAll('+', '')) +
            countryCode.length -
            1,
      );
    }

    return {'countryCode': countryCode, 'nationalNumber': nationalNumber};
  }
}
