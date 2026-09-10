import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:doss_core/doss_core.dart';
import '../../widgets/driver_nav_bar.dart';

class TripsScreen extends StatelessWidget {
  const TripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LanguageProvider>().t;
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      bottomNavigationBar: const DriverNavBar(current: 3),
      appBar: AppBar(
        backgroundColor: AppTheme.primaryDark,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(t('Trips', 'الرحلات'),
            style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: const Color(0xFF06F6FF).withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: const Color(0xFF06F6FF).withValues(alpha: 0.25)),
                ),
                child: const Icon(Icons.receipt_long_rounded,
                    color: Color(0xFF06F6FF), size: 44),
              ),
              const SizedBox(height: 24),
              Text(
                t('No trips yet', 'لا توجد رحلات بعد'),
                style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                t('Your completed trips will appear here once you start driving.',
                    'هتلاقي رحلاتك المكتملة هنا بمجرد ما تبدأ القيادة.'),
                style: const TextStyle(
                    color: AppTheme.textMuted, fontSize: 14, height: 1.5),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
