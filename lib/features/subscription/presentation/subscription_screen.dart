import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:link_2_chat/core/design/app_context.dart';
import 'package:link_2_chat/core/design/app_radii.dart';
import 'package:link_2_chat/core/design/app_spacing.dart';
import 'package:link_2_chat/core/ui/failure_toast.dart';
import 'package:link_2_chat/features/auth/auth.dart';
import 'package:link_2_chat/features/subscription/application/subscription_providers.dart';
import 'package:link_2_chat/features/subscription/domain/plan.dart';
import 'package:link_2_chat/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// The plans screen: the account's current plan, the four-tier catalog and
/// the simulated payment / downgrade confirmations. The plan change itself
/// lives in [changePlanActionProvider]; the card list re-renders from the
/// account row once the store write lands.
class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  void _changePlan(Plan plan) {
    final l10n = AppLocalizations.of(context);
    final currentTier = ref.read(currentUserProvider).value?.subscriptionTier;
    if (currentTier == null || currentTier == plan.tier) return;
    final upgrading = _tierRank(currentTier) < _tierRank(plan.tier);
    if (upgrading) {
      _showPaymentDialog(l10n, plan);
    } else {
      _showConfirmDialog(l10n, plan, downgrade: true);
    }
  }

  /// The upgrade path pretends to take a payment first, exactly like the
  /// pre-refactor demo.
  void _showPaymentDialog(AppLocalizations l10n, Plan plan) {
    showDialog<void>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text(l10n.subscriptionPaymentTitle),
            content: Text(l10n.subscriptionPaymentMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(l10n.commonCancel),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  _apply(plan);
                },
                child: Text(l10n.subscriptionSimulatePayment),
              ),
            ],
          ),
    );
  }

  void _showConfirmDialog(
    AppLocalizations l10n,
    Plan plan, {
    required bool downgrade,
  }) {
    final planName = _tierName(l10n, plan.tier);
    showDialog<void>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text(
              downgrade
                  ? l10n.subscriptionDowngradeTitle
                  : l10n.subscriptionChangeTitle,
            ),
            content: Text(
              downgrade
                  ? l10n.subscriptionDowngradeMessage(planName)
                  : l10n.subscriptionChangeMessage(planName),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(l10n.commonCancel),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  _apply(plan);
                },
                child: Text(
                  downgrade
                      ? l10n.subscriptionDowngrade
                      : l10n.subscriptionChange,
                ),
              ),
            ],
          ),
    );
  }

  void _apply(Plan plan) {
    ref.read(changePlanActionProvider.notifier).changeTo(plan.tier);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(currentUserProvider).value;
    ref.listen(changePlanActionProvider, (previous, next) {
      if (isFreshFailure(next)) showFailureToast(context, next.error!);
    });
    return Scaffold(
      appBar: AppBar(title: Text(l10n.subscriptionTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (user != null) _CurrentPlanBanner(user: user),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.subscriptionChoosePlan,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            for (final plan in planCatalog) ...[
              const SizedBox(height: AppSpacing.lg),
              _PlanCard(
                plan: plan,
                currentTier: user?.subscriptionTier,
                onChanged: () => _changePlan(plan),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            Text(
              l10n.subscriptionContactUs,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// The account banner at the top of the screen: the tier, when it expires,
/// whether it counts as active and whether the tier may open teams.
class _CurrentPlanBanner extends StatelessWidget {
  const _CurrentPlanBanner({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    final expiry = user.subscriptionExpiry;
    final active = expiry == null || expiry.isAfter(DateTime.now());
    final tier = user.subscriptionTier;
    return Card(
      color: colors.card,
      child: Padding(
        padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  active ? Icons.check_circle : Icons.warning_amber,
                  color: active ? colors.success : colors.accent,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    l10n.subscriptionCurrentPlanLabel(_tierName(l10n, tier)),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            if (tier != SubscriptionTier.free) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                expiry == null
                    ? l10n.subscriptionNoExpiry
                    : l10n.subscriptionExpiryLabel(_formatDate(expiry)),
                style: TextStyle(fontSize: 14, color: colors.textMuted),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.subscriptionStatusLabel(
                active ? l10n.subscriptionActive : l10n.subscriptionExpired,
              ),
              style: TextStyle(fontSize: 14, color: colors.textMuted),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.subscriptionTeamsFeatureLabel(
                tier == SubscriptionTier.free
                    ? l10n.subscriptionNotAvailable
                    : l10n.subscriptionAvailable,
              ),
              style: TextStyle(fontSize: 14, color: colors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

/// One plan card: header, features, limitations (free only) and the action
/// button. The popular tier gets a highlighted border and a POPULAR badge.
class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.currentTier,
    required this.onChanged,
  });

  final Plan plan;
  final SubscriptionTier? currentTier;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    final isCurrent = currentTier == plan.tier;
    final actionLabel = _actionLabel(currentTier, plan.tier);
    final actionColor = switch (actionLabel) {
      _SubscriptionAction.upgrade => colors.success,
      _SubscriptionAction.downgrade => colors.accent,
      _ => colors.primary,
    };
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Card(
          color: colors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
            side: BorderSide(
              color: plan.popular ? colors.primary : colors.line,
              width: plan.popular ? 2 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _tierName(l10n, plan.tier),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _price(l10n, plan.tier),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: plan.popular ? colors.primary : colors.text,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                        bottom: AppSpacing.xs,
                      ),
                      child: Text(
                        _period(l10n, plan.tier),
                        style: TextStyle(fontSize: 14, color: colors.textMuted),
                      ),
                    ),
                  ],
                ),
                const Divider(height: AppSpacing.xxl),
                _PlanList(
                  heading: l10n.subscriptionFeaturesHeading,
                  entries: _featuresFor(l10n, plan.tier),
                  icon: Icons.check_circle,
                  iconColor: colors.success,
                ),
                if (_limitationsFor(l10n, plan.tier).isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _PlanList(
                    heading: l10n.subscriptionLimitationsHeading,
                    entries: _limitationsFor(l10n, plan.tier),
                    icon: Icons.remove_circle,
                    iconColor: colors.danger,
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: isCurrent ? null : onChanged,
                    style: FilledButton.styleFrom(
                      backgroundColor: actionColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                      ),
                    ),
                    child: Text(switch (actionLabel) {
                      _SubscriptionAction.current =>
                        l10n.subscriptionCurrentPlan,
                      _SubscriptionAction.upgrade => l10n.subscriptionUpgrade,
                      _SubscriptionAction.downgrade =>
                        l10n.subscriptionDowngrade,
                      _SubscriptionAction.subscribe =>
                        l10n.subscriptionSubscribe,
                    }, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (plan.popular)
          PositionedDirectional(
            top: 0,
            end: AppSpacing.lg,
            child: Container(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(AppRadii.sm),
                ),
              ),
              child: Text(
                l10n.subscriptionPopularBadge,
                style: TextStyle(
                  color: colors.onPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// A titled bullet list inside a plan card (features or limitations).
class _PlanList extends StatelessWidget {
  const _PlanList({
    required this.heading,
    required this.entries,
    required this.icon,
    required this.iconColor,
  });

  final String heading;
  final List<String> entries;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          heading,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final entry in entries)
          Padding(
            padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.sm),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 18),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    entry,
                    style: TextStyle(fontSize: 14, color: colors.text),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Which sentence the plan card's button carries.
enum _SubscriptionAction { current, upgrade, downgrade, subscribe }

_SubscriptionAction _actionLabel(
  SubscriptionTier? currentTier,
  SubscriptionTier planTier,
) {
  if (currentTier == planTier) return _SubscriptionAction.current;
  if (currentTier == null) return _SubscriptionAction.subscribe;
  return _tierRank(currentTier) < _tierRank(planTier)
      ? _SubscriptionAction.upgrade
      : _SubscriptionAction.downgrade;
}

/// The tier order used to tell an upgrade from a downgrade.
int _tierRank(SubscriptionTier tier) => switch (tier) {
  SubscriptionTier.free => 0,
  SubscriptionTier.basic => 1,
  SubscriptionTier.professional => 2,
  SubscriptionTier.enterprise => 3,
};

/// The plan name in the app language.
String _tierName(AppLocalizations l10n, SubscriptionTier tier) =>
    switch (tier) {
      SubscriptionTier.free => l10n.subscriptionTierFree,
      SubscriptionTier.basic => l10n.subscriptionTierBasic,
      SubscriptionTier.professional => l10n.subscriptionTierProfessional,
      SubscriptionTier.enterprise => l10n.subscriptionTierEnterprise,
    };

/// The price sentence in the app language (the l10n catalog spells it out).
String _price(AppLocalizations l10n, SubscriptionTier tier) => switch (tier) {
  SubscriptionTier.free => l10n.subscriptionPriceFree,
  SubscriptionTier.basic => l10n.subscriptionPriceBasic,
  SubscriptionTier.professional => l10n.subscriptionPriceProfessional,
  SubscriptionTier.enterprise => l10n.subscriptionPriceEnterprise,
};

/// Free is billed forever; the paid tiers are monthly.
String _period(AppLocalizations l10n, SubscriptionTier tier) =>
    tier == SubscriptionTier.free
        ? l10n.subscriptionForever
        : l10n.subscriptionPerMonth;

/// The marketing copy per tier, with the limits carried over from the
/// pre-refactor catalog (teams: 5 / 20 / 100, history: 50 / 500 / 5000 /
/// 50000).
List<String> _featuresFor(AppLocalizations l10n, SubscriptionTier tier) =>
    switch (tier) {
      SubscriptionTier.free => [
        l10n.subscriptionFreeFeature1,
        l10n.subscriptionFreeFeatureHistory(50),
        l10n.subscriptionFreeFeatureAnalytics,
      ],
      SubscriptionTier.basic => [
        l10n.subscriptionEverythingInFree,
        l10n.subscriptionTeamLimit(5),
        l10n.subscriptionHistoryLimit(500),
        l10n.subscriptionPrioritySupport,
      ],
      SubscriptionTier.professional => [
        l10n.subscriptionEverythingInBasic,
        l10n.subscriptionTeamLimit(20),
        l10n.subscriptionAdvancedAnalytics,
        l10n.subscriptionApiAccess,
        l10n.subscriptionHistoryLimit(5000),
      ],
      SubscriptionTier.enterprise => [
        l10n.subscriptionEverythingInProfessional,
        l10n.subscriptionUnlimitedMembers(100),
        l10n.subscriptionCustomBranding,
        l10n.subscriptionPremiumSupport,
        l10n.subscriptionExtendedApi,
        l10n.subscriptionHistoryLimit(50000),
      ],
    };

/// Only the free tier advertises what it cannot do.
List<String> _limitationsFor(AppLocalizations l10n, SubscriptionTier tier) =>
    tier == SubscriptionTier.free
        ? [
          l10n.subscriptionFreeNoTeams,
          l10n.subscriptionFreeNoAnalytics,
          l10n.subscriptionFreeNoApi,
        ]
        : const [];

/// The yyyy-MM-dd form the pre-refactor screen showed.
String _formatDate(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';
