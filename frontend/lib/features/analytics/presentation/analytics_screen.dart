import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/metric_card.dart';
import '../../../shared/widgets/section_panel.dart';
import '../data/analytics_repository.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final delays = ref.watch(delayAnalyticsProvider);
    final performance = ref.watch(performanceAnalyticsProvider);
    final reliability = ref.watch(reliabilityAnalyticsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.08),
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(delayAnalyticsProvider);
            ref.invalidate(performanceAnalyticsProvider);
            ref.invalidate(reliabilityAnalyticsProvider);
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              delays.when(
                loading: () => const LinearProgressIndicator(),
                error: (error, _) => _ErrorPanel(message: error.toString()),
                data: (data) => LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth > 720;
                    final cards = [
                      MetricCard(
                        title: 'Delay',
                        value: '${data.delayPercent}%',
                        subtitle:
                            '${data.delayedSteps}/${data.totalSteps} steps',
                        icon: Icons.warning_amber_rounded,
                        color: const Color(0xFFB45309),
                      ),
                      MetricCard(
                        title: 'Avg Delay',
                        value: '${data.averageDelayMinutes}m',
                        icon: Icons.schedule_rounded,
                      ),
                      MetricCard(
                        title: 'Needs Confirmation',
                        value: '${data.needsConfirmation}',
                        icon: Icons.pending_actions_rounded,
                      ),
                    ];
                    return GridView.count(
                      crossAxisCount: wide ? 3 : 1,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: wide ? 2.0 : 3.0,
                      children: cards,
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              performance.when(
                loading: () => const SizedBox.shrink(),
                error: (error, _) => _ErrorPanel(message: error.toString()),
                data: (data) => SectionPanel(
                  title: 'Execution Performance',
                  icon: Icons.monitor_heart_rounded,
                  child: SizedBox(
                    height: 220,
                    child: BarChart(
                      BarChartData(
                        borderData: FlBorderData(show: false),
                        gridData: FlGridData(
                          show: true,
                          getDrawingHorizontalLine: (_) => FlLine(
                            color: Theme.of(
                              context,
                            ).colorScheme.outlineVariant.withValues(alpha: 0.4),
                          ),
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: true),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, _) {
                                final labels = [
                                  'Active',
                                  'Done',
                                  'Rate',
                                  'Esc',
                                ];
                                return Text(
                                  labels[value.toInt().clamp(
                                    0,
                                    labels.length - 1,
                                  )],
                                );
                              },
                            ),
                          ),
                        ),
                        barGroups: [
                          _bar(0, data.activeShipments.toDouble()),
                          _bar(1, data.completedShipments.toDouble()),
                          _bar(2, data.completionRate),
                          _bar(3, data.escalationFrequency),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              reliability.when(
                loading: () => const SizedBox.shrink(),
                error: (error, _) => _ErrorPanel(message: error.toString()),
                data: (data) => SectionPanel(
                  title: 'Transporter Reliability',
                  icon: Icons.verified_user_rounded,
                  child: Column(
                    children: [
                      for (final item in data.transporters.take(8))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    Text(item.shipmentReference),
                                    const SizedBox(height: 6),
                                    LinearProgressIndicator(
                                      value: item.reliabilityScore / 100,
                                      minHeight: 8,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text('${item.reliabilityScore.round()}%'),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  BarChartGroupData _bar(int x, double y) => BarChartGroupData(
    x: x,
    barRods: [
      BarChartRodData(
        toY: y,
        width: 24,
        borderRadius: BorderRadius.circular(4),
      ),
    ],
  );
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
