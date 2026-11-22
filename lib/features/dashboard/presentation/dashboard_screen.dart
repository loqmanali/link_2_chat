import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:link_2_chat/core/design/app_spacing.dart';
import 'package:link_2_chat/core/design/components/app_state_view.dart';
import 'package:link_2_chat/core/ui/failure_message.dart';
import 'package:link_2_chat/core/ui/failure_toast.dart';
import 'package:link_2_chat/features/dashboard/application/dashboard_providers.dart';
import 'package:link_2_chat/features/dashboard/presentation/components/platform_distribution.dart';
import 'package:link_2_chat/features/dashboard/presentation/components/recent_activity.dart';
import 'package:link_2_chat/features/dashboard/presentation/components/summary_card.dart';
import 'package:link_2_chat/features/dashboard/presentation/components/top_countries_chart.dart';
import 'package:link_2_chat/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// The usage counters tab: summary card, platform stats, top countries and
/// the recent activity, all live from the local store. A tab child: the shell
/// owns the scaffold and the bottom bar.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardControllerProvider);
    ref.listen(dashboardControllerProvider, (previous, next) {
      final error = next.error;
      if (previous?.error == null && error != null) {
        showFailureToast(context, error);
      }
    });

    if (state.isLoading) return const AppStateView.loading();
    if (state.error != null && state.totalLinks == 0) {
      final l10n = AppLocalizations.of(context);
      return AppStateView.error(
        message: l10n.dashboardError(failureMessage(l10n, state.error!)),
        retryLabel: l10n.commonRetry,
        onRetry: () => ref.invalidate(dashboardControllerProvider),
      );
    }

    return const SingleChildScrollView(
      padding: EdgeInsetsDirectional.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SummaryCard(),
          SizedBox(height: AppSpacing.xl),
          PlatformDistribution(),
          SizedBox(height: AppSpacing.xl),
          TopCountriesChart(),
          SizedBox(height: AppSpacing.xl),
          RecentActivityList(),
          SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}
