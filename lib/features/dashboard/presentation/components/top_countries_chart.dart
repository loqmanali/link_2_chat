import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:link_2_chat/core/design/app_context.dart';
import 'package:link_2_chat/core/design/app_radii.dart';
import 'package:link_2_chat/core/design/app_spacing.dart';
import 'package:link_2_chat/features/dashboard/application/dashboard_providers.dart';
import 'package:link_2_chat/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// The most-used countries as horizontal bars with their counts. The
/// pre-refactor pie chart, as plain bars: the dial code and the count are the
/// information, the slice colours were not.
class TopCountriesChart extends ConsumerWidget {
  const TopCountriesChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    final countries = ref.watch(
      dashboardControllerProvider.select((s) => s.topCountries),
    );
    final isEmpty = countries.isEmpty;

    return Container(
      padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: colors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.dashboardTopCountries,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colors.text,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 160,
            child:
                isEmpty
                    ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.public, size: 48, color: colors.line),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            l10n.dashboardNoData,
                            style: TextStyle(
                              fontSize: 14,
                              color: colors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    )
                    : Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        for (final country in countries)
                          _CountryBar(
                            dialCode: country.key,
                            count: country.value,
                            max: countries.first.value,
                          ),
                      ],
                    ),
          ),
        ],
      ),
    );
  }
}

/// One bar: the dial code, a proportional fill, and the count.
class _CountryBar extends StatelessWidget {
  const _CountryBar({
    required this.dialCode,
    required this.count,
    required this.max,
  });

  final String dialCode;
  final int count;
  final int max;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final fill = max <= 0 ? 0.0 : count / max;
    return Row(
      children: [
        SizedBox(
          width: 48,
          child: Text(
            dialCode,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: colors.textMuted,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.sm),
            child: LinearProgressIndicator(
              value: fill.clamp(0.0, 1.0),
              minHeight: 12,
              backgroundColor: colors.page,
              valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        SizedBox(
          width: 32,
          child: Text(
            '$count',
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: colors.text,
            ),
          ),
        ),
      ],
    );
  }
}
