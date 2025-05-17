import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config/app_theme.dart';
import '../../core/services/auth_service.dart';
import '../../main_screen.dart';
import '../../widgets/loading_indicator.dart';
import 'register_screen.dart';

class LoginScreen extends HookWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final isLoading = useState(false);
    final errorMessage = useState<String?>(null);
    final formKey = useMemoized(() => GlobalKey<FormState>());

    // Check if user is already logged in
    useEffect(() {
      _checkCurrentUser(context);
      return null;
    }, []);

    return Scaffold(
      body: LoadingOverlay(
        isLoading: isLoading.value,
        message: 'Logging in...',
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 60),
                  // App logo and title
                  Center(
                    child: Column(
                      children: [
                        const Icon(
                          Icons.link,
                          size: 80,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Link2Chat',
                          style: AppTheme.headlineStyle.copyWith(
                            color: AppTheme.primaryColor,
                            fontSize: 32,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Convert phone numbers to chat links',
                          style: AppTheme.captionStyle,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 60),

                  // Error message
                  if (errorMessage.value != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        errorMessage.value!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  if (errorMessage.value != null) const SizedBox(height: 16),

                  // Email field
                  TextFormField(
                    controller: emailController,
                    decoration: AppTheme.inputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
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

                  // Password field
                  TextFormField(
                    controller: passwordController,
                    decoration: AppTheme.inputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Login button
                  ElevatedButton(
                    onPressed:
                        () => _login(
                          context,
                          emailController.text,
                          passwordController.text,
                          isLoading,
                          errorMessage,
                          formKey,
                        ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Login', style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(height: 16),

                  // Register link
                  Center(
                    child: TextButton(
                      onPressed: () => _navigateToRegister(context),
                      child: const Text('Don\'t have an account? Register'),
                    ),
                  ),

                  // Skip for now (demo mode)
                  const SizedBox(height: 36),
                  OutlinedButton(
                    onPressed: () => _skipLogin(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Continue as Guest'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _login(
    BuildContext context,
    String email,
    String password,
    ValueNotifier<bool> isLoading,
    ValueNotifier<String?> errorMessage,
    GlobalKey<FormState> formKey,
  ) async {
    // Clear previous error
    errorMessage.value = null;

    // Validate form
    if (!formKey.currentState!.validate()) {
      return;
    }

    // Show loading
    isLoading.value = true;

    // Try to login with both Supabase and local database
    final user = await AuthService().loginWithSupabase(email, password);

    // Hide loading
    isLoading.value = false;

    if (user == null) {
      // Login failed
      errorMessage.value = 'Invalid email or password';
      return;
    }

    // Login successful, navigate to home
    if (context.mounted) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const MainScreen()));
    }
  }

  Future<void> _checkCurrentUser(BuildContext context) async {
    final user = await AuthService().getCurrentUser();

    if (user != null && context.mounted) {
      // User is already logged in, navigate to home
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const MainScreen()));
    }
  }

  void _navigateToRegister(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const RegisterScreen()));
  }

  void _skipLogin(BuildContext context) {
    // For guest users, allow using the app with very limited functionality
    // Store in shared preferences that this is a guest user with limited attempts
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('is_guest_user', true);
      prefs.setInt('guest_link_count', 0); // Initialize link count for guest
    });

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const MainScreen()));
  }
}
