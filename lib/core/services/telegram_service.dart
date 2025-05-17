import 'package:url_launcher/url_launcher.dart';

class TelegramService {
  /// Generates a Telegram chat link from a phone number
  ///
  /// [phoneNumber] should include country code without '+' sign
  static String generateLink(String phoneNumber) {
    // Remove any '+' sign if present and strip any spaces or special characters
    final cleanNumber = phoneNumber
        .replaceAll('+', '')
        .replaceAll(' ', '')
        .replaceAll('-', '')
        .replaceAll('(', '')
        .replaceAll(')', '');

    return 'https://t.me/$cleanNumber';
  }

  /// Opens the Telegram chat directly
  ///
  /// Returns true if successful, false otherwise
  static Future<bool> openTelegramChat(String phoneNumber) async {
    final url = generateLink(phoneNumber);
    return await _launchUrl(url);
  }

  /// Helper method to launch URLs
  static Future<bool> _launchUrl(String urlString) async {
    final url = Uri.parse(urlString);

    if (await canLaunchUrl(url)) {
      return await launchUrl(url, mode: LaunchMode.externalApplication);
    }
    return false;
  }
}
