import 'package:link_2_chat/core/session/session.dart';

// Feature route paths. During the port they live here; each lands in its
// feature's `presentation/routes.dart` as the feature arrives (the guard's
// convention), and this file only imports the barrels.
abstract final class AppPaths {
  static const String signIn = '/sign-in';
  static const String register = '/register';
  static const String main = '/main';
  static const String settings = '/settings';
  static const String subscription = '/subscription';
  static const String apiKeys = '/api-keys';
  static String teamDetails(String teamId) =>
      '/teams/$teamDetailsSegment/$teamId';
  static const String teamDetailsSegment = 'details';
}

/// The paths a signed-out visitor may open.
const Set<String> publicPaths = {AppPaths.signIn, AppPaths.register};

/// Where [location] must go, or null to stay. Pure, so it is unit-tested
/// without a router.
String? resolveRedirect({
  required String location,
  required AppSession? session,
}) {
  final path = Uri.parse(location).path;
  final home = session == null ? AppPaths.signIn : AppPaths.main;

  if (path == '/' || path.isEmpty) return home;
  if (session == null) {
    return publicPaths.contains(path) ? null : AppPaths.signIn;
  }
  if (publicPaths.contains(path)) return AppPaths.main;
  return null;
}
