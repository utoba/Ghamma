import 'dart:math' as math;
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────
// GhammaLogo — widget riusabile ovunque nell'app
//
// Uso minimo:
//   GhammaLogo(size: 120)
//
// Con rotazione animata (passare un AnimationController 0→1 in loop):
//   GhammaLogo(size: 120, rotation: _controller.value * 2 * pi)
//
// Con opacità ridotta per sfondo:
//   GhammaLogo(size: 300, opacity: 0.08)
// ─────────────────────────────────────────────────────────────────
class GhammaLogo extends StatelessWidget {
  final double size;
  final double rotation;   // radianti, default 0
  final double opacity;    // 0.0 – 1.0, default 1.0

  const GhammaLogo({
    super.key,
    required this.size,
    this.rotation = 0.0,
    this.opacity = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _LotusLogoPainter(
          rotation: rotation,
          opacity: opacity,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Painter interno — tutti i parametri sono proporzionali a [size]
// quindi il logo scala perfettamente a qualsiasi dimensione.
// ─────────────────────────────────────────────────────────────────
class _LotusLogoPainter extends CustomPainter {
  final double rotation;
  final double opacity;

  const _LotusLogoPainter({
    required this.rotation,
    required this.opacity,
  });

  // Disegna un petalo a mandorla centrato nell'origine,
  // puntato verso l'alto, ruotato di [angle] radianti.
  void _drawPetal(
    Canvas canvas,
    Offset center,
    double angle,
    double length,
    double width,
    Paint fillPaint,
    Paint strokePaint,
  ) {
    final path = Path()
      ..moveTo(0, 0)
      ..cubicTo(
         width,        -length * 0.45,
         width * 0.5,  -length * 0.85,
         0,            -length,
      )
      ..cubicTo(
        -width * 0.5,  -length * 0.85,
        -width,        -length * 0.45,
         0,             0,
      )
      ..close();

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, strokePaint);
    canvas.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = math.min(size.width, size.height) * 0.46; // raggio massimo petali
    const n = 8;        // numero petali per strato
    const twoPi = math.pi * 2;

    // ── helper opacity-aware ──
    double o(double base) => (base * opacity).clamp(0.0, 1.0);

    Paint fill(double a) => Paint()
      ..color = Colors.white.withOpacity(o(a))
      ..style = PaintingStyle.fill;

    Paint stroke(double a, double w) => Paint()
      ..color = Colors.white.withOpacity(o(a))
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round;

    // ── Strato 1: petali esterni principali ──
    for (int i = 0; i < n; i++) {
      final angle = rotation + twoPi / n * i;
      _drawPetal(canvas, center, angle,
          r,        r * 0.18,
          fill(0.10), stroke(0.45, 0.9));
    }

    // ── Strato 1b: petali esterni interleaved (+22.5°), più corti ──
    for (int i = 0; i < n; i++) {
      final angle = rotation + twoPi / n * i + twoPi / 16;
      _drawPetal(canvas, center, angle,
          r * 0.80, r * 0.14,
          fill(0.07), stroke(0.30, 0.7));
    }

    // ── Strato 2: petali medi sfasati di 22.5° ──
    for (int i = 0; i < n; i++) {
      final angle = rotation + twoPi / n * i + twoPi / 16;
      _drawPetal(canvas, center, angle,
          r * 0.62, r * 0.13,
          fill(0.10), stroke(0.40, 0.8));
    }

    // ── Strato 3: petali interni allineati ai principali ──
    for (int i = 0; i < n; i++) {
      final angle = rotation + twoPi / n * i;
      _drawPetal(canvas, center, angle,
          r * 0.38, r * 0.10,
          fill(0.12), stroke(0.50, 0.8));
    }

    // ── Cerchi concentrici ──
    for (final fr in [0.145, 0.100, 0.060]) {
      canvas.drawCircle(center, r * fr, stroke(0.40, 0.7));
    }

    // ── Stami: 8 segmenti radiali ──
    final stamenPaint = stroke(0.28, 0.6);
    for (int i = 0; i < n; i++) {
      final angle = rotation + twoPi / n * i;
      final r1 = r * 0.060;
      final r2 = r * 0.130;
      canvas.drawLine(
        Offset(center.dx + r1 * math.sin(angle),
               center.dy - r1 * math.cos(angle)),
        Offset(center.dx + r2 * math.sin(angle),
               center.dy - r2 * math.cos(angle)),
        stamenPaint,
      );
    }

    // ── Punto centrale ──
    canvas.drawCircle(center, r * 0.024,
        fill(0.70)..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(_LotusLogoPainter old) =>
      old.rotation != rotation || old.opacity != opacity;
}