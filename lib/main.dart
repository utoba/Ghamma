import 'dart:math';
import 'package:flutter/material.dart';

void main() {
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
      home: const PlayerScreen(),
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

// ─────────────────────────────────────────────
//  PLAYER SCREEN
// ─────────────────────────────────────────────
class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with TickerProviderStateMixin {
  late AnimationController _lissajousController;

  bool _isPlaying = false;

  // durata selezionata in minuti
  int _selectedMinutes = 20;
  final List<int> _minuteOptions = [
    5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60
  ];

  // secondi rimanenti — gestito direttamente senza AnimationController
  late int _remainingSeconds;

  // ticker manuale per il countdown (1 tick = 1 secondo)
  late AnimationController _tickController;

  bool _showDurationPicker = false;

  @override
  void initState() {
    super.initState();

    _remainingSeconds = _selectedMinutes * 60;

    _lissajousController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    );

    _tickController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _tickController.addStatusListener(_onTick);
  }

  void _onTick(AnimationStatus status) {
    if (!_isPlaying) return;
    if (status == AnimationStatus.completed) {
      setState(() {
        if (_remainingSeconds > 0) _remainingSeconds--;
      });
      if (_remainingSeconds <= 0) {
        setState(() => _isPlaying = false);
        _lissajousController.stop();
        return;
      }
      _tickController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _lissajousController.dispose();
    _tickController.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (_isPlaying) {
      setState(() => _isPlaying = false);
      _lissajousController.stop();
      _tickController.stop();
    } else {
      if (_remainingSeconds <= 0) {
        setState(() => _remainingSeconds = _selectedMinutes * 60);
      }
      setState(() => _isPlaying = true);
      _lissajousController.repeat();
      _tickController.forward(from: 0);
    }
  }

  void _setDuration(int minutes) {
    setState(() {
      _selectedMinutes = minutes;
      _remainingSeconds = minutes * 60; // aggiorna subito il display
      _showDurationPicker = false;
      _isPlaying = false;
    });
    _lissajousController.stop();
    _tickController.stop();
  }

  String _formatTime(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // gradient: scuro in alto-dx → caldo ambra in basso-sx
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Color(0xFF1A1E18),   // verde scuro
              Color(0xFF1A1E18),   // ancora scuro a metà
              Color(0x5973521F),   // #73521F ~35% opacity
            ],
            stops: [0.0, 0.45, 1.0],
          ),
        ),
        child: GestureDetector(
          onTap: () {
            if (_showDurationPicker) {
              setState(() => _showDurationPicker = false);
            }
          },
          child: SafeArea(
            child: Stack(
              children: [
                // ── layout principale ──
                Column(
                  children: [
                    const SizedBox(height: 24),

                    // ── 3 indicatori di pagina ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (i) {
                        final isActive = i == 1;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: isActive ? 24 : 8,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isActive
                                ? const Color.fromRGBO(30, 200, 80, 0.9)
                                : Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 32),

                    // ── card semitrasparente (si vede il gradient dietro) ──
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.08),
                              width: 1,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                // ── vectorscope ──
                                Expanded(
                                  child: AnimatedBuilder(
                                    animation: _lissajousController,
                                    builder: (_, __) => CustomPaint(
                                      painter: VectorscopePainter(
                                        t: _lissajousController.value,
                                        isPlaying: _isPlaying,
                                      ),
                                      child: const SizedBox.expand(),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 16),

                                // ── titolo traccia ──
                                Text(
                                  'VOID',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.85),
                                    fontSize: 28,
                                    letterSpacing: 10,
                                    fontWeight: FontWeight.w200,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Pure Tone',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.35),
                                    fontSize: 11,
                                    letterSpacing: 3.5,
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // ── timer countdown ──
                                Text(
                                  _formatTime(_remainingSeconds),
                                  style: const TextStyle(
                                    color: Color(0xFFCCCCCC),
                                    fontSize: 52,
                                    fontWeight: FontWeight.w200,
                                    letterSpacing: 6,
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // ── bottoni ──
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // orologio + durata
                                    GestureDetector(
                                      onTap: () => setState(() =>
                                          _showDurationPicker =
                                              !_showDurationPicker),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.09),
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          border: Border.all(
                                            color: Colors.white.withOpacity(0.12),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.timer_outlined,
                                              color: Colors.white.withOpacity(0.65),
                                              size: 18,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '$_selectedMinutes min',
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(0.65),
                                                fontSize: 14,
                                                letterSpacing: 1.2,
                                                fontWeight: FontWeight.w300,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    const SizedBox(width: 20),

                                    // START / STOP
                                    GestureDetector(
                                      onTap: _togglePlay,
                                      child: Container(
                                        width: 72,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.09),
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          border: Border.all(
                                            color: Colors.white.withOpacity(0.12),
                                            width: 1,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            _isPlaying ? 'STOP' : 'START',
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.75),
                                              fontSize: 12,
                                              letterSpacing: 2.5,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 8),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),

                // ── dropdown selezione durata ──
                if (_showDurationPicker)
                  Positioned(
                    bottom: 100,
                    left: 24,
                    right: 24,
                    child: GestureDetector(
                      onTap: () {}, // blocca chiusura accidentale
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1E18).withOpacity(0.95),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.55),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 12),
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: _minuteOptions.map((min) {
                            final isSelected = min == _selectedMinutes;
                            return GestureDetector(
                              onTap: () => _setDuration(min),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color.fromRGBO(30, 200, 80, 0.18)
                                      : Colors.white.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color.fromRGBO(30, 200, 80, 0.55)
                                        : Colors.white.withOpacity(0.08),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  '$min min',
                                  style: TextStyle(
                                    color: isSelected
                                        ? const Color.fromRGBO(30, 200, 80, 1)
                                        : Colors.white.withOpacity(0.55),
                                    fontSize: 13,
                                    letterSpacing: 1.2,
                                    fontWeight: isSelected
                                        ? FontWeight.w400
                                        : FontWeight.w300,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}