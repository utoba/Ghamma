import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'menu_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const AnandaApp());
}

class AnandaApp extends StatelessWidget {
  const AnandaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ananda',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1A1E18),
      ),
      home: const MenuScreen(),
    );
  }
}

// ─────────────────────────────────────────────
//  TIMER RING PAINTER
// ─────────────────────────────────────────────
class TimerRingPainter extends CustomPainter {
  final double progress; // 0.0 = inizio, 1.0 = fine
  final bool isPlaying;

  TimerRingPainter({required this.progress, required this.isPlaying});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = (size.width / 2) - 6;

    // cerchio base grigio scuro
    final bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(Offset(cx, cy), radius, bgPaint);

    if (!isPlaying && progress == 0.0) return;

    // arco bianco che avanza
    final fgPaint = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      -pi / 2,      // parte dall'alto
      sweepAngle,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(TimerRingPainter old) =>
      old.progress != progress || old.isPlaying != isPlaying;
}

// ─────────────────────────────────────────────
//  VECTORSCOPE PAINTER
// ─────────────────────────────────────────────
class VectorscopePainter extends CustomPainter {
  final double t;
  final bool isPlaying;

  VectorscopePainter({required this.t, required this.isPlaying});

  @override
void paint(Canvas canvas, Size size) {
  final cx = size.width / 2;
  final cy = size.height / 2;
  final r = size.width * 0.32;

  const steps = 400;
  final speed = t * 2 * pi;

  final passes = [
    (width: 6.0, opacity: 0.06),
    (width: 2.5, opacity: 0.30),
    (width: 1.0, opacity: 0.95),
  ];

  for (final pass in passes) {
    final paint = Paint()
      ..color = Color.fromRGBO(30, 200, 80, pass.opacity)
      ..strokeWidth = pass.width
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    for (int i = 0; i <= steps; i++) {
      final angle = (i / steps) * 2 * pi;
      final x = cx + r * sin(2 * angle + speed);
      final y = cy + r * sin(3 * angle);  // Y statico — solo X ruota
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }
}

  @override
  bool shouldRepaint(VectorscopePainter old) =>
      old.t != t || old.isPlaying != isPlaying;
}

// Stelle
class StarfieldPainter extends CustomPainter {
  final double t;

  StarfieldPainter({required this.t});

  static final List<_Star> _stars = _generateStars();

