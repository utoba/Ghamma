import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../logo_painter.dart';
import '../menu_screen.dart';

// ─────────────────────────────────────────────────────────────────
// SplashScreen — schermata di apertura GHAMMA
//
// Sequenza animazione (totale ~3.6 sec):
//   0.0 – 0.6s  sfondo scuro, silenzio
//   0.6 – 1.6s  logo fade-in + scala 0.82→1.0
//   1.0 – 2.0s  "GHAMMA" fade-in con letter-spacing che si apre
//   1.8 – 2.6s  sottotitolo fade-in
//   2.8 – 3.6s  tutto fade-out → MenuScreen
// ─────────────────────────────────────────────────────────────────
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  late AnimationController _master;
  late AnimationController _rotController;

  late Animation<double> _logoOpacity;
  late Animation<double> _logoScale;
  late Animation<double> _titleOpacity;
  late Animation<double> _titleSpacing;
  late Animation<double> _subtitleOpacity;
  late Animation<double> _screenOpacity;

  @override
  void initState() {
    super.initState();

    // rotazione lenta del logo (loop infinito)
    _rotController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 120),
    )..repeat();

    // controller master: governa tutta la sequenza
    _master = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    );

    // Logo: fade-in 0.17→0.44, scala 0.17→0.50
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _master,
        curve: const Interval(0.17, 0.44, curve: Curves.easeOut),
      ),
    );
    _logoScale = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(
        parent: _master,
        curve: const Interval(0.17, 0.50, curve: Curves.easeOutCubic),
      ),
    );

    // Titolo: fade-in 0.28→0.56, letter-spacing 4→16
    _titleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _master,
        curve: const Interval(0.28, 0.56, curve: Curves.easeOut),
      ),
    );
    _titleSpacing = Tween<double>(begin: 4.0, end: 16.0).animate(
      CurvedAnimation(
        parent: _master,
        curve: const Interval(0.28, 0.65, curve: Curves.easeOutCubic),
      ),
    );

    // Sottotitolo: fade-in 0.50→0.72
    _subtitleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _master,
        curve: const Interval(0.50, 0.72, curve: Curves.easeOut),
      ),
    );

    // Fade-out globale: 0.78→1.0
    _screenOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _master,
        curve: const Interval(0.78, 1.0, curve: Curves.easeIn),
      ),
    );

    _master.forward();

    // Quando l'animazione finisce, vai al MenuScreen
    _master.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: Duration.zero,
            pageBuilder: (_, __, ___) => const MenuScreen(),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _master.dispose();
    _rotController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_master, _rotController]),
      builder: (context, _) {
        return Opacity(
          opacity: _screenOpacity.value,
          child: Scaffold(
            backgroundColor: const Color(0xFF1A1E18),
            body: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    Color(0xFF1A1E18),
                    Color(0xFF1A1E18),
                    Color(0x5973521F),
                  ],
                  stops: [0.0, 0.45, 1.0],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    // ── Logo loto ──
                    Opacity(
                      opacity: _logoOpacity.value,
                      child: Transform.scale(
                        scale: _logoScale.value,
                        child: GhammaLogo(
                          size: 180,
                          rotation: _rotController.value * 2 * math.pi,
                          opacity: 1.0,
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── Nome ──
                    Opacity(
                      opacity: _titleOpacity.value,
                      child: Text(
                        'G H A M M A',
                        style: TextStyle(
                          color: const Color(0xFFCCCCCC),
                          fontSize: 32,
                          fontWeight: FontWeight.w200,
                          letterSpacing: _titleSpacing.value,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // ── Sottotitolo ──
                    Opacity(
                      opacity: _subtitleOpacity.value,
                      child: Text(
                        'sound and silence for the mind',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.30),
                          fontSize: 13,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 3.5,
                        ),
                      ),
                    ),

                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}