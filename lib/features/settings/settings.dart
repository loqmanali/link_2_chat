/// The settings feature: the settings tab and its preferences. Other features
/// import this barrel only.
export 'package:link_2_chat/features/settings/application/settings_providers.dart'
    show
        saveHistoryControllerProvider,
        showQrControllerProvider,
        appVersionProvider;
export 'package:link_2_chat/features/settings/presentation/settings_screen.dart'
    show SettingsScreen;
