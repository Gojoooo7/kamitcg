import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../utils/format.dart';

/// Pill arrondi affichant une variation (vert si hausse, rouge si baisse).
/// Reproduit le composant `DeltaBadge` du design (atoms.jsx).
enum DeltaBadgeSize { sm, md, lg }

class DeltaBadge extends StatelessWidget {
  const DeltaBadge({
    required this.value,
    this.pct,
    this.size = DeltaBadgeSize.md,
    super.key,
  });

  final double value;

  /// Si fourni, affiche le pct au lieu de la valeur brute.
  final double? pct;
  final DeltaBadgeSize size;

  @override
  Widget build(BuildContext context) {
    final up = value >= 0;
    final color = up ? AppColors.up : AppColors.down;
    final bg = up ? AppColors.upSoft : AppColors.downSoft;
    final fontSize = switch (size) {
      DeltaBadgeSize.sm => 11.0,
      DeltaBadgeSize.md => 12.0,
      DeltaBadgeSize.lg => 13.0,
    };
    final padX = size == DeltaBadgeSize.lg ? 10.0 : 8.0;
    final padY = size == DeltaBadgeSize.lg ? 6.0 : 4.0;

    final label = pct != null
        ? Format.pct(pct!)
        : (value >= 0 ? '+' : '') + value.toStringAsFixed(2);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: padX, vertical: padY),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomPaint(
            size: const Size(10, 10),
            painter: _DeltaArrowPainter(up: up, color: color),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.num(
              size: fontSize,
              weight: FontWeight.w600,
              color: color,
              letterSpacing: -0.005,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeltaArrowPainter extends CustomPainter {
  _DeltaArrowPainter({required this.up, required this.color});
  final bool up;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path();
    if (up) {
      path
        ..moveTo(2, 7)
        ..lineTo(5, 3)
        ..lineTo(8, 7);
    } else {
      path
        ..moveTo(2, 3)
        ..lineTo(5, 7)
        ..lineTo(8, 3);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _DeltaArrowPainter old) =>
      old.up != up || old.color != color;
}
