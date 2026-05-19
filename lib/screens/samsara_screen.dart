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
      // velocità aumentata: 0.00008 → 0.00035
      setState(() => _wavePhase += dt.inMilliseconds * 0.00035);
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
      _lastTick = Duration.zero;
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

            // ── background linee costellazione ──
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

                                  // ── cerchio con barre radiali dentro ──
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
                    top: 20, left: 35,
                    child: GestureDetector(
                      onTap: _closeScreen,
                      child: _iconBtn(Icons.close),
                    ),
                  ),
                  Positioned(
                    top: 20, right: 35,
                    child: GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        PageRouteBuilder(
                          transitionDuration: const Duration(milliseconds: 1200),
                          pageBuilder: (_, __, ___) => const SamsaraInfoScreen(),
                          transitionsBuilder: (_, animation, __, child) {
                            final curved = CurvedAnimation(
                              parent: animation, curve: Curves.easeOutQuart,
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
// Cerchio con barre radiali animate dentro
// ────────────────────────────────────────────────
class SamsaraCirclePainter extends CustomPainter {
  final double wavePhase;
  final double amplitude;
  final bool isPlaying;

  // seed fisse per ogni barra — frequenze e fasi diverse
  static final List<Map<String, double>> _bars = List.generate(60, (i) {
    final rng = Random(i * 7 + 3);
    return {
      'f1': 1.2 + rng.nextDouble() * 2.5,   // range più ampio
      'f2': 0.5 + rng.nextDouble() * 1.5,
      'f3': 0.3 + rng.nextDouble() * 0.8,   // terza componente per più varietà
      'p1': rng.nextDouble() * pi * 2,
      'p2': rng.nextDouble() * pi * 2,
      'p3': rng.nextDouble() * pi * 2,
      'base': 0.05 + rng.nextDouble() * 0.06,
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

    // clip dentro il cerchio
    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: center, radius: radius - 1)),
    );

    final numBars = _bars.length;
    final maxBarH = radius * 0.62;  // barre più lunghe
    final minBarH = radius * 0.03;
    final innerR  = radius * 0.28;

    for (int i = 0; i < numBars; i++) {
      final s = _bars[i];
      final angle = (i / numBars) * 2 * pi - pi / 2;

      double h;
      if (isPlaying && amplitude > 0) {
        // tre componenti sinusoidali → movimento molto più vario
        h = s['base']!
          + sin(wavePhase * s['f1']! + s['p1']!) * 0.30
          + sin(wavePhase * s['f2']! + s['p2']!) * 0.18
          + sin(wavePhase * s['f3']! + s['p3']!) * 0.10;
        h = h.clamp(0.02, 1.0);
        h = (minBarH + h * maxBarH) * amplitude;
      } else {
        h = minBarH * 1.2;
      }

      final outerR = innerR + h;
      final x1 = center.dx + cos(angle) * innerR;
      final y1 = center.dy + sin(angle) * innerR;
      final x2 = center.dx + cos(angle) * outerR;
      final y2 = center.dy + sin(angle) * outerR;

      final normalizedH = h / maxBarH;
      final alpha = isPlaying
          ? (0.20 + normalizedH * 0.65) * amplitude
          : 0.07;

      final paint = Paint()
        ..color = Color.fromRGBO(30, 200, 80, alpha.clamp(0.0, 1.0))
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
    }

    canvas.restore();

    // cerchio outline sopra
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
// Background: Orione ingrandito — poche linee visibili
// ────────────────────────────────────────────────
class ConstellationBgPainter extends CustomPainter {

  // 7 nodi principali di Orione, ingranditi su tutto lo schermo
  static const _nodes = [
    (0.10, 0.10),  // 0 Betelgeuse
    (0.68, 0.13),  // 1 Bellatrix
    (0.11, 0.38),  // 2 Rigel
    (0.42, 0.32),  // 3 Saiph
    (0.30, 0.48),  // 4 Alnitak
    (0.50, 0.65),  // 5 Alnilam
    (0.70, 0.53),  // 6 Mintaka
  ];

  // solo 10 linee — le connessioni principali di Orione
  static const _lines = [
    [0, 1],  // spalle
    [0, 2],  // Betelgeuse → Rigel
    [1, 3],  // Bellatrix → Saiph
    [2, 3],  // piedi
    [4, 5],  // cintura
    [5, 6],  // cintura
    [0, 4],  // spalla sx → cintura
    [1, 6],  // spalla dx → cintura
    [0, 5],  // Betelgeuse → centro cintura
    [1, 5],  // Bellatrix → centro cintura
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.07)  // molto più visibile
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final dotMain = Paint()
      ..color = Colors.white.withOpacity(0.10)
      ..style = PaintingStyle.fill;

    Offset p(double x, double y) => Offset(x * size.width, y * size.height);

    for (final pair in _lines) {
      final a = _nodes[pair[0]];
      final b = _nodes[pair[1]];
      canvas.drawLine(p(a.$1, a.$2), p(b.$1, b.$2), linePaint);
    }

    // solo i 7 nodi principali, dimensioni diverse per magnitudine
    final radii = [2.8, 2.2, 2.8, 2.2, 1.6, 2.0, 1.6];
    for (int i = 0; i < _nodes.length; i++) {
      canvas.drawCircle(p(_nodes[i].$1, _nodes[i].$2), radii[i], dotMain);
    }
  }

  @override
  bool shouldRepaint(ConstellationBgPainter old) => false;
}