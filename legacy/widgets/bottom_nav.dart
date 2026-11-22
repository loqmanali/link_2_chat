import 'package:flutter/material.dart';

import '../core/config/app_theme.dart';

class BottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final bool showTeamsTab;

  const BottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.showTeamsTab = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _adjustedCurrentIndex(currentIndex),
        onTap: _handleTap,
        backgroundColor: Colors.white,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: AppTheme.mediumColor,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            activeIcon: Icon(Icons.analytics),
            label: 'Dashboard',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'History',
          ),
          if (showTeamsTab)
            const BottomNavigationBarItem(
              icon: Icon(Icons.people_outlined),
              activeIcon: Icon(Icons.people),
              label: 'Teams',
            ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  // Adjust current index based on whether teams tab is shown
  int _adjustedCurrentIndex(int index) {
    // If teams tab is hidden and index is for settings (which would be 3 instead of 4)
    if (!showTeamsTab && index >= 3) {
      return 3; // Settings tab is now at position 3
    }
    return index;
  }

  // Handle tap with adjusted index
  void _handleTap(int index) {
    // If teams tab is hidden and user taps on settings or any tab after where teams would be
    if (!showTeamsTab && index >= 3) {
      onTap(
        3,
      ); // Always navigate to settings (which is now at position 3 in the screens list)
    } else {
      onTap(index);
    }
  }
}
