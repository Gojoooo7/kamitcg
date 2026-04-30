import 'package:flutter/material.dart';

import '../../features/portfolio/domain/card_models.dart';
import '../theme/app_colors.dart';

/// Tuile d'illustration placeholder (no IP) — gradient + sigil abstrait.
/// Reproduit `CardArt` du design (atoms.jsx).
class CardArtTile extends StatelessWidget {
  const CardArtTile({
    required this.card,
    this.width = 56,
    this.height = 80,
    this.foilGlow = true,
    super.key,
  });

  final TcgCard card;
  final double width;
  final double height;
  final bool foilGlow;

  static List<Color> _gradientFor(CardArtKey k) => switch (k) {
        CardArtKey.a => AppColors.artA,
        CardArtKey.b => AppColors.artB,
        CardArtKey.c => AppColors.artC,
        CardArtKey.d => AppColors.artD,
        CardArtKey.e => AppColors.artE,
        CardArtKey.f => AppColors.artF,
        CardArtKey.g => AppColors.artG,
        CardArtKey.h => AppColors.artH,
      };

  static Color _ringFor(CardRarity r) => switch (r) {
        CardRarity.mythic => AppColors.rarityMythicRing,
        CardRarity.legendary => AppColors.rarityLegendaryRing,
        CardRarity.rare => AppColors.rarityRareRing,
        CardRarity.common => AppColors.rarityCommonRing,
      };

  @override
  Widget build(BuildContext context) {
    final radius = (width * 0.10).clamp(6.0, 24.0);
    final ring = _ringFor(card.rarity);
    final showFoilRing = card.foil && foilGlow;
    final gradient = _gradientFor(card.art);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          colors: gradient,
          begin: const Alignment(-0.6, -1),
          end: const Alignment(0.6, 1),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x73000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: showFoilRing ? ring : const Color(0x14FFFFFF),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius - 1),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _SigilPainter()),
            ),
            // Code label en bas
            Positioned(
              left: 4,
              right: 4,
              bottom: 3,
              child: Text(
                card.code,
                style: TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: (width * 0.13).clamp(7.0, 14.0),
                  color: const Color(0xC7FFFFFF),
                  letterSpacing: 0.04,
                  shadows: const [
                    Shadow(color: Color(0x80000000), blurRadius: 2, offset: Offset(0, 1)),
                  ],
                ),
              ),
            ),
            // Pastille foil
            if (card.foil)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: ring,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: ring, blurRadius: 8),
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

class _SigilPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Voile radial pour donner du relief
    const gradient = RadialGradient(
      center: Alignment(0, -0.3),
      radius: 0.85,
      colors: [
        Color(0x52FFFFFF),
        Color(0x0AFFFFFF),
        Color(0x8C000000),
      ],
      stops: [0.0, 0.6, 1.0],
    );
    canvas.drawRect(
      Offset.zero & size,
      Paint()..shader = gradient.createShader(Offset.zero & size),
    );

    // Sigil abstrait : cercle, croix, X
    final cx = size.width / 2;
    final cy = size.height * 0.45;
    final r1 = size.width * 0.20;
    final r2 = size.width * 0.11;

    final p1 = Paint()
      ..color = const Color(0x8CFFFFFF)
      ..strokeWidth = 0.9
      ..style = PaintingStyle.stroke;
    final p2 = Paint()
      ..color = const Color(0x59FFFFFF)
      ..strokeWidth = 0.9
      ..style = PaintingStyle.stroke;
    final p3 = Paint()
      ..color = const Color(0x4DFFFFFF)
      ..strokeWidth = 0.9
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(Offset(cx, cy), r1, p1);
    canvas.drawCircle(Offset(cx, cy), r2, p2);
    canvas.drawLine(Offset(cx - r1, cy), Offset(cx + r1, cy), p3);
    canvas.drawLine(Offset(cx, cy - r1), Offset(cx, cy + r1), p3);
    canvas.drawLine(Offset(cx - r2, cy - r2), Offset(cx + r2, cy + r2), p3);
    canvas.drawLine(Offset(cx - r2, cy + r2), Offset(cx + r2, cy - r2), p3);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
