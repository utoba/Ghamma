import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:just_audio/just_audio.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'samsara_info_screen.dart';

class SamsaraScreen extends StatefulWidget {
  final VoidCallback? onOpenInfo;
  final void Function(VoidCallback)? onRegisterInfo;

  const SamsaraScreen({
    super.key,
    this.onOpenInfo,
    this.onRegisterInfo,
  });

  @override
  State<SamsaraScreen> createState() => _SamsaraScreenState();
}

class _SamsaraScreenState extends State<SamsaraScreen>
    with SingleTickerProviderStateMixin {

  final AudioPlayer _player = AudioPlayer();
  static const String _folderUrl = 'https://www.eoni.cloud/ANANDA/AUDIO/SAMSARA/';

  bool _isPlaying = false;
  int _elapsedSeconds = 0;
  bool _audioStarted = false;
  bool _seekingManually = false;
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

    widget.onRegisterInfo?.call(_openInfo);

    _waveTicker = createTicker((elapsed) {
      if (!_isPlaying) return;
      final dt = elapsed - _lastTick;
      _lastTick = elapsed;
      setState(() => _wavePhase += dt.inMilliseconds * 0.00095);
    });

    _player.currentIndexStream.listen((index) {
      if (index == null || !_isPlaying || !_audioStarted) return;
      if (_seekingManually) {
        _seekingManually = false;
        return;
      }
      _fadeOut(onComplete: _fadeIn);
    });
  }

  void _openInfo() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 480),
      pageBuilder: (_, __, ___) => const SamsaraInfoScreen(),
      transitionBuilder: (_, animation, __, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
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
        if (_amplitude <= 0.0) { t.cancel(); onComplete?.call(); }
      });
    });
  }

  void _fadeOutAudio({VoidCallback? onComplete}) {
    int tick = 0;
    const totalTicks = 50;
    Timer.periodic(const Duration(milliseconds: 30), (t) {
      tick++;
      _player.setVolume((1.0 - tick / totalTicks).clamp(0.0, 1.0));
      if (tick >= totalTicks) { t.cancel(); onComplete?.call(); }
    });
  }

  void _fadeInAudio() {
    int tick = 0;
    const totalTicks = 50;
    Timer.periodic(const Duration(milliseconds: 30), (t) {
      tick++;
      _player.setVolume((tick / totalTicks).clamp(0.0, 1.0));
      if (tick >= totalTicks) t.cancel();
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
    await Future.delayed(const Duration(milliseconds: 300));
    _audioStarted = true;
  }

  void _startTimer() {
    _sessionStartTime = DateTime.now();
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isPlaying) return;
      final elapsed = DateTime.now().difference(_sessionStartTime!).inSeconds;
      setState(() => _elapsedSeconds = elapsed);
      FlutterForegroundTask.updateService(
        notificationTitle: 'GHAMMA',
        notificationText: _formatTime(_elapsedSeconds),
      );
    });
  }

  void _togglePlay() {
    if (_isPlaying) {
      _ticker?.cancel();
      _audioStarted = false;
      setState(() => _isPlaying = false);
      _fadeOut();
      _fadeOutAudio(onComplete: () {
        _waveTicker.stop();
        _player.stop();
        _player.setVolume(1.0);
        FlutterForegroundTask.stopService();
        if (mounted) setState(() {
          _elapsedSeconds = 0;
          _amplitude = 0.0;
          _wavePhase = 0.0;
          _lastTick = Duration.zero;
        });
      });
    } else {
      setState(() => _isPlaying = true);
      _lastTick = Duration.zero;
      _waveTicker.start();
      FlutterForegroundTask.startService(
        serviceId: 257,
        notificationTitle: 'GHAMMA — active meditation',
        notificationText: '00:00',
      );
      _startAudio();
      _startTimer();
      _fadeIn();
    }
  }

  void _skipWithFade(Future<void> Function() seekAction) {
    _seekingManually = true;
    _fadeOut(onComplete: () {
      seekAction().then((_) => _fadeIn());
    });
    _fadeOutAudio(onComplete: _fadeInAudio);
  }

  Future<void> _skipNext() { _skipWithFade(_player.seekToNext); return Future.value(); }
  Future<void> _skipPrev() { _skipWithFade(_player.seekToPrevious); return Future.value(); }

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

  Widget _swipeHandle() => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Center(
      child: Container(
        width: 36, height: 4,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: const ScrollBehavior().copyWith(scrollbars: false),
      child: Scaffold(
        body: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [Color(0xFF1A2035), Color(0xFF1A1E18), Color(0x5973521F)],
                  stops: [0.0, 0.45, 1.0],
                ),
              ),
            ),
            const CustomPaint(
              painter: ConstellationBgPainter(),
              child: SizedBox.expand(),
            ),
            SafeArea(
              child: Stack(
                children: [
                  Column(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
                            ),
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 24, right: 24),
                                  child: Column(
                                    children: [
                                      // drag handle top — swipe down per info
                                      Center(
                                        child: Container(
                                          width: 36, height: 4,
                                          margin: const EdgeInsets.only(top: 15, bottom: 40),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.18),
                                            borderRadius: BorderRadius.circular(2),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 24),
                                    child: CustomPaint(
                                      painter: SamsaraCirclePainter(
                                        wavePhase: _wavePhase,
                                        amplitude: _amplitude,
                                        isPlaying: _isPlaying,
                                      ),
                                      child: const SizedBox.expand(),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(left: 24, right: 24),
                                  child: Column(
                                    children: [
                                      const SizedBox(height: 16),
                                      Text('SAMSARA', style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 28, letterSpacing: 10, fontWeight: FontWeight.w200)),
                                      const SizedBox(height: 6),
                                      Text('Ambient Soundscapes', style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 11, letterSpacing: 3.5, fontWeight: FontWeight.w300)),
                                      const SizedBox(height: 8),
                                      Text(_formatTime(_elapsedSeconds), style: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 52, fontWeight: FontWeight.w200, letterSpacing: 6)),
                                      const SizedBox(height: 24),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          GestureDetector(onTap: _skipPrev, child: _controlBtn(Icons.skip_previous_rounded)),
                                          const SizedBox(width: 16),
                                          GestureDetector(
                                            onTap: _togglePlay,
                                            child: SizedBox(
                                              width: 130, height: 48,
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withOpacity(0.09),
                                                  borderRadius: BorderRadius.circular(14),
                                                  border: Border.all(color: Colors.white.withOpacity(0.12), width: 1),
                                                ),
                                                child: Center(child: Text(_isPlaying ? 'STOP' : 'PLAY', style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 12, letterSpacing: 2.5, fontWeight: FontWeight.w400))),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          GestureDetector(onTap: _skipNext, child: _controlBtn(Icons.skip_next_rounded)),
                                        ],
                                      ),
                                      const SizedBox(height: 35),
                                    ],
                                  ),
                                ),
                                // handle swipe up — fuori dal padding
                                _swipeHandle(),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

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

