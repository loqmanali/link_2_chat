import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/config/app_theme.dart';
import '../../../core/services/qr_service.dart';

class QrCodeWidget extends StatelessWidget {
  final String data;
  final String title;
  final GlobalKey qrKey;

  const QrCodeWidget({
    super.key,
    required this.data,
    required this.title,
    required this.qrKey,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: AppTheme.titleStyle, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.lightColor),
            ),
            child: RepaintBoundary(
              key: qrKey,
              child: QrService.generateQrWidget(
                data: data,
                size: 200,
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.share),
                label: const Text('Share QR'),
                onPressed: () => _shareQrCode(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondaryColor,
                ),
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.content_copy),
                label: const Text('Copy Link'),
                onPressed: () => _copyLink(context),
                style: AppTheme.outlineButtonStyle,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            data,
            style: AppTheme.captionStyle,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  void _shareQrCode() async {
    await QrService.shareQrCode(qrKey, title: 'Share QR Code for $title');
  }

  void _copyLink(BuildContext context) {
    Clipboard.setData(ClipboardData(text: data));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Link copied to clipboard'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
