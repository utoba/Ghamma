import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
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
    with TickerProviderStateMixin {

  final AudioPlayer _player = AudioPlayer();
  static const String _folderUrl =
      'https://www.eoni.cloud/ANANDA/AUDIO/SAMSARA/';

  late AnimationController _waveController;

  bool _isPlaying = false;
  int _elapsedSeconds = 0;
  Timer? _ticker;
  DateTime? _sessionStartTime;
  double _wavePhase = 0.0;
  double _waveAmplitude = 0.0;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 16),
        )..addListener(() {
        if (_isPlaying) {
            setState(() => _wavePhase += 0.03);
        }
    });
    _player.currentIndexStream.listen((index) {
        if (index == null) return;
        _fadeOutWave(onComplete: () => _fadeInWave());
    });
  }

  Future<List<String>> _fetchTracks(String folderUrl) async {
    final response = await http.get(Uri.parse(folderUrl));
    if (response.statusCode != 200) return [];
    final regExp = RegExp(r'href="([^"]+\.mp3)"', caseSensitive: false);
    final matches = regExp.allMatches(response.body);
    return matches
        .map((m) => folderUrl + m.group(1)!)
        .toList();
  }

  Future<void> _startAudio() async {
    final tracks = await _fetchTracks(_folderUrl);
    if (tracks.isEmpty) return;
    tracks.shuffle(Random());
    final playlist = ConcatenatingAudioSource(
      children: tracks
          .map((url) => AudioSource.uri(Uri.parse(url)))
          .toList(),
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
      final elapsed =
          DateTime.now().difference(_sessionStartTime!).inSeconds;
      setState(() => _elapsedSeconds = elapsed);
      FlutterForegroundTask.updateService(
        notificationTitle: 'Ananda — meditazione attiva',
        notificationText: _formatTime(_elapsedSeconds),
      );
    });
  }

  void _togglePlay() {
    if (_isPlaying) {
      _ticker?.cancel();
      _fadeOutWave();
      _player.stop();
      _waveController.stop();
      WakelockPlus.disable();
      FlutterForegroundTask.stopService();
      setState(() {
        _isPlaying = false;
        _elapsedSeconds = 0;
      });
    } else {
      setState(() => _isPlaying = true);
      _waveController.repeat();
      WakelockPlus.enable();
      FlutterForegroundTask.startService(
        serviceId: 257,
        notificationTitle: 'Ananda — meditazione attiva',
        notificationText: '00:00',
      );
      _startAudio();
      _startTimer();
      _fadeInWave();
    }
  }

  void _fadeInWave() {
  Timer.periodic(const Duration(milliseconds: 50), (timer) {
    if (!mounted) { timer.cancel(); return; }
    setState(() => _waveAmplitude += 0.01);
    if (_waveAmplitude >= 1.0) {
      _waveAmplitude = 1.0;
      timer.cancel();
    }
  });
}

