import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:doss_core/doss_core.dart';
import '../../blocs/auth/driver_auth_bloc.dart';
import '../../widgets/driver_nav_bar.dart';

const _cyan = Color(0xFF06F6FF);
const _brandBlue = Color(0xFF00A3E0);

class DriverProfileScreen extends StatelessWidget {
  const DriverProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final t = lang.t;
    final state = context.watch<DriverAuthBloc>().state;
    final user = state is DriverAuthAuthenticated ? state.user : null;

    return Directionality(
      textDirection: lang.textDirection,
      child: Scaffold(
        backgroundColor: AppTheme.primaryDark,
        bottomNavigationBar: const DriverNavBar(current: 4),
        appBar: AppBar(
          backgroundColor: AppTheme.primaryDark,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Text(t('My Account', 'حسابي'),
              style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          children: [
            Center(
              child: Column(
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_cyan, _brandBlue],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _cyan.withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        user?.name.isNotEmpty == true
                            ? user!.name[0].toUpperCase()
                            : 'D',
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w900,
                          fontSize: 36,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    user?.name ?? t('Driver', 'السائق'),
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.phone ?? '',
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            _SectionHeader(title: t('Account', 'الحساب')),
            _InfoRow(
                icon: Icons.person_outline,
                label: t('Name', 'الاسم'),
                value: user?.name ?? '--'),
            _InfoRow(
                icon: Icons.phone_outlined,
                label: t('Phone', 'الهاتف'),
                value: user?.phone ?? '--'),
            const SizedBox(height: 22),
            _SectionHeader(title: t('Vehicle', 'المركبة')),
            _InfoRow(
                icon: Icons.directions_car_outlined,
                label: t('Model', 'الموديل'),
                value: user?.vehicleModel ?? '--'),
            _InfoRow(
                icon: Icons.credit_card_outlined,
                label: t('Plate', 'اللوحة'),
                value: user?.vehiclePlate ?? '--'),
            _InfoRow(
                icon: Icons.location_city_outlined,
                label: t('Governorate', 'المحافظة'),
                value: user?.governorate ?? '--'),
            const SizedBox(height: 22),
            _SectionHeader(title: t('Management', 'الإدارة')),
            _NavRow(
              icon: Icons.badge_outlined,
              label: t('My Documents', 'مستنداتي'),
              subtitle: t(
                  'Upload or update your documents', 'رفع أو تحديث المستندات'),
              color: _cyan,
              onTap: () => context.push('/documents'),
            ),
            _NavRow(
              icon: Icons.description_outlined,
              label: t('Terms & Policies', 'الشروط والسياسات'),
              subtitle:
                  t('Review the driver agreement', 'مراجعة اتفاقية السائق'),
              color: AppTheme.textSecondary,
              onTap: () => context.push('/terms'),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () {
                  context
                      .read<DriverAuthBloc>()
                      .add(DriverAuthLogoutRequested());
                  context.go('/login');
                },
                icon: const Icon(Icons.logout, size: 18),
                label: Text(
                  t('Sign Out', 'تسجيل الخروج'),
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.error,
                  side: const BorderSide(color: AppTheme.error, width: 1.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.primaryMid,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textMuted, size: 18),
          const SizedBox(width: 14),
          Text(label,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _NavRow({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppTheme.primaryMid,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 15)),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: const TextStyle(
                              color: AppTheme.textMuted, fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: AppTheme.textMuted, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
