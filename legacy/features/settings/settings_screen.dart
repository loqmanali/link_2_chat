import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config/app_theme.dart';
import '../../core/config/constants.dart';
import '../../core/models/user.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/supabase_service.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/loading_indicator.dart';
import '../api/api_keys_screen.dart';
import '../auth/login_screen.dart';
import '../auth/register_screen.dart';
import '../subscription/subscription_screen.dart';

class SettingsScreen extends HookWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isLoading = useState(true);
    final themeMode = useState(ThemeMode.system);
    final saveLinksHistory = useState(true);
    final defaultPlatform = useState<String>('whatsapp');
    final showQrByDefault = useState(false);
    final currentUser = useState<User?>(null);

    // Load settings and user
    useEffect(() {
      _loadAll(
        themeMode: themeMode,
        saveLinksHistory: saveLinksHistory,
        defaultPlatform: defaultPlatform,
        showQrByDefault: showQrByDefault,
        currentUser: currentUser,
        setLoading: (val) => isLoading.value = val,
      );
      return null;
    }, []);

    // Show password dialog
    Future<String?> showPasswordDialog(BuildContext context) async {
      final passwordController = TextEditingController();

      return showDialog<String>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Enter Password'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Please enter your password to continue'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed:
                      () => Navigator.of(context).pop(passwordController.text),
                  child: const Text('Continue'),
                ),
              ],
            ),
      );
    }

    // Function to sync user data from Supabase
    Future<void> syncUserDataFromSupabase() async {
      try {
        // Show loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Syncing user data...'),
            duration: Duration(seconds: 1),
          ),
        );

        // Get the Supabase service
        final supabaseService = SupabaseService();

        // Check if Supabase is initialized
        if (!supabaseService.isInitialized) {
          await supabaseService.initialize();
        }

        // Get fresh user data from Supabase
        final supabaseUser = await supabaseService.getCurrentUser();

        if (supabaseUser == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to sync: Not logged in to Supabase'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // Get the current local user
        final authService = AuthService();
        final localUser = await authService.getCurrentUser();

        if (localUser == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to sync: No local user found'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // Update local user with Supabase data
        final updatedUser = localUser.copyWith(
          name: supabaseUser.name,
          role: supabaseUser.role,
          teamIds: supabaseUser.teamIds,
          subscriptionTier: supabaseUser.subscriptionTier,
          subscriptionExpiry: supabaseUser.subscriptionExpiry,
          lastLoginAt: supabaseUser.lastLoginAt,
          permissions: supabaseUser.permissions,
          preferences: supabaseUser.preferences,
          createdAt: supabaseUser.createdAt,
          passwordHash: supabaseUser.passwordHash,
        );

        // Save updated user
        await authService.updateUser(updatedUser);

        // Update UI
        currentUser.value = updatedUser;

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User data synced successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Restart the app to apply changes
        await Future.delayed(const Duration(seconds: 1));
        Navigator.pushReplacementNamed(context, '/main');
      } catch (e) {
        print('Error syncing user data: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error syncing data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    // Function to force update all local data with Supabase
    Future<void> forceUpdateAllLocalData() async {
      try {
        // Show loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Updating all local data...'),
            duration: Duration(seconds: 2),
          ),
        );

        // Get the Supabase service
        final supabaseService = SupabaseService();

        // Check if Supabase is initialized
        if (!supabaseService.isInitialized) {
          await supabaseService.initialize();
        }

        // Get the current local user
        final authService = AuthService();
        final localUser = await authService.getCurrentUser();

        if (localUser == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed: No local user found'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // Try to login again to refresh the session
        final email = localUser.email;

        // Show password dialog
        final password = await showPasswordDialog(context);

        if (password == null || password.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cancelled by user'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }

        // Login with Supabase
        final updatedUser = await authService.loginWithSupabase(
          email,
          password,
        );

        if (updatedUser == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to login with Supabase'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // Update UI
        currentUser.value = updatedUser;

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All data updated successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Restart the app to apply changes
        await Future.delayed(const Duration(seconds: 1));
        Navigator.pushReplacementNamed(context, '/main');
      } catch (e) {
        print('Error updating all local data: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }

    return Scaffold(
      appBar: const CustomAppBar(title: 'Settings'),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).scaffoldBackgroundColor,
              Theme.of(context).primaryColor.withOpacity(0.05),
            ],
            stops: const [0.0, 1.0],
          ),
        ),
        child:
            isLoading.value
                ? const Center(
                  child: LoadingIndicator(message: 'Loading settings...'),
                )
                : ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 24,
                  ),
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child:
                          currentUser.value != null
                              ? _buildProfileSection(
                                context,
                                currentUser.value!,
                              )
                              : _buildGuestLoginSection(context),
                    ),
                    const SizedBox(height: 24),
                    _buildSectionHeader('Appearance'),
                    _buildThemeSelector(themeMode.value, (value) {
                      themeMode.value = value;
                      _saveThemeMode(value);
                    }),
                    const Divider(),

                    _buildSectionHeader('Behavior'),
                    _buildSwitchTile(
                      title: 'Save links history',
                      subtitle: 'Keep a record of all generated links',
                      value: saveLinksHistory.value,
                      onChanged: (value) {
                        saveLinksHistory.value = value;
                        _saveBoolSetting('save_links_history', value);
                      },
                    ),
                    _buildSwitchTile(
                      title: 'Show QR code by default',
                      subtitle: 'Display QR code when link is generated',
                      value: showQrByDefault.value,
                      onChanged: (value) {
                        showQrByDefault.value = value;
                        _saveBoolSetting('show_qr_by_default', value);
                      },
                    ),
                    _buildPlatformSelector(defaultPlatform.value, (value) {
                      defaultPlatform.value = value;
                      _saveStringSetting('default_platform', value);
                    }),
                    const Divider(height: 40),

                    _buildSectionHeader('About'),
                    _buildAboutCard(),

                    if (currentUser.value != null) ...[
                      const Divider(height: 40),
                      _buildSectionHeader('Subscription'),
                      _buildSubscriptionTile(context, currentUser.value!),

                      if (currentUser.value!.subscriptionTier.hasApiAccess)
                        _buildSettingsActionCard(
                          title: 'API Keys',
                          subtitle: 'Manage API keys for integration',
                          icon: Icons.vpn_key,
                          iconColor: Colors.amber,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ApiKeysScreen(),
                              ),
                            );
                          },
                        ),

                      // Add sync users option for admin users
                      if (currentUser.value!.role == 'admin')
                        _buildSettingsActionCard(
                          title: 'Sync Local Users',
                          subtitle: 'Sync local users with Supabase',
                          icon: Icons.people_alt,
                          iconColor: Colors.teal,
                          onTap: () => _showSyncUsersDialog(context),
                        ),

                      _buildSettingsActionCard(
                        title: 'Sync Account Data',
                        subtitle: 'Refresh subscription and teams data',
                        icon: Icons.sync,
                        iconColor: Colors.blue,
                        onTap: syncUserDataFromSupabase,
                      ),

                      _buildSettingsActionCard(
                        title: 'Force Update All Data',
                        subtitle: 'Re-login and update all local data',
                        icon: Icons.update,
                        iconColor: Colors.purple,
                        onTap: forceUpdateAllLocalData,
                      ),

                      const SizedBox(height: 24),
                      _buildSignOutButton(context),
                      const SizedBox(height: 24),
                    ],
                  ],
                ),
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context, User user) {
    final dateFormat =
        '${user.lastLoginAt.year}-${user.lastLoginAt.month.toString().padLeft(2, '0')}-${user.lastLoginAt.day.toString().padLeft(2, '0')}';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getRoleColor(user.role),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _getRoleDisplayName(user.role),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.access_time,
                            size: 12,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Last login: $dateFormat',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),
            _buildRolePermissions(user),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),
            _buildProfileActionButtons(context, user),
          ],
        ),
      ),
    );
  }

  Widget _buildRolePermissions(User user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Permissions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        // Modern permissions list with better styling
        ListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildPermissionItem('Create Links', true, Icons.link),
            _buildPermissionItem('View History', true, Icons.history),
            _buildPermissionItem(
              'Create Teams',
              user.role == 'admin' ||
                  user.subscriptionTier != SubscriptionTier.free,
              Icons.group_add,
            ),
            _buildPermissionItem(
              'API Access',
              user.subscriptionTier.hasApiAccess,
              Icons.api,
            ),
            _buildPermissionItem(
              'Advanced Analytics',
              user.subscriptionTier.hasAdvancedAnalytics,
              Icons.analytics,
            ),
            if (user.role == 'admin')
              _buildPermissionItem(
                'Admin Panel',
                true,
                Icons.admin_panel_settings,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildPermissionItem(String label, bool enabled, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: enabled ? Colors.white : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        boxShadow:
            enabled
                ? [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
                : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color:
                enabled
                    ? Colors.green.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: enabled ? Colors.green : Colors.grey,
            size: 24,
          ),
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: enabled ? FontWeight.w600 : FontWeight.normal,
            color: enabled ? Colors.black87 : Colors.grey,
          ),
        ),
        trailing: Icon(
          enabled ? Icons.check_circle : Icons.cancel,
          color: enabled ? Colors.green : Colors.grey.withOpacity(0.5),
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.purple;
      case 'manager':
        return Colors.blue;
      case 'member':
        return Colors.green;
      case 'viewer':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getRoleDisplayName(String role) {
    // Capitalize first letter
    return role.isNotEmpty
        ? role[0].toUpperCase() + role.substring(1)
        : 'Member';
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildThemeSelector(
    ThemeMode currentMode,
    Function(ThemeMode) onChanged,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Theme Mode',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  _buildThemeOption(
                    title: 'System',
                    subtitle: 'Follow system settings',
                    icon: Icons.brightness_auto,
                    mode: ThemeMode.system,
                    currentMode: currentMode,
                    onChanged: onChanged,
                  ),
                  _buildThemeOption(
                    title: 'Light',
                    subtitle: 'Light theme for day use',
                    icon: Icons.light_mode,
                    mode: ThemeMode.light,
                    currentMode: currentMode,
                    onChanged: onChanged,
                  ),
                  _buildThemeOption(
                    title: 'Dark',
                    subtitle: 'Dark theme for night use',
                    icon: Icons.dark_mode,
                    mode: ThemeMode.dark,
                    currentMode: currentMode,
                    onChanged: onChanged,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required ThemeMode mode,
    required ThemeMode currentMode,
    required Function(ThemeMode) onChanged,
  }) {
    final isSelected = currentMode == mode;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primaryColor : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow:
            isSelected
                ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
                : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onChanged(mode),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? Colors.white.withOpacity(0.2)
                            : AppTheme.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? Colors.white : AppTheme.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              isSelected
                                  ? Colors.white.withOpacity(0.8)
                                  : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: AppTheme.primaryColor,
                      size: 16,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          title: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          trailing: Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: AppTheme.primaryColor,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: Colors.grey[300],
          ),
        ),
      ),
    );
  }

  Widget _buildPlatformSelector(
    String currentPlatform,
    Function(String) onChanged,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Default Platform',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildPlatformOption(
                    'WhatsApp',
                    'whatsapp',
                    currentPlatform,
                    onChanged,
                    const Color(0xFF25D366), // WhatsApp green
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildPlatformOption(
                    'Telegram',
                    'telegram',
                    currentPlatform,
                    onChanged,
                    const Color(0xFF0088CC), // Telegram blue
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformOption(
    String label,
    String platform,
    String currentPlatform,
    Function(String) onChanged,
    Color platformColor,
  ) {
    final isSelected = currentPlatform == platform;

    return GestureDetector(
      onTap: () => onChanged(platform),
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: isSelected ? platformColor : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? platformColor : Colors.grey.shade200,
            width: 2,
          ),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: platformColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                  : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Platform icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? Colors.white.withOpacity(0.2)
                        : platformColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: _getPlatformIcon(platform, isSelected, platformColor),
            ),
            const SizedBox(height: 12),
            // Platform name
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            // Default badge
            if (isSelected)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: platformColor, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Default',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: platformColor,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _getPlatformIcon(
    String platform,
    bool isSelected,
    Color platformColor,
  ) {
    switch (platform) {
      case 'whatsapp':
        return Icon(
          Icons.chat_bubble,
          size: 32,
          color: isSelected ? Colors.white : platformColor,
        );
      case 'telegram':
        return Icon(
          Icons.send,
          size: 32,
          color: isSelected ? Colors.white : platformColor,
        );
      default:
        return Icon(
          Icons.link,
          size: 32,
          color: isSelected ? Colors.white : platformColor,
        );
    }
  }

  void _showComingSoonMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('This feature is coming soon!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showEditProfileDialog(BuildContext context, User user) async {
    final nameController = TextEditingController(text: user.name);
    final emailController = TextEditingController(text: user.email);
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    String? errorMessage;
    bool isLoading = false;

    await showDialog(
      context: context,
      builder:
          (dialogContext) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: const Text('Edit Profile'),
                  content: Form(
                    key: formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (errorMessage != null)
                            Container(
                              padding: const EdgeInsets.all(8),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                errorMessage ?? '',
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          TextFormField(
                            controller: nameController,
                            decoration: const InputDecoration(
                              labelText: 'Name',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: emailController,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!RegExp(
                                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                              ).hasMatch(value)) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: passwordController,
                            decoration: const InputDecoration(
                              labelText:
                                  'New Password (leave blank to keep current)',
                              prefixIcon: Icon(Icons.lock_outline),
                            ),
                            obscureText: true,
                            validator: (value) {
                              if (value != null &&
                                  value.isNotEmpty &&
                                  value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text('Cancel'),
                    ),
                    if (isLoading)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    else
                      TextButton(
                        onPressed: () async {
                          if (formKey.currentState!.validate()) {
                            setState(() {
                              isLoading = true;
                              errorMessage = null;
                            });

                            final result = await AuthService().updateProfile(
                              user.id,
                              name: nameController.text,
                              email: emailController.text,
                              newPassword:
                                  passwordController.text.isEmpty
                                      ? null
                                      : passwordController.text,
                            );

                            setState(() {
                              isLoading = false;
                            });

                            if (result == null) {
                              setState(() {
                                errorMessage =
                                    'Update failed. Email may already be in use.';
                              });
                            } else {
                              if (dialogContext.mounted) {
                                Navigator.of(dialogContext).pop(true);
                              }
                            }
                          }
                        },
                        child: const Text('Save'),
                      ),
                  ],
                ),
          ),
    ).then((updated) {
      if (updated == true) {
        // Refresh the page
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  Future<void> _logout(BuildContext context) async {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Sign Out'),
            content: const Text('Are you sure you want to sign out?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();

                  // Show loading
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Signing out...'),
                      duration: Duration(seconds: 1),
                    ),
                  );

                  // Perform complete logout
                  await AuthService().logout();

                  // Clear any cached preferences
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('theme_mode');
                  await prefs.remove('save_links_history');
                  await prefs.remove('default_platform');
                  await prefs.remove('show_qr_by_default');

                  // Navigate to login screen with a slight delay to ensure all resources are properly disposed
                  if (context.mounted) {
                    // Use Future.delayed to ensure all resources are properly disposed before navigation
                    Future.delayed(const Duration(milliseconds: 100), () {
                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                          (route) => false,
                        );
                      }
                    });
                  }
                },
                child: const Text('Sign Out'),
              ),
            ],
          ),
    );
  }

  Widget _buildSubscriptionTile(BuildContext context, User user) {
    final tier = user.subscriptionTier;
    final isActive = user.hasActiveSubscription;
    String tierName;

    switch (tier) {
      case SubscriptionTier.free:
        tierName = 'Free';
        break;
      case SubscriptionTier.basic:
        tierName = 'Basic';
        break;
      case SubscriptionTier.professional:
        tierName = 'Professional';
        break;
      case SubscriptionTier.enterprise:
        tierName = 'Enterprise';
        break;
    }

    // Check if user has premium subscription but no teams
    final bool isPremiumWithNoTeams =
        tier != SubscriptionTier.free && isActive && (user.teamIds.isEmpty);

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getSubscriptionColor(tier).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getSubscriptionIcon(tier),
                color: _getSubscriptionColor(tier),
                size: 24,
              ),
            ),
            title: const Text(
              'Subscription Plan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            subtitle: Row(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _getSubscriptionColor(tier),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    tierName,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (tier != SubscriptionTier.free)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isActive ? 'Active' : 'Expired',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SubscriptionScreen(),
                ),
              );
            },
          ),
        ),

        // Show create team button for premium users with no teams
        if (isPremiumWithNoTeams)
          Container(
            margin: const EdgeInsets.only(top: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade50, Colors.blue.shade100],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.info_outline,
                          color: Colors.blue,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'You have a premium subscription but haven\'t created any teams yet',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Teams allow you to collaborate with others and share links',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, '/teams');
                      },
                      icon: const Icon(Icons.group_add),
                      label: const Text('Create Your First Team'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Color _getSubscriptionColor(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return Colors.grey;
      case SubscriptionTier.basic:
        return Colors.blue;
      case SubscriptionTier.professional:
        return Colors.purple;
      case SubscriptionTier.enterprise:
        return Colors.orange;
    }
  }

  IconData _getSubscriptionIcon(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return Icons.workspace_premium;
      case SubscriptionTier.basic:
        return Icons.card_membership;
      case SubscriptionTier.professional:
        return Icons.verified;
      case SubscriptionTier.enterprise:
        return Icons.diamond;
    }
  }

  Future<void> _showSyncUsersDialog(BuildContext context) async {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    return showDialog(
      context: context,
      builder:
          (dialogContext) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: const Text('Sync Users with Supabase'),
                  content: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Enter admin credentials to sync local users with Supabase. '
                          'This will create accounts for all local users.',
                          style: TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: emailController,
                          decoration: const InputDecoration(
                            labelText: 'Admin Email',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter admin email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: passwordController,
                          decoration: const InputDecoration(
                            labelText: 'Admin Password',
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter admin password';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Cancel'),
                    ),
                    if (isLoading)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    else
                      ElevatedButton(
                        onPressed: () async {
                          if (formKey.currentState!.validate()) {
                            setState(() {
                              isLoading = true;
                            });

                            try {
                              final results = await AuthService()
                                  .syncLocalUsersWithSupabase(
                                    adminEmail: emailController.text,
                                    adminPassword: passwordController.text,
                                  );

                              setState(() {
                                isLoading = false;
                              });

                              if (dialogContext.mounted) {
                                Navigator.pop(dialogContext);
                                _showSyncResultsDialog(context, results);
                              }
                            } catch (e) {
                              setState(() {
                                isLoading = false;
                              });

                              if (dialogContext.mounted) {
                                ScaffoldMessenger.of(
                                  dialogContext,
                                ).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: ${e.toString()}'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          }
                        },
                        child: const Text('Sync Users'),
                      ),
                  ],
                ),
          ),
    );
  }

  void _showSyncResultsDialog(
    BuildContext context,
    Map<String, dynamic> results,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Sync Results'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total users: ${results['total']}'),
                  Text('Successfully synced: ${results['success']}'),
                  Text('Failed: ${results['failed']}'),
                  Text('Skipped: ${results['skipped']}'),
                  if (results.containsKey('error'))
                    Text(
                      'Error: ${results['error']}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  const SizedBox(height: 16),
                  if ((results['details'] as List).isNotEmpty) ...[
                    const Text(
                      'Details:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...((results['details'] as List).map(
                      (detail) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _getSyncStatusColor(detail['status']),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Email: ${detail['email']}'),
                            Text('Status: ${detail['status']}'),
                            if (detail.containsKey('reason'))
                              Text('Reason: ${detail['reason']}'),
                            if (detail.containsKey('newId'))
                              Text('New ID: ${detail['newId']}'),
                          ],
                        ),
                      ),
                    )),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  Color _getSyncStatusColor(String status) {
    switch (status) {
      case 'success':
        return Colors.green.shade50;
      case 'failed':
        return Colors.red.shade50;
      case 'skipped':
        return Colors.yellow.shade50;
      case 'error':
        return Colors.orange.shade50;
      default:
        return Colors.grey.shade50;
    }
  }

  // Show dialog to confirm account deletion
  void _showDeleteAccountDialog(BuildContext context, User user) {
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    showDialog(
      context: context,
      builder:
          (dialogContext) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: const Text('Delete Account'),
                  content: SingleChildScrollView(
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Warning: This action cannot be undone. All your data will be permanently deleted.',
                            style: TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Please enter your password to confirm deletion:',
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: passwordController,
                            decoration: const InputDecoration(
                              labelText: 'Password',
                              prefixIcon: Icon(Icons.lock_outline),
                            ),
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Cancel'),
                    ),
                    if (isLoading)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    else
                      ElevatedButton(
                        onPressed: () async {
                          if (formKey.currentState!.validate()) {
                            setState(() {
                              isLoading = true;
                            });

                            try {
                              final success = await AuthService().deleteAccount(
                                user.id,
                                password: passwordController.text,
                              );

                              if (success) {
                                // Close the dialog
                                if (dialogContext.mounted) {
                                  Navigator.pop(dialogContext);
                                }

                                // Navigate to login screen
                                if (context.mounted) {
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const LoginScreen(),
                                    ),
                                    (route) => false,
                                  );

                                  // Show success message
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Account deleted successfully',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } else {
                                setState(() {
                                  isLoading = false;
                                });

                                if (dialogContext.mounted) {
                                  ScaffoldMessenger.of(
                                    dialogContext,
                                  ).showSnackBar(
                                    const SnackBar(
                                      content: Text('Incorrect password'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            } catch (e) {
                              setState(() {
                                isLoading = false;
                              });

                              if (dialogContext.mounted) {
                                ScaffoldMessenger.of(
                                  dialogContext,
                                ).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: ${e.toString()}'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text('Delete Account'),
                      ),
                  ],
                ),
          ),
    );
  }

  // Add new method to build guest login section
  Widget _buildGuestLoginSection(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Account'),
            const SizedBox(height: 8),
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.grey.withOpacity(0.2),
                  child: const Icon(
                    Icons.person_outline,
                    size: 30,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Guest User',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'You are currently using the app as a guest',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Limited Features',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.deepOrange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Sign in or create an account to access all features:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            _buildFeatureList(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _navigateToLogin(context),
                    icon: const Icon(Icons.login),
                    label: const Text('Sign In'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _navigateToRegister(context),
                    icon: const Icon(Icons.person_add),
                    label: const Text('Sign Up'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureList() {
    return Column(
      children: [
        _buildFeatureItem('Save your link history'),
        _buildFeatureItem('Sync across devices'),
        _buildFeatureItem('Create teams and share links'),
        _buildFeatureItem('Access advanced analytics'),
        _buildFeatureItem('Use API for integrations'),
      ],
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle,
            color: AppTheme.primaryColor,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }

  void _navigateToLogin(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  void _navigateToRegister(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const RegisterScreen()));
  }

  Widget _buildProfileActionButtons(BuildContext context, User user) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showEditProfileDialog(context, user),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit Profile'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _showDeleteAccountDialog(context, user),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete Account'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // New method to build consistent action cards
  Widget _buildSettingsActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // New method for sign out button with better design
  Widget _buildSignOutButton(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade400, Colors.red.shade600],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _logout(context),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.logout, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Sign Out',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // New method to build the About section with improved design
  Widget _buildAboutCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAboutItem(
              title: 'Version',
              subtitle: AppConstants.appVersion,
              icon: Icons.info_outline,
              iconColor: Colors.blue,
            ),
            const Divider(height: 32),
            _buildAboutItem(
              title: 'Privacy Policy',
              subtitle: 'Read our privacy policy',
              icon: Icons.privacy_tip_outlined,
              iconColor: Colors.green,
              onTap: (context) => _showComingSoonMessage(context),
            ),
            const Divider(height: 32),
            _buildAboutItem(
              title: 'Terms of Service',
              subtitle: 'Read our terms of service',
              icon: Icons.gavel_outlined,
              iconColor: Colors.orange,
              onTap: (context) => _showComingSoonMessage(context),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build individual about items
  Widget _buildAboutItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    Function(BuildContext)? onTap,
  }) {
    return Builder(
      builder: (context) {
        return InkWell(
          onTap: onTap != null ? () => onTap(context) : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                if (onTap != null)
                  Icon(Icons.chevron_right, color: Colors.grey[400]),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Helper methods for settings
Future<void> _loadAll({
  required ValueNotifier<ThemeMode> themeMode,
  required ValueNotifier<bool> saveLinksHistory,
  required ValueNotifier<String> defaultPlatform,
  required ValueNotifier<bool> showQrByDefault,
  required ValueNotifier<User?> currentUser,
  required Function(bool) setLoading,
}) async {
  try {
    // Load user
    currentUser.value = await AuthService().getCurrentUser();

    // Load preferences
    final prefs = await SharedPreferences.getInstance();

    // Load theme mode
    final themeModeStr = prefs.getString('theme_mode') ?? 'system';
    themeMode.value = _parseThemeMode(themeModeStr);

    // Load other settings
    saveLinksHistory.value = prefs.getBool('save_links_history') ?? true;
    defaultPlatform.value = prefs.getString('default_platform') ?? 'whatsapp';
    showQrByDefault.value = prefs.getBool('show_qr_by_default') ?? false;

    setLoading(false);
  } catch (e) {
    setLoading(false);
    print('Error loading settings: $e');
  }
}

ThemeMode _parseThemeMode(String value) {
  switch (value) {
    case 'light':
      return ThemeMode.light;
    case 'dark':
      return ThemeMode.dark;
    case 'system':
    default:
      return ThemeMode.system;
  }
}

Future<void> _saveThemeMode(ThemeMode mode) async {
  final prefs = await SharedPreferences.getInstance();
  String value;

  switch (mode) {
    case ThemeMode.light:
      value = 'light';
      break;
    case ThemeMode.dark:
      value = 'dark';
      break;
    case ThemeMode.system:
      value = 'system';
      break;
  }

  await prefs.setString('theme_mode', value);
}

Future<void> _saveBoolSetting(String key, bool value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(key, value);
}

Future<void> _saveStringSetting(String key, String value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(key, value);
}
