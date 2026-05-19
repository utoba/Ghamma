import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:just_audio/just_audio.dart';
import 'package:http/http.dart' as http;
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'samsara_info_screen.dart';

class SamsaraScreen extends StatefulWidget {
  const SamsaraScreen({super.key});

  @override
  State<SamsaraScreen> createState() => _SamsaraScreenState();
}

class _SamsaraScreenState extends State<SamsaraScreen>
    with SingleTickerProviderStateMixin {

  final AudioPlayer _player = AudioPlayer();
  static const String _folderUrl =
      'https://www.eoni.cloud/ANANDA/AUDIO/SAMSARA/';

  bool _isPlaying = false;
  int _elapsedSeconds = 0;
  Timer? _ticker;
  DateTime? _sessionStartTime;

  double _amplitude = 0.0;
  Timer? _fadeTicker;

  // fase waveform animata con Ticker Flutter (smooth, no setState loop)
  late Ticker _waveTicker;
  double _wavePhase = 0.0;
  Duration _lastTick = Duration.zero;

  @override
  void initState() {
    super.initState();

    _waveTicker = createTicker((elapsed) {
      if (!_isPlaying) return;
      final dt = elapsed - _lastTick;
      _lastTick = elapsed;
      setState(() => _wavePhase += dt.inMilliseconds * 0.00008);
    });

    _player.currentIndexStream.listen((index) {
      if (index == null || !_isPlaying) return;
      _fadeOut(onComplete: _fadeIn);
    });
  }

  void _fadeIn() {
    _fadeTicker?.cancel();
    _fadeTicker = Timer.periodic(const Duration(milliseconds: 30), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        _amplitude = (_amplitude + 0.02).clamp(0.0, 1.0);
        if (_amplitude >= 1.0) t.cancel();
      });
    });
  }

  void _fadeOut({VoidCallback? onComplete}) {
    _fadeTicker?.cancel();
    _fadeTicker = Timer.periodic(const Duration(milliseconds: 30), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        _amplitude = (_amplitude - 0.02).clamp(0.0, 1.0);
        if (_amplitude <= 0.0) {
          t.cancel();
          onComplete?.call();
        }
      });
    });
  }

  Future<List<String>> _fetchTracks(String folderUrl) async {
    final response = await http.get(Uri.parse(folderUrl));
    if (response.statusCode != 200) return [];
    final regExp = RegExp(r'href="([^"]+\.mp3)"', caseSensitive: false);
    final matches = regExp.allMatches(response.body);
    return matches.map((m) => folderUrl + m.group(1)!).toList();
  }

  Future<void> _startAudio() async {
    final tracks = await _fetchTracks(_folderUrl);
    if (tracks.isEmpty) return;
    tracks.shuffle(Random());
    final playlist = ConcatenatingAudioSource(
      children: tracks.map((url) => AudioSource.uri(Uri.parse(url))).toList(),
    );
    await _player.setAudioSource(playlist);
    await _player.setLoopMode(LoopMode.all);
    await _player.setVolume(1.0);
    await _player.play();
  }

  void _startTimer() {
    _sessionStartTime = DateTime.now();
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isPlaying) return;
      final elapsed = DateTime.now().difference(_sessionStartTime!).inSeconds;
      setState(() => _elapsedSeconds = elapsed);
      FlutterForegroundTask.updateService(
        notificationTitle: 'Ananda',
        notificationText: _formatTime(_elapsedSeconds),
      );
    });
  }

  void _togglePlay() {
    if (_isPlaying) {
      _ticker?.cancel();
      _fadeTicker?.cancel();
      _waveTicker.stop();
      _player.stop();
      WakelockPlus.disable();
      FlutterForegroundTask.stopService();
      setState(() {
        _isPlaying = false;
        _elapsedSeconds = 0;
        _amplitude = 0.0;
        _wavePhase = 0.0;
        _lastTick = Duration.zero;
      });
    } else {
      setState(() => _isPlaying = true);
      _waveTicker.start();
      WakelockPlus.enable();
      FlutterForegroundTask.startService(
        serviceId: 257,
        notificationTitle: 'Ananda — meditazione attiva',
        notificationText: '00:00',
      );
      _startAudio();
      _startTimer();
      _fadeIn();
    }
  }

  Future<void> _skipNext() async => _player.seekToNext();
  Future<void> _skipPrev() async => _player.seekToPrevious();

  void _closeScreen() {
    _ticker?.cancel();
    _fadeTicker?.cancel();
    _waveTicker.stop();
    _player.stop();
    WakelockPlus.disable();
    FlutterForegroundTask.stopService();
    Navigator.pop(context);
  }

  String _formatTime(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _fadeTicker?.cancel();
    _waveTicker.dispose();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: const ScrollBehavior().copyWith(scrollbars: false),
      child: Scaffold(
        body: Stack(
          children: [

            // ── sfondo gradient ──
            Container(
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
            ),

            // ── background linee costellazione ingrandita ──
            CustomPaint(
              painter: ConstellationBgPainter(),
              child: const SizedBox.expand(),
            ),

            // ── contenuto ──
            SafeArea(
              child: Stack(
                children: [
                  Column(
                    children: [
                      const SizedBox(height: 8),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
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

                                  // ── cerchio con animazione dentro ──
                                  Expanded(
                                    child: CustomPaint(
                                      painter: SamsaraCirclePainter(
                                        wavePhase: _wavePhase,
                                        amplitude: _amplitude,
                                        isPlaying: _isPlaying,
                                      ),
                                      child: const SizedBox.expand(),
                                    ),
                                  ),

                                  const SizedBox(height: 16),
                                  Text(
                                    'SAMSARA',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.85),
                                      fontSize: 28,
                                      letterSpacing: 10,
                                      fontWeight: FontWeight.w200,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Ambient Soundscapes',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.35),
                                      fontSize: 11,
                                      letterSpacing: 3.5,
                                      fontWeight: FontWeight.w300,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _formatTime(_elapsedSeconds),
                                    style: const TextStyle(
                                      color: Color(0xFFCCCCCC),
                                      fontSize: 52,
                                      fontWeight: FontWeight.w200,
                                      letterSpacing: 6,
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // ── controlli ──
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      GestureDetector(
                                        onTap: _skipPrev,
                                        child: _controlBtn(Icons.skip_previous_rounded),
                                      ),
                                      const SizedBox(width: 16),
                                      GestureDetector(
                                        onTap: _togglePlay,
                                        child: SizedBox(
                                          width: 130,
                                          height: 48,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.09),
                                              borderRadius: BorderRadius.circular(14),
                                              border: Border.all(
                                                color: Colors.white.withOpacity(0.12),
                                                width: 1,
                                              ),
                                            ),
                                            child: Center(
                                              child: Text(
                                                _isPlaying ? 'STOP' : 'PLAY',
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
                                      ),
                                      const SizedBox(width: 16),
                                      GestureDetector(
                                        onTap: _skipNext,
                                        child: _controlBtn(Icons.skip_next_rounded),
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
                      const SizedBox(height: 8),
                    ],
                  ),

                  Positioned(
                    top: 20,
                    left: 35,
                    child: GestureDetector(
                      onTap: _closeScreen,
                      child: _iconBtn(Icons.close),
                    ),
                  ),
                  Positioned(
                    top: 20,
                    right: 35,
                    child: GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        PageRouteBuilder(
                          transitionDuration: const Duration(milliseconds: 1200),
                          pageBuilder: (_, __, ___) => const SamsaraInfoScreen(),
                          transitionsBuilder: (_, animation, __, child) {
                            final curved = CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutQuart,
                            );
                            return ScaleTransition(
                              scale: Tween<double>(begin: 0.1, end: 1.0).animate(curved),
                              child: FadeTransition(
                                opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curved),
                                child: child,
                              ),
                            );
                          },
                        ),
                      ),
                      child: _iconBtn(Icons.info_outline),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon) => Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
        ),
        child: Icon(icon, color: Colors.white.withOpacity(0.55), size: 16),
      );

  Widget _controlBtn(IconData icon) => Container(
        width: 48, height: 48,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.09),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.12), width: 1),
        ),
        child: Icon(icon, color: Colors.white.withOpacity(0.65), size: 22),
      );
}

