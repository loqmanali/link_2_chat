import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/config/app_theme.dart';
import 'core/config/constants.dart';
import 'core/models/api_key.dart';
import 'core/models/phone_entry.dart';
import 'core/models/team.dart';
import 'core/models/user.dart';
import 'core/models/user_stats.dart';
import 'core/services/analytics_service.dart';
import 'core/services/auth_service.dart';
import 'core/services/supabase_service.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/teams/teams_screen.dart';
import 'main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Hive for local storage
  await Hive.initFlutter();

  // Register adapters
  try {
    Hive.registerAdapter(PhoneEntryAdapter());
    Hive.registerAdapter(UserStatsAdapter());
    Hive.registerAdapter(UserAdapter());
    Hive.registerAdapter(SubscriptionTierAdapter());
    Hive.registerAdapter(ApiKeyAdapter());
    Hive.registerAdapter(ApiPermissionAdapter());
    Hive.registerAdapter(TeamAdapter());
    Hive.registerAdapter(TeamMemberAdapter());
    Hive.registerAdapter(TeamRoleAdapter());
    Hive.registerAdapter(TeamPermissionAdapter());
    Hive.registerAdapter(TeamSettingsAdapter());
  } catch (e) {
    print('Error registering Hive adapters: $e');
  }

  // Initialize Supabase
  try {
    await SupabaseService().initialize();
    print('Supabase initialized successfully');
  } catch (e) {
    print('Error initializing Supabase: $e');
    // Continue without Supabase - app will work offline
  }

  // Initialize analytics service (which initializes the sync service)
  await AnalyticsService.init();

  runApp(const MyApp());
}

class MyApp extends HookWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = useState(false);
    final isLoading = useState(true);

    // Check authentication status on app start
    useEffect(() {
      _checkAuthentication(isAuthenticated, isLoading);
      return null;
    }, []);

    return MaterialApp(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home:
          isLoading.value
              ? const _SplashScreen()
              : isAuthenticated.value
              ? const MainScreen()
              : const LoginScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/main': (context) => const MainScreen(),
        '/teams': (context) => const TeamsScreen(),
      },
    );
  }

  Future<void> _checkAuthentication(
    ValueNotifier<bool> isAuthenticated,
    ValueNotifier<bool> isLoading,
  ) async {
    try {
      // Simulate a short delay to show splash screen
      await Future.delayed(const Duration(milliseconds: 1500));

      // Check if user is authenticated with local AuthService
      final user = await AuthService().getCurrentUser();
      isAuthenticated.value = user != null;
    } catch (e) {
      print('Authentication check error: $e');
      isAuthenticated.value = false;
    } finally {
      isLoading.value = false;
    }
  }
}

// Simple splash screen
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.link, size: 80, color: Colors.white),
            const SizedBox(height: 16),
            Text(
              AppConstants.appName,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppConstants.appTagline,
              style: const TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
