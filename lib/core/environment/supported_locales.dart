/// Splits `SUPPORTED_LOCALES` (for example `en,ar`) into language codes;
/// an empty value means English only.
List<String> parseLocaleCodes(String csv) {
  final codes =
      csv.split(',').map((c) => c.trim()).where((c) => c.isNotEmpty).toList();
  return codes.isEmpty ? const ['en'] : codes;
}
