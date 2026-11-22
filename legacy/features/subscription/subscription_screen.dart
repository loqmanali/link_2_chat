import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../core/models/user.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/supabase_service.dart';
import '../../widgets/app_bar.dart';
import 'components/subscription_card.dart';
import 'subscription_viewmodel.dart';

class SubscriptionScreen extends HookWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final subscriptionBloc = useMemoized(() => SubscriptionBloc(), []);
    final isLoading = useState(true);
    final currentUser = useState<User?>(null);
    final authService = useMemoized(() => AuthService(), []);

    // Load user data
    useEffect(() {
      _loadUserData(authService, currentUser, isLoading);
      return () {
        subscriptionBloc.close();
      };
    }, []);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Subscription Plans'),
      body:
          isLoading.value
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (currentUser.value != null)
                      _buildSubscriptionInfoCard(context, currentUser.value!),
                    const SizedBox(height: 16),
                    const Text(
                      'Choose a Plan',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SubscriptionCard(
                      title: 'Free',
                      price: '\$0',
                      period: 'forever',
                      features: [
                        'Basic link generation',
                        'Limited history (${SubscriptionTier.free.maxHistoryItems} items)',
                        'Basic analytics',
                      ],
                      limitations: [
                        'No team features',
                        'No advanced analytics',
                        'No API access',
                      ],
                      isCurrentPlan:
                          currentUser.value?.subscriptionTier ==
                          SubscriptionTier.free,
                      buttonText:
                          currentUser.value?.subscriptionTier ==
                                  SubscriptionTier.free
                              ? 'Current Plan'
                              : 'Downgrade',
                      onPressed:
                          currentUser.value?.subscriptionTier ==
                                  SubscriptionTier.free
                              ? null
                              : () => _confirmPlanChange(
                                context,
                                subscriptionBloc,
                                SubscriptionTier.free,
                                currentUser,
                                isLoading,
                              ),
                    ),
                    const SizedBox(height: 16),
                    SubscriptionCard(
                      title: 'Basic',
                      price: '\$4.99',
                      period: 'per month',
                      features: [
                        'Everything in Free',
                        'Create up to ${SubscriptionTier.basic.maxTeamMembers} member teams',
                        'Extended history (${SubscriptionTier.basic.maxHistoryItems} items)',
                        'Priority support',
                      ],
                      isCurrentPlan:
                          currentUser.value?.subscriptionTier ==
                          SubscriptionTier.basic,
                      buttonText: _getButtonText(
                        currentUser.value?.subscriptionTier,
                        SubscriptionTier.basic,
                      ),
                      isPopular: true,
                      onPressed:
                          currentUser.value?.subscriptionTier ==
                                  SubscriptionTier.basic
                              ? null
                              : () => _handleSubscription(
                                context,
                                subscriptionBloc,
                                SubscriptionTier.basic,
                                currentUser,
                                isLoading,
                              ),
                    ),
                    const SizedBox(height: 16),
                    SubscriptionCard(
                      title: 'Professional',
                      price: '\$9.99',
                      period: 'per month',
                      features: [
                        'Everything in Basic',
                        'Create up to ${SubscriptionTier.professional.maxTeamMembers} member teams',
                        'Advanced analytics',
                        'API access for integration',
                        'Extended history (${SubscriptionTier.professional.maxHistoryItems} items)',
                      ],
                      isCurrentPlan:
                          currentUser.value?.subscriptionTier ==
                          SubscriptionTier.professional,
                      buttonText: _getButtonText(
                        currentUser.value?.subscriptionTier,
                        SubscriptionTier.professional,
                      ),
                      onPressed:
                          currentUser.value?.subscriptionTier ==
                                  SubscriptionTier.professional
                              ? null
                              : () => _handleSubscription(
                                context,
                                subscriptionBloc,
                                SubscriptionTier.professional,
                                currentUser,
                                isLoading,
                              ),
                    ),
                    const SizedBox(height: 16),
                    SubscriptionCard(
                      title: 'Enterprise',
                      price: '\$29.99',
                      period: 'per month',
                      features: [
                        'Everything in Professional',
                        'Unlimited team members (up to ${SubscriptionTier.enterprise.maxTeamMembers})',
                        'Custom branding',
                        'Premium support',
                        'Extended API features',
                        'Extended history (${SubscriptionTier.enterprise.maxHistoryItems} items)',
                      ],
                      isCurrentPlan:
                          currentUser.value?.subscriptionTier ==
                          SubscriptionTier.enterprise,
                      buttonText: _getButtonText(
                        currentUser.value?.subscriptionTier,
                        SubscriptionTier.enterprise,
                      ),
                      onPressed:
                          currentUser.value?.subscriptionTier ==
                                  SubscriptionTier.enterprise
                              ? null
                              : () => _handleSubscription(
                                context,
                                subscriptionBloc,
                                SubscriptionTier.enterprise,
                                currentUser,
                                isLoading,
                              ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Need more? Contact us for a custom plan.',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildSubscriptionInfoCard(BuildContext context, User user) {
    final bool isActive = user.hasActiveSubscription;
    final String tierName = user.subscriptionTier.name.toUpperCase();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: isActive ? Colors.green.shade50 : Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isActive ? Icons.check_circle : Icons.warning,
                  color: isActive ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  'Current Plan: $tierName',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (user.subscriptionTier != SubscriptionTier.free)
              Text(
                'Expiry: ${user.subscriptionExpiry != null ? _formatDate(user.subscriptionExpiry!) : 'No expiration date'}',
                style: const TextStyle(fontSize: 14),
              ),
            const SizedBox(height: 8),
            Text(
              'Status: ${isActive ? 'Active' : 'Expired'}',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Teams Feature: ${user.subscriptionTier.canCreateTeams ? 'Available' : 'Not Available'}',
                  style: const TextStyle(fontSize: 14),
                ),
                if (!isActive || user.subscriptionTier == SubscriptionTier.free)
                  TextButton(
                    onPressed: () => _refreshSubscriptionStatus(context, user),
                    child: const Text('Refresh Status'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _refreshSubscriptionStatus(
    BuildContext context,
    User user,
  ) async {
    try {
      final authService = AuthService();
      final supabaseService = SupabaseService();

      // Check if Supabase is initialized
      if (!supabaseService.isInitialized) {
        await supabaseService.initialize();
      }

      // Get fresh user data from Supabase
      if (await supabaseService.isAuthenticated()) {
        final updatedUser = await supabaseService.getCurrentUser();

        if (updatedUser != null) {
          // Update local user data
          final updatedLocalUser = user.copyWith(
            subscriptionTier: updatedUser.subscriptionTier,
            subscriptionExpiry: updatedUser.subscriptionExpiry,
          );

          await authService.updateUser(updatedLocalUser);

          // Show success message
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Subscription status updated successfully'),
                backgroundColor: Colors.green,
              ),
            );

            // Reload page
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
            );
          }
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Unable to refresh subscription status. Please log in again.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating subscription: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getPlanName(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return 'Free';
      case SubscriptionTier.basic:
        return 'Basic';
      case SubscriptionTier.professional:
        return 'Professional';
      case SubscriptionTier.enterprise:
        return 'Enterprise';
    }
  }

  String _getButtonText(
    SubscriptionTier? currentTier,
    SubscriptionTier planTier,
  ) {
    if (currentTier == planTier) return 'Current Plan';

    if (currentTier == null) return 'Subscribe';

    if (_getTierValue(currentTier) < _getTierValue(planTier)) {
      return 'Upgrade';
    } else {
      return 'Downgrade';
    }
  }

  int _getTierValue(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return 0;
      case SubscriptionTier.basic:
        return 1;
      case SubscriptionTier.professional:
        return 2;
      case SubscriptionTier.enterprise:
        return 3;
    }
  }

  Future<void> _loadUserData(
    AuthService authService,
    ValueNotifier<User?> currentUser,
    ValueNotifier<bool> isLoading,
  ) async {
    try {
      isLoading.value = true;
      final user = await authService.getCurrentUser();
      currentUser.value = user;
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void _handleSubscription(
    BuildContext context,
    SubscriptionBloc bloc,
    SubscriptionTier tier,
    ValueNotifier<User?> currentUser,
    ValueNotifier<bool> isLoading,
  ) {
    if (currentUser.value == null) return;

    final currentTier = currentUser.value!.subscriptionTier;

    if (_getTierValue(currentTier) < _getTierValue(tier)) {
      // Upgrading
      _showPaymentDialog(context, bloc, tier, currentUser, isLoading);
    } else {
      // Downgrading
      _confirmPlanChange(context, bloc, tier, currentUser, isLoading);
    }
  }

  void _confirmPlanChange(
    BuildContext context,
    SubscriptionBloc bloc,
    SubscriptionTier tier,
    ValueNotifier<User?> currentUser,
    ValueNotifier<bool> isLoading,
  ) {
    if (currentUser.value == null) return;

    final currentTier = currentUser.value!.subscriptionTier;
    final isDowngrade = _getTierValue(currentTier) > _getTierValue(tier);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(isDowngrade ? 'Downgrade Plan?' : 'Change Plan?'),
            content: Text(
              isDowngrade
                  ? 'Are you sure you want to downgrade to the ${_getPlanName(tier)} plan? You may lose access to some features.'
                  : 'Are you sure you want to change to the ${_getPlanName(tier)} plan?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Update subscription
                  _changePlan(bloc, tier, currentUser, isLoading);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDowngrade ? Colors.orange : Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: Text(isDowngrade ? 'Downgrade' : 'Change'),
              ),
            ],
          ),
    );
  }

  void _showPaymentDialog(
    BuildContext context,
    SubscriptionBloc bloc,
    SubscriptionTier tier,
    ValueNotifier<User?> currentUser,
    ValueNotifier<bool> isLoading,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Complete Your Subscription'),
            content: const Text(
              'In a real application, this would show a payment form using Stripe or PayPal. '
              'For this demo, we\'ll simulate a successful payment.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Update subscription
                  _changePlan(bloc, tier, currentUser, isLoading);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Simulate Payment'),
              ),
            ],
          ),
    );
  }

  Future<void> _changePlan(
    SubscriptionBloc bloc,
    SubscriptionTier tier,
    ValueNotifier<User?> currentUser,
    ValueNotifier<bool> isLoading,
  ) async {
    if (currentUser.value == null) return;

    try {
      isLoading.value = true;

      // In a real app, this would process payment and update the backend
      final now = DateTime.now();
      final expiryDate = now.add(
        const Duration(days: 30),
      ); // 30-day subscription

      final updatedUser = currentUser.value!.copyWith(
        subscriptionTier: tier,
        subscriptionExpiry: tier == SubscriptionTier.free ? null : expiryDate,
      );

      final authService = AuthService();
      final result = await authService.updateUser(updatedUser);

      if (result != null) {
        currentUser.value = result;
      }
    } catch (e) {
      print('Error changing subscription: $e');
      // Show error message
    } finally {
      isLoading.value = false;
    }
  }
}
