import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:intl/intl.dart';

import '../../../core/config/app_theme.dart';
import '../../../core/models/phone_entry.dart';

class RecentActivityList extends HookWidget {
  final List<PhoneEntry> entries;

  const RecentActivityList({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    final animationController = useAnimationController(
      duration: const Duration(milliseconds: 800),
    );

    useEffect(() {
      animationController.forward(from: 0);
      return null;
    }, []);

    if (entries.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Activity',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.darkColor,
            ),
          ),
          const SizedBox(height: 16),
          ...entries.asMap().entries.map((mapEntry) {
            final index = mapEntry.key;
            final entry = mapEntry.value;

            // Calculate staggered animation delay
            final delay = index * 0.1;
            final animationInterval = Interval(
              delay.clamp(0.0, 0.9),
              (delay + 0.1).clamp(0.0, 1.0),
            );

            return AnimatedBuilder(
              animation: animationController,
              builder: (context, child) {
                final animValue = animationInterval.transform(
                  animationController.value,
                );
                return Opacity(
                  opacity: animValue,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - animValue)),
                    child: child,
                  ),
                );
              },
              child: _buildActivityItem(entry),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildActivityItem(PhoneEntry entry) {
    final isWhatsApp = entry.platform == 'whatsapp';
    final color = isWhatsApp ? AppTheme.whatsappColor : AppTheme.telegramColor;
    final icon = isWhatsApp ? Icons.message : Icons.send;
    final dateFormat = DateFormat('MMM d, h:mm a');

    // Fix the phone number display - ensure it only has one + sign
    final phoneNumber = _formatPhoneNumber(
      entry.countryCode,
      entry.phoneNumber,
    );

    // Fix country name display
    final countryName = _formatCountryName(entry.countryName);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  phoneNumber,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  countryName,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isWhatsApp ? 'WhatsApp' : 'Telegram',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                dateFormat.format(entry.timestamp),
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper method to format phone number correctly
  String _formatPhoneNumber(String countryCode, String phoneNumber) {
    // Remove any existing + signs
    String cleanCountryCode = countryCode.replaceAll('+', '');
    String cleanPhoneNumber = phoneNumber.replaceAll('+', '');

    // Add proper spacing between groups of digits if the number is long enough
    if (cleanPhoneNumber.length > 6) {
      // Format: +XX XXX XXX XXXX
      final firstPart = cleanPhoneNumber.substring(0, 3);
      final secondPart = cleanPhoneNumber.substring(3, 6);
      final thirdPart = cleanPhoneNumber.substring(6);

      return '+$cleanCountryCode $firstPart $secondPart $thirdPart';
    } else if (cleanPhoneNumber.length > 3) {
      // Format: +XX XXX XXXX
      final firstPart = cleanPhoneNumber.substring(0, 3);
      final secondPart = cleanPhoneNumber.substring(3);

      return '+$cleanCountryCode $firstPart $secondPart';
    }

    // Return basic formatted number with just one + sign
    return '+$cleanCountryCode $cleanPhoneNumber';
  }

  // Helper method to format country name correctly
  String _formatCountryName(String countryName) {
    if (countryName.isEmpty) {
      return 'Unknown';
    }

    // Capitalize first letter of each word
    final words = countryName.split(' ');
    final capitalizedWords = words.map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    });

    return capitalizedWords.join(' ');
  }

  Widget _buildEmptyState() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Activity',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.darkColor,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history, size: 48, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'No recent activity',
                    style: TextStyle(color: Colors.grey[500], fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
