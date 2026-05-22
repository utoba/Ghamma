import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class SilenceScreen extends StatefulWidget {
  const SilenceScreen({super.key});

  @override
  State<SilenceScreen> createState() => _SilenceScreenState();
}

class _SilenceScreenState extends State<SilenceScreen>
    with SingleTickerProviderStateMixin {
  // ── Timer state ────────────────────────────────────────────
  int _selectedMinutes = 20;
  int _totalSeconds = 0;
  int _elapsedSeconds = 0;
  bool _isRunning = false;
  Timer? _timer;

  // ── Audio ──────────────────────────────────────────────────
  final AudioPlayer _bellPlayer = AudioPlayer();
  static const String _bellUrl =
      'https://www.eoni.cloud/ANANDA/AUDIO/BELL/bell_ananda1.mp3';

  // ── Ring animation ─────────────────────────────────────────
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _totalSeconds = _selectedMinutes * 60;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _bellPlayer.dispose();
    super.dispose();
  }

  Future<void> _playBell() async {
    try {
      await _bellPlayer.setUrl(_bellUrl);
      await _bellPlayer.seek(Duration.zero);
      await _bellPlayer.play();
    } catch (_) {}
  }

  void _startStop() {
    if (_isRunning) {
      _timer?.cancel();
      setState(() => _isRunning = false);
    } else {
      if (_elapsedSeconds >= _totalSeconds) {
        setState(() => _elapsedSeconds = 0);
      }
      _playBell();
      setState(() => _isRunning = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_elapsedSeconds >= _totalSeconds) {
          _timer?.cancel();
          setState(() => _isRunning = false);
          _playBell();
        } else {
          setState(() => _elapsedSeconds++);
        }
      });
    }
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _elapsedSeconds = 0;
      _totalSeconds = _selectedMinutes * 60;
    });
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String get _displayTime {
    final remaining = _totalSeconds - _elapsedSeconds;
    return _formatTime(remaining.clamp(0, _totalSeconds));
  }

  double get _progress =>
      _totalSeconds > 0 ? _elapsedSeconds / _totalSeconds : 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1E18),
      body: Stack(
        children: [
          // ── Background gradient ──────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1A1E18),
                  Color(0xFF1A1E18),
                  Color(0x3A1A2A3A),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // ── Main content ─────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // ── Top bar — close a sinistra ───────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 16),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.06),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.08),
                            ),
                          ),
                          child: Icon(
                            Icons.close,
                            color: Colors.white.withOpacity(0.50),
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // ── Titolo ───────────────────────────────────
                const Text(
                  'S I L E N C E',
                  style: TextStyle(
                    color: Color(0xFFCCCCCC),
                    fontSize: 25,
                    fontWeight: FontWeight.w200,
                    letterSpacing: 10,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Meditation Timer',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.35),
                    fontSize: 12,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 2,
                  ),
                ),

                const Spacer(),

                // ── Timer ring ───────────────────────────────
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, _) {
                    return CustomPaint(
                      size: const Size(260, 260),
                      painter: _SilenceRingPainter(
                        progress: _progress,
                        pulse: _isRunning ? _pulseController.value : 0.0,
                      ),
                      child: SizedBox(
                        width: 260,
                        height: 260,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _displayTime,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.85),
                                  fontSize: 48,
                                  fontWeight: FontWeight.w200,
                                  letterSpacing: 4,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _isRunning ? 'running' : 'ready',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.25),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w300,
                                  letterSpacing: 3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const Spacer(),

                // ── Duration selector — centrato con Wrap ────
                if (!_isRunning && _elapsedSeconds == 0) ...[
                  Text(
                    'duration',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.30),
                      fontSize: 11,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: _durations.map((min) {
                        final selected = min == _selectedMinutes;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedMinutes = min;
                              _totalSeconds = min * 60;
                              _elapsedSeconds = 0;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 8),
                            decoration: BoxDecoration(
                              color: selected
                                  ? Colors.white.withOpacity(0.12)
                                  : Colors.white.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: selected
                                    ? Colors.white.withOpacity(0.25)
                                    : Colors.white.withOpacity(0.06),
                              ),
                            ),
                            child: Text(
                              '$min min',
                              style: TextStyle(
                                color: selected
                                    ? Colors.white.withOpacity(0.85)
                                    : Colors.white.withOpacity(0.35),
                                fontSize: 13,
                                fontWeight: FontWeight.w300,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 32),
                ] else ...[
                  const SizedBox(height: 88),
                ],

                // ── Start / Stop button ──────────────────────
                GestureDetector(
                  onTap: _startStop,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isRunning
                          ? Colors.white.withOpacity(0.08)
                          : Colors.white.withOpacity(0.12),
                      border: Border.all(
                        color: _isRunning
                            ? Colors.white.withOpacity(0.15)
                            : Colors.white.withOpacity(0.25),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      _isRunning ? Icons.pause : Icons.play_arrow,
                      color: Colors.white.withOpacity(0.75),
                      size: 28,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Reset button — più grande ────────────────
                AnimatedOpacity(
                  opacity: !_isRunning && _elapsedSeconds > 0 ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: GestureDetector(
                    onTap: !_isRunning && _elapsedSeconds > 0 ? _reset : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.10),
                        ),
                      ),
                      child: Text(
                        'R E S E T',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.40),
                          fontSize: 13,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 4,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 52),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Duration options ───────────────────────────────────────────────────────────
const List<int> _durations = [5, 10, 15, 20, 30, 45, 60];

// ── Ring Painter ───────────────────────────────────────────────────────────────
class _SilenceRingPainter extends CustomPainter {
  final double progress;
  final double pulse;

  _SilenceRingPainter({required this.progress, required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 16;

    // Glow pulse quando running
    if (pulse > 0) {
      final glowPaint = Paint()
        ..color = Colors.white.withOpacity(0.03 * pulse)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 24
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawCircle(center, radius, glowPaint);
    }

    // Track base
    final trackPaint = Paint()
      ..color = Colors.white.withOpacity(0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = Colors.white.withOpacity(0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        progressPaint,
      );

      // Dot alla fine dell'arco
      final angle = -math.pi / 2 + 2 * math.pi * progress;
      final dotX = center.dx + radius * math.cos(angle);
      final dotY = center.dy + radius * math.sin(angle);
      final dotPaint = Paint()
        ..color = Colors.white.withOpacity(0.80)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(dotX, dotY), 4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_SilenceRingPainter old) =>
      old.progress != progress || old.pulse != pulse;
}