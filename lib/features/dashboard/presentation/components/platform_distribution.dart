import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:link_2_chat/core/design/app_colors.dart' show AppColors;
import 'package:link_2_chat/core/design/app_context.dart';
import 'package:link_2_chat/core/design/app_radii.dart';
import 'package:link_2_chat/core/design/app_spacing.dart';
import 'package:link_2_chat/features/dashboard/application/dashboard_providers.dart';
import 'package:link_2_chat/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// The per-platform counters and their pie chart, with the count legend. The
/// pre-refactor stats section; the distribution bar became a pie chart.
class PlatformDistribution extends ConsumerWidget {
  const PlatformDistribution({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    final state = ref.watch(dashboardControllerProvider);

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
            l10n.dashboardStatsTitle,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colors.text,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _StatsCounter(
                  label: l10n.commonWhatsApp,
                  count: state.whatsappLinks,
                  color: colors.whatsapp,
                  icon: Icons.message_rounded,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: _StatsCounter(
                  label: l10n.commonTelegram,
                  count: state.telegramLinks,
                  color: colors.telegram,
                  icon: Icons.send_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.dashboardDistribution,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colors.textMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 180,
            child:
                state.isEmpty
                    ? Center(
                      child: Text(
                        l10n.dashboardNoData,
                        style: TextStyle(fontSize: 14, color: colors.textMuted),
                      ),
                    )
                    : Row(
                      children: [
                        Expanded(
                          child: PieChart(
                            PieChartData(
                              sections: _sections(state, colors),
                              centerSpaceRadius: 40,
                              sectionsSpace: 2,
                              pieTouchData: PieTouchData(enabled: false),
                              borderData: FlBorderData(show: false),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _LegendRow(
                                label: l10n.commonWhatsApp,
                                count: state.whatsappLinks,
                                color: colors.whatsapp,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              _LegendRow(
                                label: l10n.commonTelegram,
                                count: state.telegramLinks,
                                color: colors.telegram,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _sections(DashboardState state, AppColors colors) {
    Color platformColor(bool whatsapp) =>
        whatsapp ? colors.whatsapp : colors.telegram;
    return [
      PieChartSectionData(
        value: state.whatsappLinks.toDouble(),
        color: platformColor(true),
        showTitle: false,
        radius: 48,
      ),
      PieChartSectionData(
        value: state.telegramLinks.toDouble(),
        color: platformColor(false),
        showTitle: false,
        radius: 48,
      ),
    ];
  }
}

/// One labelled count chip (the pre-refactor `StatsCounter`, without its
/// animated ring: the number is the content, the rest was decoration).
class _StatsCounter extends StatelessWidget {
  const _StatsCounter({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  final String label;
  final int count;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.page,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: colors.line),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: colors.textMuted,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsetsDirectional.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A legend dot, a platform name and its parenthesised count.
class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(label, style: TextStyle(fontSize: 14, color: colors.textMuted)),
        const SizedBox(width: AppSpacing.xs),
        Text(
          l10n.dashboardLegendCount(count),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: colors.text,
          ),
        ),
      ],
    );
  }
}
