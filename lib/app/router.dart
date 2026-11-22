import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:link_2_chat/app/redirect.dart';
import 'package:link_2_chat/core/session/session_providers.dart';
import 'package:material_ui/material_ui.dart';

/// The one router. It re-evaluates the redirect whenever the session changes,
/// so a sign-in or sign-out moves the user at once. Feature route lists are
/// spread in here as each feature lands.
final routerProvider = Provider<GoRouter>((ref) {
  final changes = ValueNotifier<int>(0);
  ref.listen(sessionControllerProvider, (_, _) => changes.value++);
  final router = GoRouter(
    initialLocation: AppPaths.main,
    refreshListenable: changes,
    redirect:
        (context, state) => resolveRedirect(
          location: state.uri.toString(),
          session: ref.read(sessionControllerProvider),
        ),
    routes: [
      // TEMPORARY placeholder until the features land (removed at the end of
      // the port).
      GoRoute(
        path: '/',
        builder: (context, state) => const _PlaceholderScreen(),
      ),
    ],
  );
  ref.onDispose(() {
    router.dispose();
    changes.dispose();
  });
  return router;
});

/// TEMPORARY: something to draw while the port is in flight.
class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Link2Chat')));
}
