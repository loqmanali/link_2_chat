import 'package:link_2_chat/features/auth/auth.dart' show SubscriptionTier;

/// One row of the plan catalog, carried over from the pre-refactor app: the
/// tier, its monthly price and whether the card is highlighted. The feature
/// and limitation copy lives in the presentation layer, which maps each tier
/// to its l10n sentences.
class Plan {
  const Plan({
    required this.tier,
    required this.monthlyPriceUsd,
    this.popular = false,
  });

  final SubscriptionTier tier;

  /// The advertised monthly price in dollars (the price sentences in l10n
  /// spell it out, so this is the catalog's source of truth, not display
  /// text).
  final double monthlyPriceUsd;

  /// The highlighted card gets a POPULAR badge.
  final bool popular;
}

/// The catalog in display order, cheapest first.
const List<Plan> planCatalog = [
  Plan(tier: SubscriptionTier.free, monthlyPriceUsd: 0),
  Plan(tier: SubscriptionTier.basic, monthlyPriceUsd: 4.99, popular: true),
  Plan(tier: SubscriptionTier.professional, monthlyPriceUsd: 9.99),
  Plan(tier: SubscriptionTier.enterprise, monthlyPriceUsd: 29.99),
];
