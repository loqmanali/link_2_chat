import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

class QrService {
  /// Creates a QR code widget for a given data string
  ///
  /// [data] is the string to encode in the QR code (usually a URL)
  /// [size] is the width and height of the QR code
  /// [backgroundColor] is the background color of the QR code
  /// [foregroundColor] is the color of the QR code data modules
  static Widget generateQrWidget({
    required String data,
    double size = 200.0,
    Color backgroundColor = Colors.white,
    Color foregroundColor = Colors.black,
  }) {
    return QrImageView(
      data: data,
      version: QrVersions.auto,
      size: size,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      padding: EdgeInsets.zero,
      errorStateBuilder: (context, error) {
        return Container(
          width: size,
          height: size,
          color: backgroundColor,
          child: Center(
            child: Text(
              'Error generating QR code',
              style: TextStyle(color: foregroundColor),
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }

  /// Share the QR code as a PNG image
  ///
  /// [qrKey] is the GlobalKey attached to the QR Widget
  /// [title] is the title of the share dialog
  static Future<void> shareQrCode(
    GlobalKey qrKey, {
    String title = 'Share QR Code',
  }) async {
    try {
      // Find the RenderRepaintBoundary
      RenderRepaintBoundary boundary =
          qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

      // Convert to image
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData != null) {
        final bytes = byteData.buffer.asUint8List();
        final tempFile = XFile.fromData(
          bytes,
          mimeType: 'image/png',
          name: 'qr_code.png',
        );

        await Share.shareXFiles([tempFile], text: title);
      }
    } catch (e) {
      print('Error sharing QR code: $e');
    }
  }
}
