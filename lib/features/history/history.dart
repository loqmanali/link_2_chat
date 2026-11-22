/// The history feature: every generated link of the account, its details and
/// the clear-all action. Other features and the shell import this barrel
/// only.
export 'package:link_2_chat/features/history/application/history_providers.dart'
    show
        ClearHistoryAction,
        HistoryController,
        HistoryState,
        clearHistoryActionProvider,
        historyControllerProvider;
export 'package:link_2_chat/features/history/presentation/history_screen.dart'
    show HistoryScreen;
