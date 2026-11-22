import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

/// Native: no disk writes of our own — the share sheet receives the bytes in
/// memory and the user picks where they land.
Future<void> saveGeneratedFile({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
}) => SharePlus.instance.share(
  ShareParams(
    files: [XFile.fromData(bytes, name: fileName, mimeType: mimeType)],
  ),
);
