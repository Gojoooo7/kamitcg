import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/bottom_nav_shell.dart';
import '../../market/presentation/market_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../scanner/presentation/scanner_screen.dart';
import 'add_card_screen.dart';
import 'card_detail_screen.dart';
import 'collection_screen.dart';
import 'dashboard_screen.dart';

/// Coque principale — héberge les 4 onglets, le FAB scanner, le détail carte
/// et l'overlay "Ajouter manuellement".
///
/// Le FAB ouvre le **scanner OCR** ; depuis le scanner, l'utilisateur peut
/// basculer sur l'AddCardScreen pour saisir une carte manuellement (utile
/// quand la lumière est mauvaise ou la carte abîmée). L'AddCardScreen est
/// aussi accessible via l'empty state du Dashboard / Collection.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  AppTab _tab = AppTab.home;
  String? _activeCardId;
  bool _scanning = false;
  bool _addingCard = false;

  void _openCard(String id) => setState(() => _activeCardId = id);
  void _closeCard() => setState(() => _activeCardId = null);

  void _openScanner() {
    Haptics.light(ref);
    setState(() => _scanning = true);
  }

  void _closeScanner() => setState(() => _scanning = false);

  void _openAddCard() {
    Haptics.light(ref);
    setState(() => _addingCard = true);
  }

  void _closeAddCard() => setState(() => _addingCard = false);

  /// Bascule depuis le scanner vers la saisie manuelle (close scan, open add).
  void _scannerToManual() {
    setState(() {
      _scanning = false;
      _addingCard = true;
    });
  }

  Widget _buildBody() {
    if (_activeCardId != null) {
      return CardDetailScreen(
        collectionItemId: _activeCardId!,
        onBack: _closeCard,
      );
    }
    switch (_tab) {
      case AppTab.home:
        return DashboardScreen(
          onCardTap: _openCard,
          onAddPressed: _openAddCard,
          onSeeAllPressed: () => setState(() => _tab = AppTab.collection),
        );
      case AppTab.collection:
        return CollectionScreen(
          onCardTap: _openCard,
          onAddPressed: _openAddCard,
        );
      case AppTab.market:
        return const MarketScreen();
      case AppTab.profile:
        return const ProfileScreen();
    }
  }

  bool get _canPopRoot =>
      !_scanning &&
      !_addingCard &&
      _activeCardId == null &&
      _tab == AppTab.home;

  void _handleSystemPop(bool didPop, Object? _) {
    if (didPop) return;
    if (_scanning) {
      setState(() => _scanning = false);
      return;
    }
    if (_addingCard) {
      setState(() => _addingCard = false);
      return;
    }
    if (_activeCardId != null) {
      setState(() => _activeCardId = null);
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
            Positioned.fill(
              child: SafeArea(bottom: false, child: _buildBody()),
            ),
            // Bottom nav (cachée en mode détail / scanner / add)
            if (_activeCardId == null && !_scanning && !_addingCard)
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
            // Overlay scanner OCR
            if (_scanning)
              Positioned.fill(
                child: ScannerScreen(
                  onClose: _closeScanner,
                  onAdded: (entry) {
                    _closeScanner();
                    ScaffoldMessenger.of(context).showSnackBar(
                      AppSnackBar.success(Strings.addCardAdded),
                    );
                  },
                  onManualEntry: _scannerToManual,
                ),
              ),
            // Overlay AddCard manuel
            if (_addingCard)
              Positioned.fill(
                child: AddCardScreen(onClose: _closeAddCard),
              ),
          ],
        ),
      ),
    );
  }
}
