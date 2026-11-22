import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:link_2_chat/core/design/app_context.dart';
import 'package:link_2_chat/core/session/session_providers.dart';
import 'package:link_2_chat/features/auth/auth.dart';
import 'package:link_2_chat/features/dashboard/dashboard.dart';
import 'package:link_2_chat/features/history/history.dart';
import 'package:link_2_chat/features/home/home.dart';
import 'package:link_2_chat/features/settings/settings.dart';
import 'package:link_2_chat/features/teams/teams.dart';
import 'package:link_2_chat/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// The signed-in shell: the four base tabs, plus Teams while the account is a
/// paid, non-guest one — the same visibility rule the pre-refactor shell used.
class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  // Ephemeral UI state owned by this State (the kit's ValueNotifier rule).
  final ValueNotifier<int> _tab = ValueNotifier<int>(0);

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    final session = ref.watch(sessionControllerProvider);
    final user = ref.watch(currentUserProvider).value;
    final showTeams =
        user != null &&
        user.subscriptionTier != SubscriptionTier.free &&
        user.isPremium &&
        !(session?.isGuest ?? true);

    final screens = <Widget>[
      const HomeScreen(),
      const DashboardScreen(),
      const HistoryScreen(),
      if (showTeams) const TeamsScreen(),
      const SettingsScreen(),
    ];

    final destinations = <Widget>[
      NavigationDestination(
        icon: const Icon(Icons.chat_bubble_outline_rounded),
        selectedIcon: const Icon(Icons.chat_bubble_rounded),
        label: l10n.commonHome,
      ),
      NavigationDestination(
        icon: const Icon(Icons.insights_outlined),
        selectedIcon: const Icon(Icons.insights_rounded),
        label: l10n.commonDashboard,
      ),
      NavigationDestination(
        icon: const Icon(Icons.history_outlined),
        selectedIcon: const Icon(Icons.history_rounded),
        label: l10n.commonHistory,
      ),
      if (showTeams)
        NavigationDestination(
          icon: const Icon(Icons.group_outlined),
          selectedIcon: const Icon(Icons.group_rounded),
          label: l10n.commonTeams,
        ),
      NavigationDestination(
        icon: const Icon(Icons.settings_outlined),
        selectedIcon: const Icon(Icons.settings_rounded),
        label: l10n.commonSettings,
      ),
    ];

    // A hidden Teams tab cannot stay selected.
    if (_tab.value >= screens.length) _tab.value = screens.length - 1;

    return Scaffold(
      body: ValueListenableBuilder<int>(
        valueListenable: _tab,
        builder:
            (context, index, _) =>
                IndexedStack(index: index, children: screens),
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: colors.card,
          indicatorColor: colors.primary.withValues(alpha: 0.15),
        ),
        child: ValueListenableBuilder<int>(
          valueListenable: _tab,
          builder:
              (context, index, _) => NavigationBar(
                selectedIndex: index,
                onDestinationSelected: (i) => _tab.value = i,
                destinations: [
                  for (final destination in destinations)
                    destination as NavigationDestination,
                ],
              ),
        ),
      ),
    );
  }
}
