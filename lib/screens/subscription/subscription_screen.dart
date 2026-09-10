import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:doss_core/doss_core.dart';
import '../../blocs/driver/driver_bloc.dart';
import '../../widgets/driver_nav_bar.dart';

const _cyan = Color(0xFF06F6FF);

class DriverSubscriptionScreen extends StatefulWidget {
  const DriverSubscriptionScreen({super.key});

  @override
  State<DriverSubscriptionScreen> createState() =>
      _DriverSubscriptionScreenState();
}

class _DriverSubscriptionScreenState extends State<DriverSubscriptionScreen> {
  bool _loading = true;
  DriverSubscription? _sub;
  String? _error;
  Timer? _countdown;
  Timer? _watchman;
  Duration _remaining = Duration.zero;
  String? _selectedPlan; // 'car' | 'bike' | 'shuttle'

  @override
  void initState() {
    super.initState();
    _load();
    _watchman =
        Timer.periodic(const Duration(seconds: 60), (_) => _checkExpiry());
  }

  @override
  void dispose() {
    _countdown?.cancel();
    _watchman?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final driverId = AuthService.instance.currentUser?.id ?? '';
      final result = await ApiClient.instance
          .query('subscriptions.status', input: {'driverId': driverId});
      DriverSubscription? sub;
      if (result['subscription'] is Map) {
        sub = DriverSubscription.fromJson(
            result['subscription'] as Map<String, dynamic>);
      } else if (result['hasActiveSubscription'] == true) {
        sub = DriverSubscription(
          id: '',
          planName: 'Active',
          status: 'active',
          expiresAt: result['expiresAt'] != null
              ? DateTime.tryParse(result['expiresAt'] as String)
              : null,
          priceEgp: 0,
        );
      }
      if (mounted) {
        setState(() {
          _sub = sub;
          _loading = false;
        });
        if (sub != null && sub.isActive && sub.expiresAt != null) {
          _startCountdown(sub.expiresAt!);
        }
      }
    } catch (e) {
      if (mounted)
        setState(() {
          _error = e.toString();
          _loading = false;
        });
    }
  }

  void _startCountdown(DateTime exp) {
    _countdown?.cancel();
    _remaining = exp.difference(DateTime.now());
    _countdown = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final r = exp.difference(DateTime.now());
      if (r.isNegative) {
        _countdown?.cancel();
        _checkExpiry();
      } else {
        setState(() => _remaining = r);
      }
    });
  }

  Future<void> _checkExpiry() async {
    if (_sub == null || !_sub!.isActive) {
      try {
        await ApiClient.instance
            .mutate('drivers.updateStatus', input: {'status': 'offline'});
        if (mounted) {
          context.read<DriverBloc>().add(DriverGoOffline());
        }
      } catch (_) {}
      await _load();
    }
  }

  String _fmt(Duration d, String Function(String, String) t) {
    if (d.isNegative) return t('Expired', 'منتهي');
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final t = lang.t;

    return Directionality(
      textDirection: lang.textDirection,
      child: Scaffold(
        backgroundColor: Colors.black,
        bottomNavigationBar: const DriverNavBar(current: 2),
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Text(t('Subscription', 'الاشتراك'),
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700)),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: _cyan))
            : _error != null
                ? _ErrorView(error: _error!, onRetry: _load, t: t)
                : ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _StatusCard(
                          sub: _sub, remainingText: _fmt(_remaining, t), t: t),
                      const SizedBox(height: 22),
                      Text(t('Choose Your Plan', 'اختر خطتك'),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      _PlanCard(
                        planKey: 'car',
                        selected: _selectedPlan == 'car',
                        onTap: () => setState(() => _selectedPlan = 'car'),
                        icon: Icons.directions_car_rounded,
                        accent: const Color(0xFF00A3E0),
                        title: t('Car Driver Plan', 'خطة سائق السيارة'),
                        desc: t('Standard rides across your city',
                            'رحلات عادية في مدينتك'),
                        price: '${AppConstants.subscriptionFeeCar}',
                        t: t,
                      ),
                      const SizedBox(height: 10),
                      _PlanCard(
                        planKey: 'bike',
                        selected: _selectedPlan == 'bike',
                        onTap: () => setState(() => _selectedPlan = 'bike'),
                        icon: Icons.two_wheeler_rounded,
                        accent: const Color(0xFF00BCD4),
                        title: t('Bike Driver Plan', 'خطة سائق الموتوسيكل'),
                        desc: t('Short rides, fast earnings',
                            'رحلات قصيرة، أرباح سريعة'),
                        price: '${AppConstants.subscriptionFeeBike}',
                        t: t,
                      ),
                      const SizedBox(height: 10),
                      _PlanCard(
                        planKey: 'shuttle',
                        selected: _selectedPlan == 'shuttle',
                        onTap: () => setState(() => _selectedPlan = 'shuttle'),
                        icon: Icons.airport_shuttle_rounded,
                        accent: const Color(0xFFFF6B00),
                        title: t('Shuttle Driver Plan', 'خطة سائق الشاتل'),
                        desc: t('Fixed routes, up to 14 riders',
                            'خطوط ثابتة، حتى ١٤ راكب'),
                        price: '${AppConstants.subscriptionFeeShuttle}',
                        t: t,
                      ),
                      const SizedBox(height: 22),
                      Text(t('How to Subscribe', 'كيفية الاشتراك'),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      _StepRow(
                          n: 1,
                          t: t,
                          en: 'Open your bank app → InstaPay',
                          ar: 'افتح تطبيق البنك ← InstaPay'),
                      _StepRow(
                          n: 2,
                          t: t,
                          en: 'Send to: ${AppConstants.instapayNumber}',
                          ar: 'حوّل على: ${AppConstants.instapayNumber}'),
                      _StepRow(
                          n: 3,
                          t: t,
                          en: 'Send the exact plan amount',
                          ar: 'حوّل مبلغ الخطة بالظبط'),
                      _StepRow(
                          n: 4,
                          t: t,
                          en: 'Screenshot the confirmation',
                          ar: 'صوّر تأكيد التحويل'),
                      _StepRow(
                          n: 5,
                          t: t,
                          en: 'Upload below — verified instantly!',
                          ar: 'ارفعها تحت — التفعيل فوري!'),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: _selectedPlan == null
                              ? null
                              : () => context.push('/subscription/upload'),
                          icon: const Icon(Icons.upload_file_rounded, size: 20),
                          label: Text(
                            _selectedPlan == null
                                ? t('Select a plan first', 'اختر خطة الأول')
                                : t('Upload Payment Receipt',
                                    'رفع إيصال الدفع'),
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _cyan,
                            foregroundColor: Colors.black,
                            disabledBackgroundColor: AppTheme.surface,
                            disabledForegroundColor: AppTheme.textMuted,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String planKey;
  final bool selected;
  final VoidCallback onTap;
  final IconData icon;
  final Color accent;
  final String title;
  final String desc;
  final String price;
  final String Function(String, String) t;

  const _PlanCard({
    required this.planKey,
    required this.selected,
    required this.onTap,
    required this.icon,
    required this.accent,
    required this.title,
    required this.desc,
    required this.price,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? _cyan.withValues(alpha: 0.08) : AppTheme.primaryMid,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? _cyan : AppTheme.divider,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
                const SizedBox(height: 3),
                Text(desc,
                    style: const TextStyle(
                        color: AppTheme.textMuted, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$price ${t('EGP', 'ج.م')}',
                  style: TextStyle(
                      color: selected ? _cyan : Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 17)),
              Text(t('/ day', '/ يوم'),
                  style:
                      const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
            ],
          ),
          const SizedBox(width: 10),
          Icon(
            selected
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked,
            color: selected ? _cyan : AppTheme.textMuted,
            size: 24,
          ),
        ]),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final DriverSubscription? sub;
  final String remainingText;
  final String Function(String, String) t;

  const _StatusCard(
      {required this.sub, required this.remainingText, required this.t});

  @override
  Widget build(BuildContext context) {
    final active = sub != null && sub!.isActive;
    final color = active ? AppTheme.success : AppTheme.warning;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(children: [
        Icon(
          active ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
          color: color,
          size: 40,
        ),
        const SizedBox(height: 10),
        Text(
          active
              ? t('Subscription Active', 'الاشتراك فعّال')
              : t('No Active Subscription', 'لا يوجد اشتراك فعّال'),
          style: TextStyle(
              color: color, fontSize: 18, fontWeight: FontWeight.w800),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          active
              ? '${t('Time remaining', 'الوقت المتبقي')}: $remainingText'
              : t('Subscribe to start accepting rides',
                  'اشترك عشان تبدأ تستقبل رحلات'),
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          textAlign: TextAlign.center,
        ),
      ]),
    );
  }
}

class _StepRow extends StatelessWidget {
  final int n;
  final String en;
  final String ar;
  final String Function(String, String) t;

  const _StepRow(
      {required this.n, required this.en, required this.ar, required this.t});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: _cyan.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(color: _cyan.withValues(alpha: 0.4)),
          ),
          child: Center(
              child: Text('$n',
                  style: const TextStyle(
                      color: _cyan,
                      fontSize: 12,
                      fontWeight: FontWeight.w800))),
        ),
        const SizedBox(width: 12),
        Expanded(
            child: Text(t(en, ar),
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 13, height: 1.4))),
      ]),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  final String Function(String, String) t;

  const _ErrorView(
      {required this.error, required this.onRetry, required this.t});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.wifi_off_rounded,
              color: AppTheme.textMuted, size: 44),
          const SizedBox(height: 14),
          Text(
            t('Could not load subscription', 'تعذر تحميل بيانات الاشتراك'),
            style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
                backgroundColor: _cyan, foregroundColor: Colors.black),
            child: Text(t('Retry', 'إعادة المحاولة'),
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ]),
      ),
    );
  }
}
