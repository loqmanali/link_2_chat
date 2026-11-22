import 'dart:developer' as developer;

import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:link_2_chat/app/app.dart';
import 'package:link_2_chat/core/design/app_spacing.dart';
import 'package:link_2_chat/core/design/app_theme.dart';
import 'package:link_2_chat/core/design/components/app_button.dart';
import 'package:link_2_chat/core/design/components/app_state_view.dart';
import 'package:link_2_chat/core/local_db/local_database.dart';
import 'package:link_2_chat/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// Opens what the first frame needs from disk (the local database and what is
/// read through it) and returns the app to run. Overridden in `bootstrap.dart`
/// and in tests; it throws when the database cannot be opened.
final startupLoaderProvider = Provider<Future<Widget> Function()>(
  (ref) => throw UnimplementedError('startupLoaderProvider is not overridden'),
);

/// The app, with [overrides] in a container of its own, not a `ProviderScope`
/// nested in the gate's: a nested scope only re-creates the providers it
/// overrides, so every other provider (the API client, the session, ...) would
/// stay in the gate's root and read the unset `databaseProvider` and
/// `appEnvironmentProvider` there.
class StartupApp extends StatefulWidget {
  const StartupApp({required this.overrides, super.key});

  final List<Override> overrides;

  @override
  State<StartupApp> createState() => _StartupAppState();
}

class _StartupAppState extends State<StartupApp> {
  // A State may own what Flutter makes it own (controllers, containers); the
  // app's state itself is in Riverpod.
  late final ProviderContainer _container = ProviderContainer(
    overrides: widget.overrides,
  );

  @override
  void dispose() {
    _container.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      UncontrolledProviderScope(container: _container, child: const App());
}

/// Deletes the local database file. Tests replace it.
final startupResetProvider = Provider<Future<void> Function()>(
  (ref) => () => LocalDatabase.delete(),
);

/// The app to show once the local data is open, or the error that kept it
/// closed. Never retried on its own: a person decides (Retry, Reset).
final startupProvider = AsyncNotifierProvider<StartupController, Widget>(
  StartupController.new,
  retry: (_, _) => null,
);

class StartupController extends AsyncNotifier<Widget> {
  @override
  Future<Widget> build() async {
    try {
      return await ref.read(startupLoaderProvider)();
    } on Object catch (error, stack) {
      developer.log(
        'Local data could not be opened',
        error: error,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  void retry() => ref.invalidateSelf();

  /// Deletes the database and opens again. Anything only the database held is
  /// lost; the confirmation says so. The session is in secure storage and
  /// survives.
  Future<void> reset() async {
    await ref.read(startupResetProvider)();
    ref.invalidateSelf();
  }
}

/// Shows the app when the local data opened, otherwise a minimal screen with
/// Retry and Reset, never a black one.
class StartupGate extends ConsumerWidget {
  const StartupGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final startup = ref.watch(startupProvider);
    final app = startup.value;
    if (app != null) return app;
    return _StartupShell(
      child:
          startup.hasError
              ? const _DataErrorScreen()
              : const AppStateView.loading(),
    );
  }
}

/// A small app of its own: the real one needs the database to exist.
class _StartupShell extends StatelessWidget {
  const _StartupShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SafeArea(child: child)),
    );
  }
}

class _DataErrorScreen extends ConsumerWidget {
  const _DataErrorScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        Expanded(
          child: AppStateView.error(
            message: l10n.startupDataErrorMessage,
            retryLabel: l10n.commonRetry,
            onRetry: ref.read(startupProvider.notifier).retry,
          ),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.all(AppSpacing.xl),
          child: AppButton(
            label: l10n.startupResetAction,
            onPressed: () => _confirmReset(context, ref),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(l10n.startupResetConfirmTitle),
            content: Text(l10n.startupResetConfirmMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l10n.commonCancel),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(l10n.startupResetConfirmAction),
              ),
            ],
          ),
    );
    if (confirmed ?? false) {
      await ref.read(startupProvider.notifier).reset();
    }
  }
}
