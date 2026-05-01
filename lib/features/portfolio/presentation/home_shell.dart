import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/bottom_nav_shell.dart';
import '../../../core/widgets/placeholder_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../domain/card_models.dart';
import 'add_card_screen.dart';
import 'card_detail_screen.dart';
import 'collection_screen.dart';
import 'dashboard_screen.dart';

/// Coque principale — héberge les 4 onglets, le FAB d'ajout et le détail carte.
///
/// V1 : le FAB ouvre l'écran "Ajouter une carte" (browse catalogue) car le
/// scanner OCR réel n'est pas encore branché. Quand ML Kit sera intégré, le
/// FAB rebasculera vers le scanner et l'AddCard restera accessible via l'empty
/// state du Dashboard / Collection.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  AppTab _tab = AppTab.home;
  DisplayCard? _activeCard;
  bool _addingCard = false;

  void _openCard(DisplayCard c) => setState(() => _activeCard = c);
  void _closeCard() => setState(() => _activeCard = null);

  void _openAddCard() {
    HapticFeedback.lightImpact();
    setState(() => _addingCard = true);
  }

  void _closeAddCard() => setState(() => _addingCard = false);

  Widget _buildBody() {
    if (_activeCard != null) {
      return CardDetailScreen(card: _activeCard!, onBack: _closeCard);
    }
    switch (_tab) {
      case AppTab.home:
        return DashboardScreen(
          onCardTap: _openCard,
          onAddPressed: _openAddCard,
        );
      case AppTab.collection:
        return CollectionScreen(
          onCardTap: _openCard,
          onAddPressed: _openAddCard,
        );
      case AppTab.market:
        return const PlaceholderScreen(
          title: Strings.marketTitle,
          subtitle: Strings.marketSubtitle,
        );
      case AppTab.profile:
        return const ProfileScreen();
    }
  }

  bool get _canPopRoot =>
      !_addingCard && _activeCard == null && _tab == AppTab.home;

  void _handleSystemPop(bool didPop, Object? _) {
    if (didPop) return;
    if (_addingCard) {
      setState(() => _addingCard = false);
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
            // Bottom nav (cachée en mode détail carte ou ajout)
            if (_activeCard == null && !_addingCard)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: BottomNavShell(
                  activeTab: _tab,
                  onTabChanged: (t) => setState(() => _tab = t),
                  onScanPressed: _openAddCard,
                ),
              ),
            // Overlay AddCard
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
