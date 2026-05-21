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

class TimerRingPainter extends CustomPainter {
  final double progress;
  final bool isPlaying;

  TimerRingPainter({required this.progress, required this.isPlaying});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = (size.width / 2) - 6;

    final bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(Offset(cx, cy), radius, bgPaint);

    if (!isPlaying && progress == 0.0) return;

    final fgPaint = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(TimerRingPainter old) =>
      old.progress != progress || old.isPlaying != isPlaying;
}

class VectorscopePainter extends CustomPainter {
  final double t;
  final bool isPlaying;
  final double amplitude;

  VectorscopePainter({
    required this.t,
    required this.isPlaying,
    this.amplitude = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.32 * amplitude;

    const steps = 400;
    final speed = t * 2 * pi;

    final passes = [
      (width: 6.0, opacity: 0.06 * amplitude),
      (width: 2.5, opacity: 0.30 * amplitude),
      (width: 1.0, opacity: 0.95 * amplitude),
    ];

    for (final pass in passes) {
      final paint = Paint()
        ..color = Color.fromRGBO(30, 200, 80, pass.opacity.clamp(0.0, 1.0))
        ..strokeWidth = pass.width
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final path = Path();
      for (int i = 0; i <= steps; i++) {
        final angle = (i / steps) * 2 * pi;
        final x = cx + r * sin(2 * angle + speed);
        final y = cy + r * sin(3 * angle);
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
      old.t != t || old.isPlaying != isPlaying || old.amplitude != amplitude;
}

class StarfieldPainter extends CustomPainter {
  final double t;
  StarfieldPainter({required this.t});

  static final List<_Star> _stars = _generateStars();

  static List<_Star> _generateStars() {
    final rng = Random(42);
    final stars = <_Star>[];

    for (int i = 0; i < 8; i++) {
      stars.add(_Star(
        x: rng.nextDouble(),
        y: rng.nextDouble() * 0.68,
        r: 2.2,
        phase: rng.nextDouble() * pi * 2,
        speed: 1.2 + rng.nextDouble() * 1.0,
        color: [
          const Color(0xFFFFFFFF),
          const Color(0xFFFFE8C0),
          const Color(0xFFC8D8FF),
        ][rng.nextInt(3)],
        minOpacity: 0.05,
        maxOpacity: 0.5,
      ));
    }
    for (int i = 0; i < 14; i++) {
      stars.add(_Star(
        x: rng.nextDouble(),
        y: rng.nextDouble() * 0.75,
        r: 1.5,
        phase: rng.nextDouble() * pi * 2,
        speed: 1.5 + rng.nextDouble() * 1.5,
        color: [
          const Color(0xFFFFFFFF),
          const Color(0xFFFFE8C0),
          const Color(0xFFC8D8FF),
        ][rng.nextInt(3)],
        minOpacity: 0.03,
        maxOpacity: 0.75,
      ));
    }
    for (int i = 0; i < 18; i++) {
      stars.add(_Star(
        x: rng.nextDouble(),
        y: rng.nextDouble() * 0.88,
        r: 1.0,
        phase: rng.nextDouble() * pi * 2,
        speed: 1.8 + rng.nextDouble() * 2.0,
        color: [
          const Color(0xFFFFFFFF),
          const Color(0xFFDDEEFF),
          const Color(0xFFFFE8C0),
        ][rng.nextInt(3)],
        minOpacity: 0.02,
        maxOpacity: 0.55,
      ));
    }
    for (int i = 0; i < 25; i++) {
      stars.add(_Star(
        x: rng.nextDouble(),
        y: rng.nextDouble() * 0.80,
        r: 0.6,
        phase: rng.nextDouble() * pi * 2,
        speed: 2.0 + rng.nextDouble() * 2.5,
        color: const Color(0xFFAABBD4),
        minOpacity: 0.01,
        maxOpacity: 0.35,
      ));
    }

    final orsaMaggiore = [
      (0.200, 0.205), (0.277, 0.188), (0.354, 0.179),
      (0.410, 0.191), (0.397, 0.229), (0.226, 0.148), (0.172, 0.120),
    ];
    for (final pos in orsaMaggiore) {
      stars.add(_Star(
        x: pos.$1, y: pos.$2, r: 1.5,
        phase: rng.nextDouble() * pi * 2,
        speed: 1.5 + rng.nextDouble() * 1.0,
        color: const Color(0xFFFFFFFF),
        minOpacity: 0.2, maxOpacity: 0.7,
        isConstellation: true,
      ));
    }

    final cassiopeia = [
      (0.654, 0.116), (0.697, 0.096), (0.744, 0.113),
      (0.790, 0.093), (0.833, 0.110),
    ];
    for (final pos in cassiopeia) {
      stars.add(_Star(
        x: pos.$1, y: pos.$2, r: 1.5,
        phase: rng.nextDouble() * pi * 2,
        speed: 1.5 + rng.nextDouble() * 1.0,
        color: const Color(0xFFFFFFFF),
        minOpacity: 0.2, maxOpacity: 0.6,
        isConstellation: true,
      ));
    }

    return stars;
  }

  static const List<List<int>> _orsaLines = [
    [0, 1], [1, 2], [2, 3], [3, 4], [4, 2], [1, 5], [5, 6]
  ];
  static const List<List<int>> _cassLines = [
    [0, 1], [1, 2], [2, 3], [3, 4]
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final blueGlow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.0, -1.0),
        radius: 1.0,
        colors: [
          const Color(0xFF1A3A6A).withOpacity(0.45),
          const Color(0xFF0D1F3C).withOpacity(0.20),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.7));
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height * 0.7),
      blueGlow,
    );

    const orsaOffset = 65;
    const cassOffset = orsaOffset + 7;

    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.10)
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

    for (final star in _stars) {
      final raw = sin(t * 80 * pi * (1 / star.speed) + star.phase);
      final flicker = (raw * raw * raw).abs() > 0.3 ? raw * raw : 0.0;
      final opacity = star.minOpacity +
          (star.maxOpacity - star.minOpacity) * ((flicker + 1.0) / 2.0);
      final paint = Paint()
        ..color = star.color.withOpacity(opacity.clamp(0.0, 1.0))
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