// ── Painters ─────────────────────────────────────────────────────

class SamsaraCirclePainter extends CustomPainter {
  final double wavePhase;
  final double amplitude;
  final bool isPlaying;

  static final List<Map<String, double>> _bars = List.generate(60, (i) {
    final rng = Random(i * 7 + 3);
    return {
      'f1': 1.2 + rng.nextDouble() * 2.5,
      'f2': 0.5 + rng.nextDouble() * 1.5,
      'f3': 0.3 + rng.nextDouble() * 0.8,
      'p1': rng.nextDouble() * pi * 2,
      'p2': rng.nextDouble() * pi * 2,
      'p3': rng.nextDouble() * pi * 2,
      'base': 0.05 + rng.nextDouble() * 0.06,
    };
  });

  SamsaraCirclePainter({required this.wavePhase, required this.amplitude, required this.isPlaying});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide / 2) - 16;
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: radius - 1)));
    final numBars = _bars.length;
    final maxBarH = radius * 0.85;
    final minBarH = radius * 0.03;
    final innerR  = radius * 0.18;
    for (int i = 0; i < numBars; i++) {
      final s = _bars[i];
      final angle = (i / numBars) * 2 * pi - pi / 2;
      double h;
      if (isPlaying && amplitude > 0) {
        h = s['base']!
          + sin(wavePhase * s['f1']! + s['p1']!) * 0.52
          + sin(wavePhase * s['f2']! + s['p2']!) * 0.30
          + sin(wavePhase * s['f3']! + s['p3']!) * 0.14;
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
      final alpha = isPlaying ? (0.20 + normalizedH * 0.65) * amplitude : 0.07;
      final paint = Paint()
        ..color = Color.fromRGBO(30, 200, 80, alpha.clamp(0.0, 1.0))
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(SamsaraCirclePainter old) =>
      old.wavePhase != wavePhase || old.amplitude != amplitude || old.isPlaying != isPlaying;
}

class ConstellationBgPainter extends CustomPainter {
  static const _nodes = [
    (0.90, 0.10), (0.87, 0.68), (0.62, 0.11), (0.68, 0.42),
    (0.52, 0.30), (0.35, 0.50), (0.47, 0.70), (0.76, 0.82),
    (0.29, 0.16), (0.22, 0.84), (0.14, 0.37), (0.44, 0.05),
    (0.62, 0.89), (0.78, 0.53), (0.79, 0.21), (0.35, 0.87),
    (0.93, 0.45), (0.14, 0.76), (0.12, 0.13),
  ];
  static const _linesMain = [[0,1],[0,2],[1,3],[2,3],[4,5],[5,6],[0,4],[1,6],[0,5],[1,5]];
  static const _linesSec  = [[0,6],[2,6],[2,5],[3,4],[3,6],[7,1],[7,6],[8,4],[8,5],[9,6],[9,5],[10,5],[10,8],[11,2],[11,4],[12,1],[12,6],[13,3],[14,0],[15,9],[17,9],[18,10],[18,8]];
  final double pulseValue;
  const ConstellationBgPainter({this.pulseValue = 0.5});

  @override
  void paint(Canvas canvas, Size size) {
    Offset p(double x, double y) => Offset(x * size.width, y * size.height);
    final mainAlpha = 0.06 + pulseValue * 0.10;
    final linePaintMain = Paint()..color = Colors.white.withOpacity(mainAlpha)..strokeWidth = 0.8..strokeCap = StrokeCap.round;
    for (final pair in _linesMain) {
      final a = _nodes[pair[0]]; final b = _nodes[pair[1]];
      canvas.drawLine(p(a.$1, a.$2), p(b.$1, b.$2), linePaintMain);
    }
    final secAlpha = 0.04 + (1.0 - pulseValue) * 0.07;
    final linePaintSec = Paint()..color = Colors.white.withOpacity(secAlpha)..strokeWidth = 0.5..strokeCap = StrokeCap.round;
    for (final pair in _linesSec) {
      final a = _nodes[pair[0]]; final b = _nodes[pair[1]];
      canvas.drawLine(p(a.$1, a.$2), p(b.$1, b.$2), linePaintSec);
    }
    final dotMain = Paint()..color = Colors.white.withOpacity(0.08 + pulseValue * 0.08)..style = PaintingStyle.fill;
    final radiiMain = [2.8, 2.2, 2.8, 2.2, 1.6, 2.0, 1.6];
    for (int i = 0; i < 7; i++) canvas.drawCircle(p(_nodes[i].$1, _nodes[i].$2), radiiMain[i], dotMain);
    final dotSec = Paint()..color = Colors.white.withOpacity(0.05 + pulseValue * 0.05)..style = PaintingStyle.fill;
    for (int i = 7; i < _nodes.length; i++) canvas.drawCircle(p(_nodes[i].$1, _nodes[i].$2), 1.2, dotSec);
  }

  @override
  bool shouldRepaint(ConstellationBgPainter old) => old.pulseValue != pulseValue;
}