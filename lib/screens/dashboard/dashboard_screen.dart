import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:doss_core/doss_core.dart' hide LatLng;
import 'package:doss_core/theme/app_theme.dart';
import 'package:doss_core/constants/constants.dart';
import '../../blocs/auth/driver_auth_bloc.dart';
import '../../blocs/driver/driver_bloc.dart';
import '../../blocs/offer/offer_bloc.dart';
import '../../widgets/driver_nav_bar.dart';

const _cyan = Color(0xFF06F6FF);
const _brandBlue = Color(0xFF00A3E0);

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  GoogleMapController? _mapCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.97, end: 1.03)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DriverBloc>().add(DriverStatsRequested());
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _mapCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final t = lang.t;
    final user =
        (context.watch<DriverAuthBloc>().state as DriverAuthAuthenticated?)
            ?.user;

    return BlocListener<OfferBloc, OfferState>(
      listener: (ctx, offerState) {
        if (offerState is OfferPending) ctx.go('/offer');
        if (offerState is OfferRideFinished) {
          ctx.read<DriverBloc>().add(DriverStatsRequested());
          ctx.read<OfferBloc>().add(OfferReset());
        }
      },
      child: Directionality(
        textDirection: lang.textDirection,
        child: Scaffold(
          backgroundColor: Colors.black,
          bottomNavigationBar: const DriverNavBar(current: 0),
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                // ── Header ────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                  child: Row(children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_cyan, _brandBlue],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          user?.name.isNotEmpty == true
                              ? user!.name[0].toUpperCase()
                              : 'D',
                          style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w900,
                              fontSize: 19),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(user?.name ?? t('Driver', 'السائق'),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16)),
                          const SizedBox(height: 2),
                          BlocBuilder<DriverBloc, DriverState>(
                            builder: (_, state) {
                              final online = state is DriverOnline;
                              return Row(children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: online
                                        ? AppTheme.success
                                        : AppTheme.textMuted,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  online
                                      ? t('Online', 'متصل')
                                      : t('Offline', 'غير متصل'),
                                  style: TextStyle(
                                      color: online
                                          ? AppTheme.success
                                          : AppTheme.textMuted,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600),
                                ),
                              ]);
                            },
                          ),
                        ],
                      ),
                    ),
                    BlocBuilder<DriverBloc, DriverState>(
                      builder: (_, state) {
                        final stats =
                            state is DriverOnline ? state.stats : null;
                        final earnings = stats?.dailyEarningsEgp ?? 0.0;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: _cyan.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: _cyan.withValues(alpha: 0.35)),
                          ),
                          child: Text(
                            '${earnings.toStringAsFixed(0)} ${t('EGP', 'ج')}',
                            style: const TextStyle(
                                color: _cyan,
                                fontWeight: FontWeight.w800,
                                fontSize: 13),
                          ),
                        );
                      },
                    ),
                  ]),
                ),
                // ── Map area (bounded — cannot break the layout) ──
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0E0E0E),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFF1C1C1E)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        GoogleMap(
                          initialCameraPosition: const CameraPosition(
                            target: LatLng(AppConstants.defaultLat,
                                AppConstants.defaultLng),
                            zoom: AppConstants.defaultZoom,
                          ),
                          onMapCreated: (c) {
                            _mapCtrl = c;
                            if (mounted) setState(() => _mapReady = true);
                          },
                          myLocationEnabled: false,
                          myLocationButtonEnabled: false,
                          zoomControlsEnabled: false,
                          mapToolbarEnabled: false,
                          compassEnabled: false,
                          liteModeEnabled: false,
                        ),
                        if (!_mapReady)
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(
                                  width: 26,
                                  height: 26,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.5, color: _cyan),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  t('Loading map...', 'جاري تحميل الخريطة...'),
                                  style: const TextStyle(
                                      color: AppTheme.textMuted, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                // ── Bottom Panel ─────────────────────────────────
                _BottomPanel(t: t, pulseAnim: _pulseAnim),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomPanel extends StatelessWidget {
  final String Function(String, String) t;
  final Animation<double> pulseAnim;
  const _BottomPanel({required this.t, required this.pulseAnim});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          BlocBuilder<DriverBloc, DriverState>(
            builder: (_, state) {
              final stats = state is DriverOnline ? state.stats : null;
              final earnings = stats?.dailyEarningsEgp ?? 0.0;
              return Row(children: [
                _StatCard(
                  label: t('Rides', 'الرحلات'),
                  value: '${stats?.ridesCompleted ?? 0}',
                  icon: Icons.directions_car_outlined,
                ),
                const SizedBox(width: 8),
                _StatCard(
                  label: t('Acceptance', 'القبول'),
                  value:
                      '${((stats?.acceptanceRate ?? 0) * 100).toStringAsFixed(0)}%',
                  icon: Icons.thumb_up_outlined,
                ),
                const SizedBox(width: 8),
                _StatCard(
                  label: t('Today', 'اليوم'),
                  value: '${earnings.toStringAsFixed(0)} ${t('EGP', 'ج')}',
                  icon: Icons.payments_outlined,
                  highlight: true,
                ),
              ]);
            },
          ),
          const SizedBox(height: 14),
          BlocBuilder<DriverBloc, DriverState>(
            builder: (_, state) {
              final online = state is DriverOnline;
              return AnimatedBuilder(
                animation: pulseAnim,
                builder: (_, child) => Transform.scale(
                  scale: online ? 1.0 : pulseAnim.value,
                  child: child,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () {
                      if (online) {
                        context.read<DriverBloc>().add(DriverGoOffline());
                      } else {
                        context.read<DriverBloc>().add(DriverGoOnline());
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: online
                          ? AppTheme.error.withValues(alpha: 0.15)
                          : _cyan,
                      foregroundColor: online ? AppTheme.error : Colors.black,
                      side: online
                          ? const BorderSide(color: AppTheme.error, width: 1.5)
                          : BorderSide.none,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18)),
                      elevation: online ? 0 : 10,
                      shadowColor: _cyan.withValues(alpha: 0.6),
                    ),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            online
                                ? Icons.power_settings_new_rounded
                                : Icons.play_arrow_rounded,
                            size: 26,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            online
                                ? t('Go Offline', 'أوقف العمل')
                                : t('Go Online', 'ابدأ العمل'),
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w900),
                          ),
                        ]),
                  ),
                ),
              );
            },
          ),
        ]),
      );
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool highlight;
  const _StatCard(
      {required this.label,
      required this.value,
      required this.icon,
      this.highlight = false});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: highlight
                ? _cyan.withValues(alpha: 0.08)
                : const Color(0xFF141414),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: highlight
                    ? _cyan.withValues(alpha: 0.35)
                    : const Color(0xFF1F1F1F)),
          ),
          child: Column(children: [
            Icon(icon,
                color: highlight ? _cyan : AppTheme.textSecondary, size: 19),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    color: highlight ? _cyan : Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16)),
            const SizedBox(height: 2),
            Text(label,
                style:
                    const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
          ]),
        ),
      );
}
