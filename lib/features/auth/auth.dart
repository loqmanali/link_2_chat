/// The auth feature: device-local accounts and the session they drive.
/// Other features import this barrel only.
export 'package:link_2_chat/features/auth/application/auth_providers.dart'
    show
        authWatcherProvider,
        currentUserProvider,
        usersStoreProvider,
        signInActionProvider,
        signUpActionProvider,
        guestSignInActionProvider,
        signOutActionProvider,
        updateProfileActionProvider,
        deleteAccountActionProvider,
        subscriptionTierProvider;
export 'package:link_2_chat/features/auth/domain/password_hasher.dart'
    show hashPassword;
export 'package:link_2_chat/features/auth/domain/user.dart'
    show SubscriptionTier, User;
export 'package:link_2_chat/features/auth/presentation/register_screen.dart'
    show RegisterScreen;
export 'package:link_2_chat/features/auth/presentation/routes.dart'
    show authRegisterPath, authRoutes, authSignInPath;
export 'package:link_2_chat/features/auth/presentation/sign_in_screen.dart'
    show SignInScreen;