  static List<_Star> _generateStars() {
    final rng = Random(42);
    final stars = <_Star>[];

    // magnitude 1 — 8 stelle grandi
    for (int i = 0; i < 8; i++) {
      stars.add(_Star(
        x: rng.nextDouble(),
        y: rng.nextDouble() * 0.85,
        r: 2.2,
        phase: rng.nextDouble() * pi * 2,
        speed: 2.5 + rng.nextDouble() * 2.0,
        color: [
          const Color(0xFFFFFFFF),
          const Color(0xFFFFE8C0),
          const Color(0xFFC8D8FF),
        ][rng.nextInt(3)],
        minOpacity: 0.3,
        maxOpacity: 0.95,
      ));
    }
    // magnitude 2 — 14 stelle medie
    for (int i = 0; i < 14; i++) {
      stars.add(_Star(
        x: rng.nextDouble(),
        y: rng.nextDouble() * 0.90,
        r: 1.5,
        phase: rng.nextDouble() * pi * 2,
        speed: 3.5 + rng.nextDouble() * 3.0,
        color: [
          const Color(0xFFFFFFFF),
          const Color(0xFFFFE8C0),
          const Color(0xFFC8D8FF),
        ][rng.nextInt(3)],
        minOpacity: 0.15,
        maxOpacity: 0.75,
      ));
    }
    // magnitude 3 — 20 stelle piccole
    for (int i = 0; i < 20; i++) {
      stars.add(_Star(
        x: rng.nextDouble(),
        y: rng.nextDouble() * 0.95,
        r: 1.0,
        phase: rng.nextDouble() * pi * 2,
        speed: 4.0 + rng.nextDouble() * 4.0,
        color: [
          const Color(0xFFFFFFFF),
          const Color(0xFFDDEEFF),
          const Color(0xFFFFE8C0),
        ][rng.nextInt(3)],
        minOpacity: 0.10,
        maxOpacity: 0.55,
      ));
    }
    // magnitude 4-5 — 35 stelle tenui
    for (int i = 0; i < 35; i++) {
      stars.add(_Star(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        r: 0.6,
        phase: rng.nextDouble() * pi * 2,
        speed: 5.0 + rng.nextDouble() * 5.0,
        color: const Color(0xFFAABBD4),
        minOpacity: 0.08,
        maxOpacity: 0.38,
      ));
    }

    // Orsa Maggiore — posizioni fisse normalizzate
    final orsaMaggiore = [
      (0.200, 0.225), (0.277, 0.208), (0.354, 0.199),
      (0.410, 0.211), (0.397, 0.249), (0.226, 0.168), (0.172, 0.140),
    ];
    for (final pos in orsaMaggiore) {
      stars.add(_Star(
        x: pos.$1, y: pos.$2, r: 1.5,
        phase: rng.nextDouble() * pi * 2,
        speed: 4.0 + rng.nextDouble() * 2.5,
        color: const Color(0xFFFFFFFF),
        minOpacity: 0.5, maxOpacity: 0.95,
        isConstellation: true,
      ));
    }

    // Cassiopeia — W caratteristico
    final cassiopeia = [
      (0.654, 0.136), (0.697, 0.116), (0.744, 0.133),
      (0.790, 0.113), (0.833, 0.130),
    ];
    for (final pos in cassiopeia) {
      stars.add(_Star(
        x: pos.$1, y: pos.$2, r: 1.5,
        phase: rng.nextDouble() * pi * 2,
        speed: 4.0 + rng.nextDouble() * 2.5,
        color: const Color(0xFFFFFFFF),
        minOpacity: 0.5, maxOpacity: 0.95,
        isConstellation: true,
      ));
    }

    return stars;
  }

  // linee costellazioni — indici nell'array stars (dopo le prime 77 random)
  static const List<List<int>> _orsaLines = [
    [0, 1], [1, 2], [2, 3], [3, 4], [4, 2], [1, 5], [5, 6]
  ];
  static const List<List<int>> _cassLines = [
    [0, 1], [1, 2], [2, 3], [3, 4]
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final orsaOffset = 77;
    final cassOffset = 77 + 7;

    // disegna linee Orsa Maggiore
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    for (final pair in _orsaLines) {
      final a = _stars[orsaOffset + pair[0]];
      final b = _stars[orsaOffset + pair[1]];
      canvas.drawLine(
        Offset(a.x * size.width, a.y * size.height),
        Offset(b.x * size.width, b.y * size.height),
        linePaint,
      );
    }
    for (final pair in _cassLines) {
      final a = _stars[cassOffset + pair[0]];
      final b = _stars[cassOffset + pair[1]];
      canvas.drawLine(
        Offset(a.x * size.width, a.y * size.height),
        Offset(b.x * size.width, b.y * size.height),
        linePaint,
      );
    }

    // disegna stelle
    for (final star in _stars) {
      final opacity = star.minOpacity +
          (star.maxOpacity - star.minOpacity) *
              (0.5 + 0.5 * sin(t * 2 * pi * (1 / star.speed) + star.phase));
      final paint = Paint()
        ..color = star.color.withOpacity(opacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(star.x * size.width, star.y * size.height),
        star.r,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(StarfieldPainter old) => old.t != t;
}

class _Star {
  final double x, y, r, phase, speed, minOpacity, maxOpacity;
  final Color color;
  final bool isConstellation;
  const _Star({
    required this.x, required this.y, required this.r,
    required this.phase, required this.speed,
    required this.color, required this.minOpacity, required this.maxOpacity,
    this.isConstellation = false,
  });
}