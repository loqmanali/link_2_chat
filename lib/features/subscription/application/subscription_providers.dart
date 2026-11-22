import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:link_2_chat/core/api/failure.dart';
import 'package:link_2_chat/core/session/session_providers.dart';
import 'package:link_2_chat/features/auth/auth.dart';
import 'package:link_2_chat/features/subscription/domain/plan.dart';

/// The signed-in account's row of the catalog. Null for a guest or a
/// signed-out visitor — they have no account row to read a tier from.
final currentPlanProvider = Provider<Plan?>((ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return null;
  return planCatalog.firstWhere((plan) => plan.tier == user.subscriptionTier);
});

/// Moves the signed-in account to [tier]. The expiry stays null — the local
/// plans do not lapse, matching the device-local behavior. Guests and
/// signed-out visitors have no account to bill: [AuthFailure].
final changePlanActionProvider = AsyncNotifierProvider<ChangePlanAction, void>(
  ChangePlanAction.new,
  retry: (_, _) => null,
);

class ChangePlanAction extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> changeTo(SubscriptionTier tier) async {
    state = await AsyncValue.guard(() async {
      final session = ref.read(sessionControllerProvider);
      if (session == null || session.isGuest) {
        throw const AuthFailure('No signed-in account.');
      }
      await ref
          .read(usersStoreProvider)
          .updateSubscription(session.userId, tier, null);
    });
  }
}
