import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:link_2_chat/app/redirect.dart';
import 'package:link_2_chat/core/session/session_providers.dart';
import 'package:link_2_chat/features/api_keys/api_keys.dart';
import 'package:link_2_chat/features/auth/auth.dart';
import 'package:link_2_chat/features/subscription/subscription.dart';
import 'package:link_2_chat/features/teams/teams.dart';
import 'package:link_2_chat/main_screen.dart';
import 'package:material_ui/material_ui.dart';

/// The one router. It re-evaluates the redirect whenever the session changes,
/// so a sign-in, a sign-out or a guest entry moves the user at once. The tabs
/// live under `/main` in [MainScreen]; everything else is a feature route.
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
      ...authRoutes,
      GoRoute(
        path: AppPaths.main,
        builder: (context, state) => const MainScreen(),
      ),
      ...subscriptionRoutes,
      ...apiKeysRoutes,
      ...teamsRoutes,
    ],
  );
  ref.onDispose(() {
    router.dispose();
    changes.dispose();
  });
  return router;
});
