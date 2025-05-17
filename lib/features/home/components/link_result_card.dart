import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_theme.dart';
import '../../../core/config/constants.dart';

class LinkResultCard extends HookWidget {
  final String link;
  final String platform;
  final VoidCallback onQrPressed;

  const LinkResultCard({
    super.key,
    required this.link,
    required this.platform,
    required this.onQrPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isPlatformWhatsApp = platform == 'whatsapp';
    final platformColor =
        isPlatformWhatsApp ? AppTheme.whatsappColor : AppTheme.telegramColor;
    final platformName = AppConstants.platforms[platform] ?? platform;

    // Animation for card appearance
    final animationController = useAnimationController(
      duration: const Duration(milliseconds: 600),
    );

    useEffect(() {
      animationController.forward();
      return null;
    }, []);

    // Fix phone number format in the link
    final phoneNumber = _extractPhoneNumber(link);

    return AnimatedBuilder(
      animation: animationController,
      builder: (context, child) {
        final slideAnimation = Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: animationController,
            curve: Curves.easeOutCubic,
          ),
        );

        final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: animationController, curve: Curves.easeOut),
        );

        return FadeTransition(
          opacity: fadeAnimation,
          child: SlideTransition(position: slideAnimation, child: child),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: platformColor.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: platformColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isPlatformWhatsApp
                        ? Icons.message_rounded
                        : Icons.send_rounded,
                    color: platformColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Your $platformName Link',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      phoneNumber,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 20),
                    onPressed: () => _copyLink(context),
                    tooltip: 'Copy link',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    color: platformColor,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      link,
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildActionButton(
                    icon: Icons.qr_code_rounded,
                    label: 'QR Code',
                    onPressed: onQrPressed,
                    color: Colors.grey[700]!,
                  ),
                  const SizedBox(width: 12),
                  _buildActionButton(
                    icon: Icons.share_rounded,
                    label: 'Share',
                    onPressed: _shareLink,
                    color: Colors.grey[700]!,
                  ),
                  const SizedBox(width: 12),
                  _buildActionButton(
                    icon: Icons.open_in_new_rounded,
                    label: 'Open',
                    onPressed: _openLink,
                    color: platformColor,
                    isPrimary: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
    bool isPrimary = false,
  }) {
    return TextButton.icon(
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: color,
        backgroundColor: isPrimary ? color.withOpacity(0.1) : null,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // Extract and format phone number from link
  String _extractPhoneNumber(String link) {
    // Extract the phone number from WhatsApp or Telegram link
    String phoneNumber = '';

    if (platform == 'whatsapp') {
      // Format: https://wa.me/123456789
      final regex = RegExp(r'wa\.me\/(\d+)');
      final match = regex.firstMatch(link);
      if (match != null && match.groupCount >= 1) {
        phoneNumber = match.group(1) ?? '';
      }
    } else if (platform == 'telegram') {
      // Format: https://t.me/123456789
      final regex = RegExp(r't\.me\/(\d+)');
      final match = regex.firstMatch(link);
      if (match != null && match.groupCount >= 1) {
        phoneNumber = match.group(1) ?? '';
      }
    }

    // Format the phone number with proper spacing
    if (phoneNumber.isNotEmpty) {
      return _formatPhoneNumber(phoneNumber);
    }

    return link; // Fallback to the original link
  }

  // Helper method to format phone number with proper spacing
  String _formatPhoneNumber(String fullNumber) {
    // Assume the first 1-3 digits are the country code
    String countryCode;
    String phoneNumber;

    if (fullNumber.length > 10) {
      // For international numbers, assume first 2-3 digits are country code
      countryCode = fullNumber.substring(0, fullNumber.length > 11 ? 3 : 2);
      phoneNumber = fullNumber.substring(countryCode.length);
    } else {
      // For shorter numbers, assume first digit is country code
      countryCode = fullNumber.substring(0, 1);
      phoneNumber = fullNumber.substring(1);
    }

    // Format with proper spacing between groups of digits
    if (phoneNumber.length > 6) {
      // Format: +XX XXX XXX XXXX
      final firstPart = phoneNumber.substring(0, 3);
      final secondPart = phoneNumber.substring(3, 6);
      final thirdPart = phoneNumber.substring(6);

      return '+$countryCode $firstPart $secondPart $thirdPart';
    } else if (phoneNumber.length > 3) {
      // Format: +XX XXX XXXX
      final firstPart = phoneNumber.substring(0, 3);
      final secondPart = phoneNumber.substring(3);

      return '+$countryCode $firstPart $secondPart';
    }

    // Return basic formatted number
    return '+$countryCode $phoneNumber';
  }

  void _copyLink(BuildContext context) {
    Clipboard.setData(ClipboardData(text: link));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppConstants.copySuccessMessage),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _shareLink() async {
    final platformName = AppConstants.platforms[platform] ?? platform;
    await Share.share(link, subject: '$platformName Link');
  }

  void _openLink() async {
    final uri = Uri.parse(link);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
