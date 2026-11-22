import 'package:url_launcher/url_launcher.dart';

class WhatsAppService {
  /// Generates a WhatsApp chat link from a phone number
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

    return 'https://wa.me/$cleanNumber';
  }

  /// Generates a WhatsApp chat link with a pre-filled message
  ///
  /// [phoneNumber] should include country code without '+' sign
  /// [message] is the text that will be pre-filled in the chat
  static String generateLinkWithMessage(String phoneNumber, String message) {
    final cleanNumber = phoneNumber
        .replaceAll('+', '')
        .replaceAll(' ', '')
        .replaceAll('-', '')
        .replaceAll('(', '')
        .replaceAll(')', '');

    // URL encode the message
    final encodedMessage = Uri.encodeComponent(message);

    return 'https://wa.me/$cleanNumber?text=$encodedMessage';
  }

  /// Opens the WhatsApp chat directly
  ///
  /// Returns true if successful, false otherwise
  static Future<bool> openWhatsAppChat(String phoneNumber) async {
    final url = generateLink(phoneNumber);
    return await _launchUrl(url);
  }

  /// Opens WhatsApp chat with a pre-filled message
  ///
  /// Returns true if successful, false otherwise
  static Future<bool> openWhatsAppChatWithMessage(
    String phoneNumber,
    String message,
  ) async {
    final url = generateLinkWithMessage(phoneNumber, message);
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
