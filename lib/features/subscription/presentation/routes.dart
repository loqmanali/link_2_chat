import 'package:go_router/go_router.dart';
import 'package:link_2_chat/features/subscription/presentation/subscription_screen.dart';

/// The plans screen. The value matches `AppPaths.subscription`.
const String subscriptionPath = '/subscription';

/// The plans screen, spread into the app router.
final List<RouteBase> subscriptionRoutes = [
  GoRoute(
    path: subscriptionPath,
    builder: (context, state) => const SubscriptionScreen(),
  ),
];
