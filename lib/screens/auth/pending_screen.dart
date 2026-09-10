import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:doss_core/doss_core.dart';
import '../../blocs/auth/driver_auth_bloc.dart';

class PendingApprovalScreen extends StatelessWidget {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<DriverAuthBloc, DriverAuthState>(
      listener: (context, state) {
        if (state is DriverAuthAuthenticated) {
          context.go('/dashboard');
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.primaryDark,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.hourglass_top_rounded,
                    color: AppTheme.warning,
                    size: 52,
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Application Under Review',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Your driver application has been submitted successfully. Our team will review it within 24 hours.',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 15,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                // Steps
                const _PendingStep(
                  icon: Icons.check_circle,
                  color: AppTheme.success,
                  label: 'Application submitted',
                  done: true,
                ),
                const SizedBox(height: 12),
                const _PendingStep(
                  icon: Icons.pending,
                  color: AppTheme.warning,
                  label: 'Admin review in progress',
                  done: false,
                ),
                const SizedBox(height: 12),
                const _PendingStep(
                  icon: Icons.directions_car_outlined,
                  color: AppTheme.textMuted,
                  label: 'Start accepting rides',
                  done: false,
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      context
                          .read<DriverAuthBloc>()
                          .add(DriverAuthCheckStatus());
                    },
                    child: const Text(
                      'Check Status',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    context
                        .read<DriverAuthBloc>()
                        .add(DriverAuthLogoutRequested());
                    context.go('/login');
                  },
                  child: const Text(
                    'Sign Out',
                    style: TextStyle(color: AppTheme.textMuted),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PendingStep extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final bool done;

  const _PendingStep({
    required this.icon,
    required this.color,
    required this.label,
    required this.done,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 14),
        Text(
          label,
          style: TextStyle(
            color: done ? AppTheme.textPrimary : AppTheme.textMuted,
            fontSize: 14,
            fontWeight: done ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
