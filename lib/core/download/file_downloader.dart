import 'dart:typed_data';

import 'package:link_2_chat/core/download/file_downloader_io.dart'
    if (dart.library.html) 'package:link_2_chat/core/download/file_downloader_web.dart'
    as impl;

/// Hands [bytes] to the user as a downloadable file: the browser download
/// flow on web, the share sheet (save to Files, Drive, ...) on mobile. This
/// replaces the pre-refactor `universal_html` download shim.
Future<void> saveGeneratedFile({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
}) => impl.saveGeneratedFile(
  bytes: bytes,
  fileName: fileName,
  mimeType: mimeType,
);