// ────────────────────────────────────────────────
// Cerchio con waveform ambient dentro
// ────────────────────────────────────────────────
class SamsaraCirclePainter extends CustomPainter {
  final double wavePhase;
  final double amplitude;
  final bool isPlaying;

  static final List<Map<String, double>> _bars = List.generate(60, (i) {
    final rng = Random(i * 7 + 3);
    return {
      'f1': 0.6 + rng.nextDouble() * 1.2,
      'f2': 0.2 + rng.nextDouble() * 0.6,
      'p1': rng.nextDouble() * pi * 2,
      'p2': rng.nextDouble() * pi * 2,
      'base': 0.04 + rng.nextDouble() * 0.08,
    };
  });

  SamsaraCirclePainter({
    required this.wavePhase,
    required this.amplitude,
    required this.isPlaying,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide / 2) - 16;

    // ── clip tutto dentro il cerchio ──
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: radius - 1)));

    // ── waveform a barre radiali dentro il cerchio ──
    final numBars = _bars.length;
    final maxBarH = radius * 0.55;
    final minBarH = radius * 0.02;

    for (int i = 0; i < numBars; i++) {
      final s = _bars[i];
      final angle = (i / numBars) * 2 * pi - pi / 2;

      double h;
      if (isPlaying && amplitude > 0) {
        h = s['base']! +
            sin(wavePhase * s['f1']! + s['p1']!) * 0.18 +
            sin(wavePhase * s['f2']! + s['p2']!) * 0.08;
        h = h.clamp(0.03, 1.0);
        h = (minBarH + h * maxBarH) * amplitude;
      } else {
        h = minBarH * 1.5;
      }

      final innerR = radius * 0.30;
      final outerR = innerR + h;

      final x1 = center.dx + cos(angle) * innerR;
      final y1 = center.dy + sin(angle) * innerR;
      final x2 = center.dx + cos(angle) * outerR;
      final y2 = center.dy + sin(angle) * outerR;

      final alpha = isPlaying
          ? (0.15 + (h / maxBarH) * 0.5) * amplitude
          : 0.06;

      final paint = Paint()
        ..color = Color.fromRGBO(30, 200, 80, alpha.clamp(0.0, 1.0))
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
    }

    canvas.restore();

    // ── cerchio outline sopra tutto ──
    final ringPaint = Paint()
      ..color = Colors.white.withOpacity(0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius, ringPaint);
  }

  @override
  bool shouldRepaint(SamsaraCirclePainter old) =>
      old.wavePhase != wavePhase ||
      old.amplitude != amplitude ||
      old.isPlaying != isPlaying;
}

