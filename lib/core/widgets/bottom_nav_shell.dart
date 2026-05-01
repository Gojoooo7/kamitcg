import 'dart:ui';

import 'package:flutter/material.dart';

import '../constants/strings.dart';
import '../theme/app_colors.dart';

enum AppTab { home, collection, market, profile }

class BottomNavShell extends StatelessWidget {
  const BottomNavShell({
    required this.activeTab,
    required this.onTabChanged,
    required this.onScanPressed,
    super.key,
  });

  final AppTab activeTab;
  final ValueChanged<AppTab> onTabChanged;
  final VoidCallback onScanPressed;

  @override
  Widget build(BuildContext context) {
    // Coller la nav au-dessus de la barre système (gesture bar / 3 boutons),
    // avec un mini-coussin de 4 px pour éviter qu'elle touche pile la barre.
    final safeBottom = MediaQuery.viewPaddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: safeBottom > 0 ? safeBottom + 4 : 12),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // Barre principale
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xC7141418),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppColors.line2),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x80000000),
                        blurRadius: 40,
                        offset: Offset(0, 14),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      _NavBtn(
                        item: _items[0],
                        active: activeTab == AppTab.home,
                        onTap: () => onTabChanged(AppTab.home),
                      ),
                      _NavBtn(
                        item: _items[1],
                        active: activeTab == AppTab.collection,
                        onTap: () => onTabChanged(AppTab.collection),
                      ),
                      const Spacer(),
                      _NavBtn(
                        item: _items[2],
                        active: activeTab == AppTab.market,
                        onTap: () => onTabChanged(AppTab.market),
                      ),
                      _NavBtn(
                        item: _items[3],
                        active: activeTab == AppTab.profile,
                        onTap: () => onTabChanged(AppTab.profile),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // FAB doré centré, avec halo pulsant
          Positioned(
            top: -10,
            child: _FabScan(onTap: onScanPressed),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  const _NavItem({required this.label, required this.icon});
  final String label;
  final IconData icon;
}

const _items = <_NavItem>[
  _NavItem(label: Strings.navHome, icon: Icons.home_rounded),
  _NavItem(label: Strings.navCollection, icon: Icons.grid_view_rounded),
  _NavItem(label: Strings.navMarket, icon: Icons.show_chart_rounded),
  _NavItem(label: Strings.navProfile, icon: Icons.person_rounded),
];

class _NavBtn extends StatelessWidget {
  const _NavBtn({
    required this.item,
    required this.active,
    required this.onTap,
  });

  final _NavItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 64,
        height: 64,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  item.icon,
                  size: 20,
                  color: active ? AppColors.text0 : AppColors.text2,
                ),
                const SizedBox(height: 2),
                Text(
                  item.label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: active ? AppColors.text0 : AppColors.text2,
                    letterSpacing: 0.04,
                  ),
                ),
              ],
            ),
            if (active)
              Positioned(
                bottom: 8,
                child: Container(
                  width: 14,
                  height: 2,
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: const [
                      BoxShadow(color: AppColors.gold, blurRadius: 6),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FabScan extends StatefulWidget {
  const _FabScan({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_FabScan> createState() => _FabScanState();
}

class _FabScanState extends State<_FabScan> with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;

  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _ctl,
        builder: (_, _) {
          // pulse ∈ [0,1] : convertit en spread du halo
          final v = 1 - (_ctl.value * 2 - 1).abs();
          final spreadAlpha = (0.45 * (1 - v) * 255).round();
          final spread = 14.0 * v;
          return Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.goldLight, AppColors.goldDark],
              ),
              border: Border.all(color: AppColors.bg0, width: 4),
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withAlpha(spreadAlpha),
                  blurRadius: 0,
                  spreadRadius: spread,
                ),
                BoxShadow(
                  color: AppColors.gold.withAlpha(0x66),
                  blurRadius: 30,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.photo_camera_rounded,
                size: 24,
                color: Color(0xFF191100),
              ),
            ),
          );
        },
      ),
    );
  }
}
