import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Grand graphique linéaire avec fill dégradé, crosshair et point pulsant.
/// Reproduit le `LineChart` du design (atoms.jsx) en CustomPainter natif Flutter.
class LineChartView extends StatefulWidget {
  const LineChartView({
    required this.points,
    required this.up,
    this.height = 168,
    this.animate = true,
    super.key,
  });

  final List<double> points;
  final bool up;
  final double height;
  final bool animate;

  @override
  State<LineChartView> createState() => _LineChartViewState();
}

class _LineChartViewState extends State<LineChartView>
    with TickerProviderStateMixin {
  late final AnimationController _drawCtl;
  late final AnimationController _pulseCtl;

  @override
  void initState() {
    super.initState();
    _drawCtl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _pulseCtl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
    if (widget.animate) {
      _drawCtl.forward();
    } else {
      _drawCtl.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant LineChartView old) {
    super.didUpdateWidget(old);
    if (old.points != widget.points && widget.animate) {
      _drawCtl
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _drawCtl.dispose();
    _pulseCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: Listenable.merge([_drawCtl, _pulseCtl]),
        builder: (_, _) => CustomPaint(
          painter: _LineChartPainter(
            points: widget.points,
            up: widget.up,
            drawProgress: _drawCtl.value,
            pulse: _pulseCtl.value,
          ),
        ),
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter({
    required this.points,
    required this.up,
    required this.drawProgress,
    required this.pulse,
  });

  final List<double> points;
  final bool up;
  final double drawProgress;
  final double pulse;

  static const double _pad = 4;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final w = size.width;
    final h = size.height;
    final min = points.reduce((a, b) => a < b ? a : b);
    final max = points.reduce((a, b) => a > b ? a : b);
    final range = max - min == 0 ? 1.0 : max - min;
    final step = (w - _pad * 2) / (points.length - 1);

    final coords = <Offset>[
      for (var i = 0; i < points.length; i++)
        Offset(
          _pad + i * step,
          h - _pad - ((points[i] - min) / range) * (h - _pad * 2),
        ),
    ];

    final stroke = up ? AppColors.up : AppColors.down;
    final strokeDark = up ? const Color(0xFF00B85F) : const Color(0xFFC82E48);

    // Ligne guide horizontale (dashée pâle)
    final guidePaint = Paint()
      ..color = const Color(0x0AFFFFFF)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    _drawDashedLine(
      canvas,
      Offset(_pad, h * 0.5),
      Offset(w - _pad, h * 0.5),
      guidePaint,
      dash: 2,
      gap: 4,
    );

    // Path de la ligne
    final linePath = Path()..moveTo(coords[0].dx, coords[0].dy);
    for (var i = 1; i < coords.length; i++) {
      linePath.lineTo(coords[i].dx, coords[i].dy);
    }

    // Fill dégradé sous la ligne
    final fillPath = Path.from(linePath)
      ..lineTo(w - _pad, h - _pad)
      ..lineTo(_pad, h - _pad)
      ..close();
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [stroke.withAlpha(0x47), stroke.withAlpha(0x00)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(fillPath, fillPaint);

    // Ligne (avec progression du tracé)
    final linePaint = Paint()
      ..shader = LinearGradient(
        colors: [strokeDark, stroke],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final metric = linePath.computeMetrics().first;
    final partial = metric.extractPath(0, metric.length * drawProgress);
    canvas.drawPath(partial, linePaint);

    // Crosshair sur ~66% du tracé (réplique du hover figé du design)
    final hi = (coords.length * 0.66).floor().clamp(0, coords.length - 1);
    final hover = coords[hi];
    final crossPaint = Paint()
      ..color = AppColors.gold.withAlpha(0x52)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    _drawDashedLine(
      canvas,
      Offset(hover.dx, _pad),
      Offset(hover.dx, h - _pad),
      crossPaint,
      dash: 3,
      gap: 3,
    );
    canvas.drawCircle(hover, 6, Paint()..color = stroke.withAlpha(0x2E));
    canvas.drawCircle(hover, 3.4, Paint()..color = stroke);
    canvas.drawCircle(hover, 1.4, Paint()..color = AppColors.bg0);

    // Point final pulsant
    final last = coords.last;
    // pulse ∈ [0,1] : on l'utilise pour faire grossir et rétrécir l'auréole.
    final pulseR = 6 + 6 * (1 - (2 * pulse - 1).abs());
    final pulseA = (0.20 * (1 - (2 * pulse - 1).abs()) * 255).round();
    canvas.drawCircle(last, pulseR, Paint()..color = stroke.withAlpha(pulseA));
    canvas.drawCircle(last, 3.2, Paint()..color = stroke);
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset a,
    Offset b,
    Paint paint, {
    double dash = 2,
    double gap = 4,
  }) {
    final total = (b - a).distance;
    final dx = (b.dx - a.dx) / total;
    final dy = (b.dy - a.dy) / total;
    var t = 0.0;
    while (t < total) {
      final start = Offset(a.dx + dx * t, a.dy + dy * t);
      final end = Offset(
        a.dx + dx * (t + dash).clamp(0.0, total),
        a.dy + dy * (t + dash).clamp(0.0, total),
      );
      canvas.drawLine(start, end, paint);
      t += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter old) =>
      old.points != points ||
      old.up != up ||
      old.drawProgress != drawProgress ||
      old.pulse != pulse;
}
