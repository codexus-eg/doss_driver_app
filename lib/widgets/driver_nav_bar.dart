import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:doss_core/doss_core.dart';

/// DOSS driver bottom navigation — 5 tabs, bilingual, Brand Cyan active state.
class DriverNavBar extends StatelessWidget {
  final int current;
  const DriverNavBar({super.key, required this.current});

  static const _cyan = Color(0xFF06F6FF);
  static const _inactive = Color(0xFF8A8A8E);

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final t = lang.t;

    final tabs = <_NavItem>[
      _NavItem('/dashboard', t('Drive', 'القيادة'),
          Icons.navigation_rounded, Icons.navigation_outlined),
      _NavItem('/earnings', t('Earnings', 'الأرباح'),
          Icons.account_balance_wallet_rounded,
          Icons.account_balance_wallet_outlined),
      _NavItem('/subscription', t('Subscription', 'الاشتراك'),
          Icons.card_membership_rounded, Icons.card_membership_outlined),
      _NavItem('/trips', t('Trips', 'الرحلات'),
          Icons.receipt_long_rounded, Icons.receipt_long_outlined),
      _NavItem('/profile', t('Account', 'الحساب'),
          Icons.person_rounded, Icons.person_outline_rounded),
    ];

    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0A0A0A),
        border: Border(
            top: BorderSide(color: Color(0xFF1C1C1E), width: 0.5)),
      ),
      padding: EdgeInsets.only(
          top: 8, bottom: bottomInset > 0 ? bottomInset : 8),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final tab = tabs[i];
          final selected = i == current;
          final color = selected ? _cyan : _inactive;
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (selected) return;
                context.go(tab.route);
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(selected ? tab.active : tab.inactive,
                      color: color, size: 24),
                  const SizedBox(height: 4),
                  Text(
                    tab.label,
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _NavItem {
  final String route;
  final String label;
  final IconData active;
  final IconData inactive;
  const _NavItem(this.route, this.label, this.active, this.inactive);
}
