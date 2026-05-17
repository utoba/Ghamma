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
    final r = size.width * 0.42;

    const steps = 300;
    const freqA = 2.0;
    const freqB = 3.0;

    final passes = [
      (width: 6.0, opacity: 0.08),
      (width: 2.5, opacity: 0.35),
      (width: 1.0, opacity: 0.9),
    ];

    for (final pass in passes) {
      final paint = Paint()
        ..color = Color.fromRGBO(30, 200, 80, pass.opacity)
        ..strokeWidth = pass.width
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final path = Path();
      for (int i = 0; i <= steps; i++) {
        final angle = (i / steps) * 2 * pi;
        final x = cx + r * sin(freqA * angle + t * 2 * pi);
        final y = cy + r * sin(freqB * angle + t * 2 * pi * 0.7);
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