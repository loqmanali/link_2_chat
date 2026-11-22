import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:intl/intl.dart';

import '../../core/config/app_theme.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/loading_indicator.dart';
import 'components/recent_activity_list.dart';
import 'components/stats_counter.dart';
import 'components/top_countries_chart.dart';
import 'dashboard_viewmodel.dart';

class DashboardScreen extends HookWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dashboardBloc = useMemoized(() => DashboardBloc(), []);

    // Load data when screen is first shown
    useEffect(() {
      dashboardBloc.add(LoadDashboardDataEvent());
      return () {
        dashboardBloc.close();
      };
    }, [dashboardBloc]);

    return BlocProvider(
      create: (context) => dashboardBloc,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: const CustomAppBar(title: 'Dashboard'),
        body: BlocBuilder<DashboardBloc, DashboardState>(
          builder: (context, state) {
            if (state.isLoading && state.recentEntries.isEmpty) {
              return const LoadingIndicator(
                message: 'Loading dashboard data...',
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                dashboardBloc.add(RefreshDashboardDataEvent());
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSummaryCard(state),
                    const SizedBox(height: 24),
                    _buildStatisticsSection(state),
                    const SizedBox(height: 24),
                    TopCountriesChart(countries: state.topCountries),
                    const SizedBox(height: 24),
                    RecentActivityList(entries: state.recentEntries),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryCard(DashboardState state) {
    final totalLinks = state.totalLinks;
    final dateFormat = DateFormat('MMMM dd, yyyy');
    final today = dateFormat.format(DateTime.now());

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Links Generated',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    totalLinks.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.link_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  today,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection(DashboardState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 16),
          child: Text(
            'Platform Statistics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: StatsCounter(
                label: 'WhatsApp',
                count: state.whatsAppLinks,
                icon: Icons.message_rounded,
                color: AppTheme.whatsappColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: StatsCounter(
                label: 'Telegram',
                count: state.telegramLinks,
                icon: Icons.send_rounded,
                color: AppTheme.telegramColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildPlatformDistributionBar(state),
      ],
    );
  }

  Widget _buildPlatformDistributionBar(DashboardState state) {
    final whatsAppPercentage =
        state.totalLinks > 0 ? state.whatsAppLinks / state.totalLinks : 0.0;
    final telegramPercentage =
        state.totalLinks > 0 ? state.telegramLinks / state.totalLinks : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Platform Distribution',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                Expanded(
                  flex: (whatsAppPercentage * 100).round(),
                  child: Container(
                    height: 24,
                    color: AppTheme.whatsappColor,
                    alignment: Alignment.center,
                    child:
                        whatsAppPercentage > 0.15
                            ? Text(
                              '${(whatsAppPercentage * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            )
                            : null,
                  ),
                ),
                Expanded(
                  flex: (telegramPercentage * 100).round(),
                  child: Container(
                    height: 24,
                    color: AppTheme.telegramColor,
                    alignment: Alignment.center,
                    child:
                        telegramPercentage > 0.15
                            ? Text(
                              '${(telegramPercentage * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            )
                            : null,
                  ),
                ),
                Expanded(
                  flex:
                      100 -
                      (whatsAppPercentage * 100).round() -
                      (telegramPercentage * 100).round(),
                  child: Container(height: 24, color: Colors.grey[300]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildLegendItem(
                'WhatsApp',
                AppTheme.whatsappColor,
                state.whatsAppLinks,
              ),
              const SizedBox(width: 24),
              _buildLegendItem(
                'Telegram',
                AppTheme.telegramColor,
                state.telegramLinks,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, int count) {
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
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
        const SizedBox(width: 4),
        Text(
          '($count)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }
}
