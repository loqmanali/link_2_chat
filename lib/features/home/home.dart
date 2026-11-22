/// The home feature: turning a phone number into a WhatsApp or Telegram
/// link, with its QR code. Other features and the shell import this barrel
/// only.
export 'package:link_2_chat/features/home/application/home_providers.dart'
    show
        GenerateLinkAction,
        HomeController,
        HomeState,
        generateLinkActionProvider,
        homeControllerProvider;
export 'package:link_2_chat/features/home/domain/guest_limit_failure.dart'
    show GuestLimitFailure, GuestLinks;
export 'package:link_2_chat/features/home/domain/phone_draft.dart'
    show PhoneDraft;
export 'package:link_2_chat/features/home/presentation/home_screen.dart'
    show HomeScreen;
