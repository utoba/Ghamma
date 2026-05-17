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