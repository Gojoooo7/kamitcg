import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/bottom_nav_shell.dart';
import '../../../core/widgets/placeholder_screen.dart';
import '../../scanner/presentation/scanner_screen.dart';
import '../domain/card_models.dart';
import 'card_detail_screen.dart';
import 'collection_screen.dart';
import 'dashboard_screen.dart';

/// Coque principale — héberge les 4 onglets, le FAB scan et le détail carte.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  AppTab _tab = AppTab.home;
  TcgCard? _activeCard;
  bool _scanning = false;

  void _openCard(TcgCard c) => setState(() => _activeCard = c);
  void _closeCard() => setState(() => _activeCard = null);

  void _openScanner() {
    HapticFeedback.lightImpact();
    setState(() => _scanning = true);
  }

  Widget _buildBody() {
    if (_activeCard != null) {
      return CardDetailScreen(card: _activeCard!, onBack: _closeCard);
    }
    switch (_tab) {
      case AppTab.home:
        return DashboardScreen(onCardTap: _openCard);
      case AppTab.collection:
        return CollectionScreen(onCardTap: _openCard);
      case AppTab.market:
        return const PlaceholderScreen(
          title: Strings.marketTitle,
          subtitle: Strings.marketSubtitle,
        );
      case AppTab.profile:
        return const PlaceholderScreen(
          title: Strings.profileTitle,
          subtitle: Strings.profileSubtitle,
        );
    }
  }

  bool get _canPopRoot =>
      !_scanning && _activeCard == null && _tab == AppTab.home;

  void _handleSystemPop(bool didPop, Object? _) {
    if (didPop) return;
    if (_scanning) {
      setState(() => _scanning = false);
      return;
    }
    if (_activeCard != null) {
      setState(() => _activeCard = null);
      return;
    }
    if (_tab != AppTab.home) {
      setState(() => _tab = AppTab.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: _canPopRoot,
      onPopInvokedWithResult: _handleSystemPop,
      child: Scaffold(
        backgroundColor: AppColors.bg0,
        body: Stack(
          children: [
            // Halo radial subtil (violet en haut-gauche, doré en haut-droite)
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(-0.6, -1.0),
                    radius: 1.4,
                    colors: [Color(0x1A8A2BE2), Colors.transparent],
                    stops: [0, 1],
                  ),
                ),
              ),
            ),
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(1.0, -0.8),
                    radius: 1.0,
                    colors: [Color(0x10D4AF37), Colors.transparent],
                    stops: [0, 1],
                  ),
                ),
              ),
            ),
            // Contenu de l'onglet (ou détail)
            Positioned.fill(child: SafeArea(bottom: false, child: _buildBody())),
            // Bottom nav (cachée en mode détail carte)
            if (_activeCard == null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: BottomNavShell(
                  activeTab: _tab,
                  onTabChanged: (t) => setState(() => _tab = t),
                  onScanPressed: _openScanner,
                ),
              ),
            // Scanner overlay
            if (_scanning)
              Positioned.fill(
                child: ScannerScreen(
                  onClose: () => setState(() => _scanning = false),
                  onScanned: (c) {
                    HapticFeedback.mediumImpact();
                    setState(() {
                      _scanning = false;
                      _activeCard = c;
                    });
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
