import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/models/user.dart';
import 'core/services/auth_service.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/history/history_screen.dart';
import 'features/home/home_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/teams/teams_screen.dart';
import 'widgets/bottom_nav.dart';

class MainScreen extends HookWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final selectedIndex = useState(0);
    final currentUser = useState<User?>(null);
    final isGuestUser = useState(false);
    final isLoading = useState(true);

    // Check if user is guest or free tier
    useEffect(() {
      _checkUserStatus(currentUser, isGuestUser, isLoading);
      return null;
    }, []);

    // List of screens to show based on the selected index
    final screens = [
      const HomeScreen(),
      const DashboardScreen(),
      const HistoryScreen(),
      if (currentUser.value != null &&
          currentUser.value!.subscriptionTier != SubscriptionTier.free &&
          currentUser.value!.hasActiveSubscription &&
          !isGuestUser.value)
        const TeamsScreen(),
      const SettingsScreen(),
    ];

    // If teams tab is hidden and user tries to access it, reset to home
    if (selectedIndex.value >= screens.length) {
      selectedIndex.value = 0;
    }

    // Determine if teams tab should be shown
    final showTeamsTab =
        currentUser.value != null &&
        currentUser.value!.subscriptionTier != SubscriptionTier.free &&
        currentUser.value!.hasActiveSubscription &&
        !isGuestUser.value;

    // Print debug information about showTeamsTab condition
    print('DEBUG: Teams tab visibility check:');
    print('- currentUser != null: ${currentUser.value != null}');
    if (currentUser.value != null) {
      print(
        '- subscriptionTier != free: ${currentUser.value!.subscriptionTier != SubscriptionTier.free}',
      );
      print(
        '- hasActiveSubscription: ${currentUser.value!.hasActiveSubscription}',
      );
    }
    print('- !isGuestUser: ${!isGuestUser.value}');
    print('- Final showTeamsTab result: $showTeamsTab');

    // Apply system UI overlay style directly in this screen
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent, // Make status bar transparent
        statusBarIconBrightness:
            Brightness.light, // Light icons on dark background
        systemNavigationBarColor: Colors.white, // White navigation bar
        systemNavigationBarIconBrightness:
            Brightness.dark, // Dark icons on white background
        systemNavigationBarDividerColor: Colors.transparent, // No divider
      ),
    );

    return SafeArea(
      top: false,
      child: Scaffold(
        body:
            isLoading.value
                ? const Center(child: CircularProgressIndicator())
                : IndexedStack(index: selectedIndex.value, children: screens),
        bottomNavigationBar: BottomNav(
          currentIndex: selectedIndex.value,
          onTap: (index) {
            // Make sure the index is valid for our screens array
            if (index < screens.length) {
              selectedIndex.value = index;
            }
          },
          showTeamsTab: showTeamsTab,
        ),
      ),
    );
  }

  Future<void> _checkUserStatus(
    ValueNotifier<User?> currentUser,
    ValueNotifier<bool> isGuestUser,
    ValueNotifier<bool> isLoading,
  ) async {
    try {
      // Check if user is a guest
      final prefs = await SharedPreferences.getInstance();
      isGuestUser.value = prefs.getBool('is_guest_user') ?? false;

      // If not guest, get current user
      if (!isGuestUser.value) {
        currentUser.value = await AuthService().getCurrentUser();

        // Debug information
        if (currentUser.value != null) {
          print('DEBUG: User subscription info:');
          print('- User ID: ${currentUser.value!.id}');
          print('- Subscription Tier: ${currentUser.value!.subscriptionTier}');
          print(
            '- Has Active Subscription: ${currentUser.value!.hasActiveSubscription}',
          );
          print('- Expiry Date: ${currentUser.value!.subscriptionExpiry}');
          print('- Team IDs: ${currentUser.value!.teamIds}');
          print('- Team IDs Length: ${currentUser.value!.teamIds.length}');
          print('- Is Guest: $isGuestUser');

          // Check if user has teams
          if (currentUser.value!.teamIds.isEmpty) {
            print(
              'DEBUG: User has no teams. This could be why Teams tab is not showing.',
            );
          }
        } else {
          print('DEBUG: Current user is null');
        }
      } else {
        print('DEBUG: User is a guest');
      }
    } catch (e) {
      print('Error checking user status: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
