import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:link_2_chat/core/settings/app_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Whether generated links are kept in the history. The key and the default
/// are the pre-refactor ones (`settings_screen` read/wrote the same key).
final saveHistoryControllerProvider =
    NotifierProvider<SaveHistoryController, bool>(SaveHistoryController.new);

class SaveHistoryController extends Notifier<bool> {
  static const String key = 'save_links_history';

  @override
  bool build() => ref.read(sharedPreferencesProvider).getBool(key) ?? true;

  Future<void> choose(bool value) async {
    state = value;
    await ref.read(sharedPreferencesProvider).setBool(key, value);
  }
}

/// Whether a finished link shows its QR code right away. The key and the
/// default are the pre-refactor ones (default off there).
final showQrControllerProvider = NotifierProvider<ShowQrController, bool>(
  ShowQrController.new,
);

class ShowQrController extends Notifier<bool> {
  static const String key = 'show_qr_by_default';

  @override
  bool build() => ref.read(sharedPreferencesProvider).getBool(key) ?? false;

  Future<void> choose(bool value) async {
    state = value;
    await ref.read(sharedPreferencesProvider).setBool(key, value);
  }
}

/// The app's version ("1.2.3"), read from the package metadata. Tests
/// override this — `PackageInfo.fromPlatform` needs a platform channel.
final appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return info.version;
});
