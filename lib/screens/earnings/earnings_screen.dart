import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:doss_core/doss_core.dart';
import '../../blocs/driver/driver_bloc.dart';
import '../../widgets/driver_nav_bar.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<DriverBloc>().add(DriverStatsRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      bottomNavigationBar: const DriverNavBar(current: 1),
      appBar: AppBar(
        backgroundColor: AppTheme.primaryDark,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Earnings'),
      ),
      body: BlocBuilder<DriverBloc, DriverState>(
        builder: (context, state) {
          final stats = state is DriverOnline ? state.stats : null;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Today's earnings card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A6B3C), AppTheme.accent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Today's Earnings",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'EGP ${(stats?.dailyEarningsEgp ?? 0.0).toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _EarningsBadge(
                          label: 'Rides',
                          value: '${stats?.ridesCompleted ?? 0}',
                          icon: Icons.directions_car_outlined,
                        ),
                        const SizedBox(width: 12),
                        _EarningsBadge(
                          label: 'Online',
                          value: '${stats?.onlineMinutes ?? 0}m',
                          icon: Icons.access_time,
                        ),
                        const SizedBox(width: 12),
                        _EarningsBadge(
                          label: 'Acceptance',
                          value:
                              '${((stats?.acceptanceRate ?? 0) * 100).toStringAsFixed(0)}%',
                          icon: Icons.thumb_up_outlined,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Performance metrics
              Text(
                'Performance',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 16),
              _MetricCard(
                icon: Icons.check_circle_outline,
                label: 'Completion Rate',
                value: stats != null
                    ? '${((1 - (stats.cancellationRate)) * 100).toStringAsFixed(0)}%'
                    : '--',
                color: AppTheme.success,
              ),
              const SizedBox(height: 10),
              _MetricCard(
                icon: Icons.cancel_outlined,
                label: 'Cancellation Rate',
                value: stats != null
                    ? '${(stats.cancellationRate * 100).toStringAsFixed(0)}%'
                    : '--',
                color: AppTheme.error,
              ),
              const SizedBox(height: 10),
              _MetricCard(
                icon: Icons.star_outline,
                label: 'Acceptance Rate',
                value: stats != null
                    ? '${(stats.acceptanceRate * 100).toStringAsFixed(0)}%'
                    : '--',
                color: AppTheme.accent,
              ),
              const SizedBox(height: 24),
              // Subscription reminder
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryMid,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppTheme.accent.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.card_membership_outlined,
                        color: AppTheme.accent, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Zero Commission',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Keep 100% of your fares with an active subscription',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push('/subscription'),
                      child: const Text('View'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _EarningsBadge extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _EarningsBadge({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 14),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryMid,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}
