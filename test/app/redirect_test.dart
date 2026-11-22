import 'package:flutter_test/flutter_test.dart';
import 'package:link_2_chat/app/redirect.dart';
import 'package:link_2_chat/core/session/session.dart';

void main() {
  const user = AppSession(userId: 'u1', isGuest: false);
  const guest = AppSession(userId: 'guest', isGuest: true);

  test('signed out goes to sign-in; signed in goes to the app', () {
    expect(resolveRedirect(location: '/', session: null), AppPaths.signIn);
    expect(resolveRedirect(location: '/', session: user), AppPaths.main);
    expect(resolveRedirect(location: '/', session: guest), AppPaths.main);
  });

  test('an empty location behaves like the root', () {
    expect(resolveRedirect(location: '', session: null), AppPaths.signIn);
    expect(resolveRedirect(location: '', session: user), AppPaths.main);
  });

  test('signed out cannot open a protected path', () {
    expect(
      resolveRedirect(location: '/settings', session: null),
      AppPaths.signIn,
    );
    expect(
      resolveRedirect(location: '/teams/details/t1', session: null),
      AppPaths.signIn,
    );
  });

  test('signed in may stay on any protected path', () {
    expect(resolveRedirect(location: '/settings', session: user), isNull);
    expect(resolveRedirect(location: '/api-keys', session: guest), isNull);
  });

  test('public paths bounce a signed-in user back to the app', () {
    expect(resolveRedirect(location: '/sign-in', session: user), AppPaths.main);
    expect(
      resolveRedirect(location: '/register', session: user),
      AppPaths.main,
    );
  });

  test('public paths stay for a signed-out user', () {
    expect(resolveRedirect(location: '/sign-in', session: null), isNull);
    expect(resolveRedirect(location: '/register', session: null), isNull);
  });

  test('the path is compared without query or fragment', () {
    expect(
      resolveRedirect(location: '/sign-in?from=register', session: user),
      AppPaths.main,
    );
    expect(
      resolveRedirect(location: '/settings#profile', session: null),
      AppPaths.signIn,
    );
  });
}