void _fadeOutWave({VoidCallback? onComplete}) {
  Timer.periodic(const Duration(milliseconds: 50), (timer) {
    if (!mounted) { timer.cancel(); return; }
    setState(() => _waveAmplitude -= 0.01);
    if (_waveAmplitude <= 0.0) {
      _waveAmplitude = 0.0;
      timer.cancel();
      onComplete?.call();
    }
  });
}

  Future<void> _skipNext() async {
    await _player.seekToNext();
  }

  Future<void> _skipPrev() async {
    await _player.seekToPrevious();
  }

  void _closeScreen() {
    _ticker?.cancel();
    _player.stop();
    _waveController.stop();
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
    _player.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: const ScrollBehavior().copyWith(scrollbars: false),
      child: Scaffold(
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
          child: SafeArea(
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

                                // ── waveform ──
                                Expanded(
                                  child: AnimatedBuilder(
                                    animation: _waveController,
                                    builder: (_, __) => CustomPaint(
                                      painter: WaveformPainter(
                                        t: _wavePhase,
                                        isPlaying: _isPlaying,
                                        amplitude: _waveAmplitude,
                                      ),
                                      child: const SizedBox.expand(),
                                    ),
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
                                const SizedBox(height: 24),
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
                                    // skip indietro
                                    GestureDetector(
                                      onTap: _skipPrev,
                                      child: _controlBtn(
                                        Icons.skip_previous_rounded,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    // play/stop
                                    GestureDetector(
                                      onTap: _togglePlay,
                                      child: Container(
                                        width: 72,
                                        height: 48,
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
                                    const SizedBox(width: 16),
                                    // skip avanti
                                    GestureDetector(
                                      onTap: _skipNext,
                                      child: _controlBtn(
                                        Icons.skip_next_rounded,
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
                    const SizedBox(height: 8),
                  ],
                ),

                // ── bottone X ──
                Positioned(
                  top: 20,
                  left: 20,
                  child: GestureDetector(
                    onTap: _closeScreen,
                    child: _iconBtn(Icons.close),
                  ),
                ),

                // ── bottone info ──
                Positioned(
                  top: 20,
                  right: 20,
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      PageRouteBuilder(
                        transitionDuration: const Duration(milliseconds: 1200),
                        pageBuilder: (_, __, ___) =>
                            const SamsaraInfoScreen(),
                        transitionsBuilder: (_, animation, __, child) {
                          final curved = CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutQuart,
                          );
                          return ScaleTransition(
                            scale: Tween<double>(
                                    begin: 0.1, end: 1.0)
                                .animate(curved),
                            child: FadeTransition(
                              opacity: Tween<double>(
                                      begin: 0.0, end: 1.0)
                                  .animate(curved),
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
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Icon(icon, color: Colors.white.withOpacity(0.55), size: 16),
    );
  }

  Widget _controlBtn(IconData icon) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.09),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withOpacity(0.12),
          width: 1,
        ),
      ),
      child: Icon(icon, color: Colors.white.withOpacity(0.65), size: 22),
    );
  }
}

// ── Waveform Painter ──
class WaveformPainter extends CustomPainter {
  final double t;
  final bool isPlaying;
  final double amplitude;

  static final List<Map<String, double>> _seeds = List.generate(70, (_) {
    final rng = Random();
    return {
      'f1': 0.8 + rng.nextDouble() * 1.0,
      'f2': 0.3 + rng.nextDouble() * 0.5,
      'p1': rng.nextDouble() * pi * 2,
      'p2': rng.nextDouble() * pi * 2,
      'base': 0.06 + rng.nextDouble() * 0.10,
    };
  });

  WaveformPainter({required this.t, required this.isPlaying, required this.amplitude,});

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    final numBars = _seeds.length;
    final barW = size.width / numBars;
    final gap = barW * 0.30;
    final maxH = size.height * 0.42;
    final phase = t;

    for (int i = 0; i < numBars; i++) {
      final s = _seeds[i];
      double amp;
      if (isPlaying) {
        amp = s['base']! +
            sin(phase * s['f1']! + s['p1']!) * 0.20 +
            sin(phase * s['f2']! + s['p2']!) * 0.10;
        amp = amp.clamp(0.04, 1.0);
      } else {
        amp = s['base']! * 0.30;
      }

      final barH = amp * maxH * amplitude;
      final x = i * barW + gap / 2;
      final w = barW - gap;
      final alpha = isPlaying ? 0.45 + amp * 0.45 : 0.15;

      final paint = Paint()
        ..color = Color.fromRGBO(180, 200, 170, alpha)
        ..style = PaintingStyle.fill;

      final rr = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, centerY - barH, w, barH * 2),
        const Radius.circular(2),
      );
      canvas.drawRRect(rr, paint);
    }
  }

  @override
  bool shouldRepaint(WaveformPainter old) =>
      old.t != t || old.isPlaying != isPlaying || old.amplitude != amplitude;
}