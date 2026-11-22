import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/app_theme.dart';
import '../../core/models/phone_entry.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/loading_indicator.dart';
import 'history_viewmodel.dart';

class HistoryScreen extends HookWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final historyBloc = useMemoized(() => HistoryBloc(), []);

    // Load data when screen is first shown
    useEffect(() {
      historyBloc.add(LoadHistoryEvent());
      return () {
        historyBloc.close();
      };
    }, [historyBloc]);

    return BlocProvider(
      create: (context) => historyBloc,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: const CustomAppBar(title: 'History'),
        body: BlocBuilder<HistoryBloc, HistoryState>(
          builder: (context, state) {
            if (state.isLoading && state.entries.isEmpty) {
              return const LoadingIndicator(message: 'Loading history...');
            }

            if (state.entries.isEmpty) {
              return _buildEmptyState();
            }

            return RefreshIndicator(
              onRefresh: () async {
                historyBloc.add(LoadHistoryEvent());
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.entries.length,
                itemBuilder: (context, index) {
                  final entry = state.entries[index];
                  return _buildHistoryItem(context, entry, index);
                },
              ),
            );
          },
        ),
        floatingActionButton: BlocBuilder<HistoryBloc, HistoryState>(
          builder: (context, state) {
            if (state.entries.isEmpty) return const SizedBox();

            return FloatingActionButton(
              onPressed: () {
                _showClearHistoryDialog(context, historyBloc);
              },
              backgroundColor: Colors.red,
              child: const Icon(Icons.delete),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.history, size: 64, color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          Text(
            'No history yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Links you generate will appear here',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(BuildContext context, PhoneEntry entry, int index) {
    final isWhatsApp = entry.platform == 'whatsapp';
    final platformColor =
        isWhatsApp ? AppTheme.whatsappColor : AppTheme.telegramColor;
    final dateFormat = DateFormat('MMM d, yyyy - h:mm a');

    // Format phone number correctly
    final formattedPhoneNumber = _formatPhoneNumber(
      entry.countryCode,
      entry.phoneNumber,
    );

    // Format country name correctly
    final formattedCountryName = _formatCountryName(entry.countryName);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: platformColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isWhatsApp ? Icons.message_rounded : Icons.send_rounded,
            color: platformColor,
            size: 24,
          ),
        ),
        title: Text(
          formattedPhoneNumber,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(formattedCountryName, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 4),
            Text(
              dateFormat.format(entry.timestamp),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: platformColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            isWhatsApp ? 'WhatsApp' : 'Telegram',
            style: TextStyle(
              color: platformColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
        onTap: () {
          _showHistoryItemDetails(context, entry);
        },
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

  void _showHistoryItemDetails(BuildContext context, PhoneEntry entry) {
    final isWhatsApp = entry.platform == 'whatsapp';
    final platformName = isWhatsApp ? 'WhatsApp' : 'Telegram';
    final platformColor =
        isWhatsApp ? AppTheme.whatsappColor : AppTheme.telegramColor;
    final dateFormat = DateFormat('MMMM d, yyyy - h:mm a');

    // Format phone number correctly
    final formattedPhoneNumber = _formatPhoneNumber(
      entry.countryCode,
      entry.phoneNumber,
    );

    // Format country name correctly
    final formattedCountryName = _formatCountryName(entry.countryName);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: platformColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isWhatsApp ? Icons.message_rounded : Icons.send_rounded,
                    color: platformColor,
                  ),
                ),
                const SizedBox(width: 12),
                Text('$platformName Link'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Phone Number:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  formattedPhoneNumber,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Country:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  formattedCountryName,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Generated on:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  dateFormat.format(entry.timestamp),
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Link:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.link,
                          style: TextStyle(color: platformColor, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
              TextButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: entry.link));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Link copied to clipboard')),
                  );
                  Navigator.of(context).pop();
                },
                child: const Text('Copy Link'),
              ),
              TextButton(
                onPressed: () {
                  _openLink(entry.link);
                  Navigator.of(context).pop();
                },
                child: const Text('Open Link'),
              ),
            ],
          ),
    );
  }

  Future<void> _openLink(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showClearHistoryDialog(BuildContext context, HistoryBloc bloc) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Clear History'),
            content: const Text(
              'Are you sure you want to clear all history? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  bloc.add(ClearHistoryEvent());
                  Navigator.of(context).pop();
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Clear'),
              ),
            ],
          ),
    );
  }
}
