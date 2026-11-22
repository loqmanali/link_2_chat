/// The two chat platforms the app builds links for.
enum LinkPlatform { whatsapp, telegram }

/// Pure link builders, carried over from the pre-refactor services. No
/// Flutter, no storage: the same numbers always produce the same links.
abstract final class LinkTarget {
  /// Strips everything but digits: `+`, spaces, dashes, parentheses.
  static String sanitize(String phoneNumber) =>
      phoneNumber.replaceAll(RegExp(r'[+\s\-()]'), '');

  static String whatsapp(String phoneNumber) =>
      'https://wa.me/${sanitize(phoneNumber)}';

  static String whatsappWithMessage(String phoneNumber, String message) =>
      'https://wa.me/${sanitize(phoneNumber)}'
      '?text=${Uri.encodeComponent(message)}';

  static String telegram(String phoneNumber) =>
      'https://t.me/${sanitize(phoneNumber)}';

  /// The link for [platform].
  static String forPlatform(String phoneNumber, LinkPlatform platform) =>
      platform == LinkPlatform.whatsapp
          ? whatsapp(phoneNumber)
          : telegram(phoneNumber);
}
