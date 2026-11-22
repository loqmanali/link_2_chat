import 'dart:developer' as developer;
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:link_2_chat/app/overrides.dart';
import 'package:link_2_chat/core/environment/app_environment.dart';
import 'package:link_2_chat/core/local_db/local_database.dart';
import 'package:link_2_chat/core/session/session_store.dart';
import 'package:link_2_chat/core/startup/startup_gate.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart'
    show databaseFactoryFfiWeb;

/// Installs the error hooks and starts the app inside the startup gate:
/// everything that needs the disk (the local database, the stored session)
/// loads there, so a database that cannot be opened shows Retry and Reset
/// instead of a black screen. Nothing here waits on the network — the app is
/// fully local.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Errors are reported, never swallowed silently. Replace `developer.log`
  // with a crash reporter when the project has one.
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    developer.log(
      'Flutter error',
      error: details.exception,
      stackTrace: details.stack,
    );
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    developer.log('Uncaught error', error: error, stackTrace: stack);
    return true;
  };

  final environment = await AppEnvironment.load();
  final preferences = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [
        startupLoaderProvider.overrideWithValue(() async {
          final database = await LocalDatabase.open(
            // sqflite has no web implementation; the FFI-web factory backs it
            // with the sqlite3 wasm shipped in web/.
            factory: kIsWeb ? databaseFactoryFfiWeb : null,
          );
          final session = await SessionStore(preferences: preferences).read();
          return StartupApp(
            overrides: [
              ...appOverrides(
                environment: environment,
                preferences: preferences,
                session: session,
              ),
              databaseProvider.overrideWithValue(database),
            ],
          );
        }),
      ],
      child: const StartupGate(),
    ),
  );
}
