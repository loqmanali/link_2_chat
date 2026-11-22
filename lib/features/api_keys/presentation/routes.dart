import 'package:go_router/go_router.dart';
import 'package:link_2_chat/features/api_keys/presentation/api_keys_screen.dart';

/// The standalone API-keys route, matching `AppPaths.apiKeys`.
const String apiKeysPath = '/api-keys';

/// The route list the app router spreads in.
final List<RouteBase> apiKeysRoutes = [
  GoRoute(
    path: apiKeysPath,
    builder: (context, state) => const ApiKeysScreen(),
  ),
];
