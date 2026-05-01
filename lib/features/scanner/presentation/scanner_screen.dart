import 'package:flutter/material.dart';

import '../../../core/constants/strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/card_art.dart';
import '../../../core/widgets/delta_badge.dart';
import '../../portfolio/data/mock_portfolio.dart';
import '../../portfolio/domain/card_models.dart';

/// Scanner V0 — simulation visuelle (sans caméra réelle ni ML Kit pour l'instant).
/// Reproduit les phases aiming → detecting → done du design.
enum _ScanPhase { aiming, detecting, done }

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({
    required this.onClose,
    required this.onScanned,
    super.key,
  });

  final VoidCallback onClose;
  final ValueChanged<TcgCard> onScanned;

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with TickerProviderStateMixin {
  _ScanPhase _phase = _ScanPhase.aiming;
  late final AnimationController _beam;

  // Carte détectée par défaut (Verdant Wyrm — index 2 dans la liste mock)
  TcgCard get _detected => MockPortfolio.cards[2];

  @override
  void initState() {
    super.initState();
    _beam = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    Future.delayed(const Duration(milliseconds: 1300), () {
      if (mounted) setState(() => _phase = _ScanPhase.detecting);
    });
    Future.delayed(const Duration(milliseconds: 2800), () {
      if (mounted) setState(() => _phase = _ScanPhase.done);
    });
  }

  @override
  void dispose() {
    _beam.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Stack(
        children: [
          // Fond simulant le viewfinder caméra
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.2),
                  radius: 0.7,
                  colors: [Color(0xFF1A1A22), Color(0xFF0A0A0C)],
                  stops: [0, 1],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                  child: Row(
                    children: [
                      _ScannerCloseButton(onTap: widget.onClose),
                      const Spacer(),
                      Text(
                        Strings.scannerTitle,
                        style: AppTypography.inter(
                          size: 13,
                          weight: FontWeight.w600,
                          color: const Color(0xD9FFFFFF),
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 40),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _Viewfinder(
                          phase: _phase,
                          beam: _beam,
                          card: _detected,
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: 240,
                          child: Text(
                            switch (_phase) {
                              _ScanPhase.aiming => Strings.scannerAiming,
                              _ScanPhase.detecting => Strings.scannerDetecting,
                              _ScanPhase.done => Strings.scannerMatchFound,
                            },
                            textAlign: TextAlign.center,
                            style: AppTypography.inter(
                              size: 13,
                              weight: _phase == _ScanPhase.done
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: _phase == _ScanPhase.done
                                  ? AppColors.gold
                                  : const Color(0xB3FFFFFF),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_phase == _ScanPhase.done)
                  _MatchSheet(
                    card: _detected,
                    onSkip: widget.onClose,
                    onAdd: () => widget.onScanned(_detected),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerCloseButton extends StatelessWidget {
  const _ScannerCloseButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0x80000000),
      shape: const CircleBorder(side: BorderSide(color: AppColors.line2)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox(
          width: 40,
          height: 40,
          child: Icon(Icons.close_rounded, size: 18, color: Colors.white),
        ),
      ),
    );
  }
}

class _Viewfinder extends StatelessWidget {
  const _Viewfinder({
    required this.phase,
    required this.beam,
    required this.card,
  });

  final _ScanPhase phase;
  final AnimationController beam;
  final TcgCard card;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 308,
      child: Stack(
        children: [
          if (phase != _ScanPhase.done)
            Positioned.fill(
              child: Opacity(
                opacity: 0.92,
                child: CardArtTile(card: card, width: 220, height: 308),
              ),
            ),
          if (phase == _ScanPhase.done)
            Positioned.fill(
              child: ColoredBox(
                color: AppColors.gold.withAlpha(0x2E),
              ),
            ),
          if (phase == _ScanPhase.detecting)
            AnimatedBuilder(
              animation: beam,
              builder: (_, _) => Positioned(
                left: 6,
                right: 6,
                top: 4 + beam.value * 296,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    gradient: const LinearGradient(
                      colors: [Colors.transparent, AppColors.gold, Colors.transparent],
                    ),
                    boxShadow: const [
                      BoxShadow(color: AppColors.gold, blurRadius: 14),
                    ],
                  ),
                ),
              ),
            ),
          // Coins dorés
          ..._corners(),
        ],
      ),
    );
  }

  List<Widget> _corners() {
    const size = 26.0;
    const t = 2.5;
    return [
      Positioned(
        top: 0,
        left: 0,
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: AppColors.gold, width: t),
              left: BorderSide(color: AppColors.gold, width: t),
            ),
            borderRadius: BorderRadius.only(topLeft: Radius.circular(16)),
          ),
        ),
      ),
      Positioned(
        top: 0,
        right: 0,
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: AppColors.gold, width: t),
              right: BorderSide(color: AppColors.gold, width: t),
            ),
            borderRadius: BorderRadius.only(topRight: Radius.circular(16)),
          ),
        ),
      ),
      Positioned(
        bottom: 0,
        left: 0,
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppColors.gold, width: t),
              left: BorderSide(color: AppColors.gold, width: t),
            ),
            borderRadius: BorderRadius.only(bottomLeft: Radius.circular(16)),
          ),
        ),
      ),
      Positioned(
        bottom: 0,
        right: 0,
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppColors.gold, width: t),
              right: BorderSide(color: AppColors.gold, width: t),
            ),
            borderRadius: BorderRadius.only(bottomRight: Radius.circular(16)),
          ),
        ),
      ),
    ];
  }
}

class _MatchSheet extends StatelessWidget {
  const _MatchSheet({
    required this.card,
    required this.onSkip,
    required this.onAdd,
  });

  final TcgCard card;
  final VoidCallback onSkip;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xEB141418),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.line2),
        ),
        child: Column(
          children: [
            Row(
              children: [
                CardArtTile(card: card, width: 48, height: 68),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        card.name,
                        style: AppTypography.inter(
                          size: 15,
                          weight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Text(card.code, style: AppTypography.mono(size: 11.5)),
                          const Text(' · ', style: TextStyle(color: AppColors.text3)),
                          Text(
                            card.set,
                            style: AppTypography.inter(
                              size: 11.5,
                              color: AppColors.text2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      Format.money(card.value),
                      style: AppTypography.num(
                        size: 15,
                        weight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    DeltaBadge(
                      value: card.change24,
                      pct: card.change24,
                      size: DeltaBadgeSize.sm,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  flex: 5,
                  child: SizedBox(
                    height: 44,
                    child: TextButton(
                      onPressed: onSkip,
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0x0AFFFFFF),
                        foregroundColor: AppColors.text0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: AppColors.line2),
                        ),
                      ),
                      child: Text(
                        Strings.scannerSkip,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.inter(
                          size: 13,
                          weight: FontWeight.w600,
                          color: AppColors.text0,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 7,
                  child: SizedBox(
                    height: 44,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [AppColors.gold, AppColors.goldDark],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gold.withAlpha(0x59),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: onAdd,
                          child: Center(
                            child: Text(
                              Strings.scannerAdd,
                              style: AppTypography.inter(
                                size: 13,
                                weight: FontWeight.w700,
                                color: const Color(0xFF191100),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
