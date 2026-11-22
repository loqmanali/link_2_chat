import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:link_2_chat/core/environment/supported_locales.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Build-time facts the app shows. The app is fully local: there is no server
/// to point at, so there is no URL here.
///
/// Values come from `--dart-define-from-file=env/dev.json` (or `prod.json`).
/// There are no native flavors.
class AppEnvironment {
  const AppEnvironment({
    required this.appName,
    required this.appBuild,
    required this.platform,
    this.supportedLocaleCodes = const ['en'],
  });

  /// Reads the defines and the running app's build number.
  static Future<AppEnvironment> load() async {
    final info = await PackageInfo.fromPlatform();
    return AppEnvironment(
      appName: _appName.isEmpty ? 'Link2Chat' : _appName,
      appBuild: int.tryParse(info.buildNumber) ?? 0,
      platform: _platformName,
      supportedLocaleCodes: parseLocaleCodes(_supportedLocales),
    );
  }

  static const String _appName = String.fromEnvironment('APP_NAME');
  static const String _supportedLocales = String.fromEnvironment(
    'SUPPORTED_LOCALES',
    defaultValue: 'en,ar',
  );

  static String get _platformName {
    if (kIsWeb) return 'web';
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isWindows) return 'windows';
    return 'linux';
  }

  /// Display name from `APP_NAME` (user-visible titles come from the ARB files).
  final String appName;

  /// Integer build number (the `+N` of the pubspec).
  final int appBuild;

  /// `web`, `ios`, `android`, `macos`, `windows` or `linux`.
  final String platform;

  /// Language codes the app offers, from `SUPPORTED_LOCALES`.
  final List<String> supportedLocaleCodes;
}

/// Overridden in `bootstrap.dart` (and in tests) with the loaded environment.
final appEnvironmentProvider = Provider<AppEnvironment>(
  (ref) => throw UnimplementedError('appEnvironmentProvider is not overridden'),
);
