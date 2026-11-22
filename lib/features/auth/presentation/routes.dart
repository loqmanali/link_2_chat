import 'package:go_router/go_router.dart';
import 'package:link_2_chat/features/auth/presentation/register_screen.dart';
import 'package:link_2_chat/features/auth/presentation/sign_in_screen.dart';

/// The public screens. The values match `AppPaths` in `app/redirect.dart`.
const String authSignInPath = '/sign-in';
const String authRegisterPath = '/register';

/// The sign-in and register screens, spread into the app router. A successful
/// sign-in navigates through the router's redirect, not through the screens.
final List<RouteBase> authRoutes = [
  GoRoute(
    path: authSignInPath,
    builder: (context, state) => const SignInScreen(),
  ),
  GoRoute(
    path: authRegisterPath,
    builder: (context, state) => const RegisterScreen(),
  ),
];