// ────────────────────────────────────────────────
// Background: zoom su Orione ingrandito
// poche linee lunghe, quasi niente punti
// ────────────────────────────────────────────────
class ConstellationBgPainter extends CustomPainter {

  // Orione ingrandito e spostato — come se fosse uno zoom
  // coordinate normalizzate, occupano gran parte dello schermo
  static const _nodes = [
    (0.15, 0.18),  // 0 Betelgeuse (spalla sx)
    (0.75, 0.12),  // 1 Bellatrix (spalla dx)
    (0.10, 0.72),  // 2 Rigel (piede sx)
    (0.80, 0.68),  // 3 Saiph (piede dx)
    (0.28, 0.44),  // 4 Alnitak (cintura sx)
    (0.50, 0.42),  // 5 Alnilam (cintura centro)
    (0.72, 0.40),  // 6 Mintaka (cintura dx)
    (0.45, 0.05),  // 7 Meissa (testa)
    (0.20, 0.30),  // 8 spalla sx → cintura
    (0.70, 0.26),  // 9 spalla dx → cintura
  ];

  static const _lines = [
    [0, 1],  // spalle
    [0, 2],  // spalla sx → piede sx
    [1, 3],  // spalla dx → piede dx
    [4, 5],  // cintura
    [5, 6],  // cintura
    [0, 7],  // spalla sx → testa
    [1, 7],  // spalla dx → testa
    [0, 8],  // spalla sx → punto intermedio
    [8, 4],  // → cintura sx
    [1, 9],  // spalla dx → punto intermedio
    [9, 6],  // → cintura dx
  ];

  // stelle piccole sparse extra (solo dot, no linee)
  static const _extraDots = [
    (0.35, 0.82), (0.60, 0.90), (0.88, 0.50),
    (0.05, 0.55), (0.92, 0.22), (0.55, 0.60),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.055)
      ..strokeWidth = 0.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // dot principali — appena visibili
    final dotMain = Paint()
      ..color = Colors.white.withOpacity(0.20)
      ..style = PaintingStyle.fill;

    // dot extra — ancora più tenui
    final dotExtra = Paint()
      ..color = Colors.white.withOpacity(0.09)
      ..style = PaintingStyle.fill;

    Offset p(double x, double y) => Offset(x * size.width, y * size.height);

    // linee
    for (final pair in _lines) {
      final a = _nodes[pair[0]];
      final b = _nodes[pair[1]];
      canvas.drawLine(p(a.$1, a.$2), p(b.$1, b.$2), linePaint);
    }

    // dot principali solo sulle stelle vere di Orione (0-6)
    for (int i = 0; i <= 6; i++) {
      final nd = _nodes[i];
      // stelle della cintura più piccole
      final r = (i >= 4 && i <= 6) ? 1.2 : 2.0;
      canvas.drawCircle(p(nd.$1, nd.$2), r, dotMain);
    }

    // dot extra sparsi
    for (final d in _extraDots) {
      canvas.drawCircle(p(d.$1, d.$2), 0.9, dotExtra);
    }
  }

  @override
  bool shouldRepaint(ConstellationBgPainter old) => false;
}