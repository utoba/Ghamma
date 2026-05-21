import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import '../main.dart';
import 'info_screen.dart';
import 'package:http/http.dart' as http;

class VoidScreen extends StatefulWidget {
  const VoidScreen({super.key});

  @override
  State<VoidScreen> createState() => _VoidScreenState();
}

class _VoidScreenState extends State<VoidScreen> with TickerProviderStateMixin {

  final AudioPlayer _player = AudioPlayer();
  final AudioPlayer _bellPlayer = AudioPlayer();

  static const List<String> _voidTracks = [
    'https://www.eoni.cloud/ANANDA/AUDIO/VOID/void1_1.mp3',
    'https://www.eoni.cloud/ANANDA/AUDIO/VOID/void1_2.mp3',
    'https://www.eoni.cloud/ANANDA/AUDIO/VOID/void1_3.mp3',
    'https://www.eoni.cloud/ANANDA/AUDIO/VOID/void1_4.mp3',
    'https://www.eoni.cloud/ANANDA/AUDIO/VOID/void1_5.mp3',
    'https://www.eoni.cloud/ANANDA/AUDIO/VOID/void1_6.mp3',
  ];

  static const String _bellUrl =
      'https://www.eoni.cloud/ANANDA/AUDIO/BELL/bell_ananda1.mp3';

  late AnimationController _lissajousController;
  late AnimationController _starController;

  bool _isPlaying = false;
  int _selectedMinutes = 20;
  int _remainingSeconds = 0;
  bool _showDurationPicker = false;
  bool _isFadingOut = false;

  double _amplitude = 0.0;
  Timer? _fadeTicker;

  DateTime? _sessionStartTime;
  int _totalSeconds = 0;
  Timer? _ticker;

  static const int _fadeOutSeconds = 20;

  final List<int> _minuteOptions = [
    5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60
  ];

  @override
  void initState() {
    super.initState();
    _remainingSeconds = _selectedMinutes * 60;
    _totalSeconds = _selectedMinutes * 60;

    _lissajousController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    );

    _starController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();

    _initForegroundTask();
  }

  void _initForegroundTask() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'ananda_meditation',
        channelName: 'Ananda Meditation',
        channelDescription: 'Keeps audio running during meditation',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000),
        autoRunOnBoot: false,
        allowWifiLock: true,
      ),
    );
  }

  Future<void> _startForegroundTask() async {
    if (await FlutterForegroundTask.isRunningService) return;
    await FlutterForegroundTask.startService(
      serviceId: 256,
      notificationTitle: 'Ananda — meditazione attiva',
      notificationText: 'Tocca per tornare alla sessione',
    );
  }

  Future<void> _stopForegroundTask() async {
    await FlutterForegroundTask.stopService();
  }

  // ── fade animazione ──

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

  void _fadeOutAnimation({VoidCallback? onComplete}) {
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

  // ── timer ──

  void _startRealTimer() {
    _sessionStartTime = DateTime.now();
    _totalSeconds = _selectedMinutes * 60;
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isPlaying) return;
      final elapsed = DateTime.now().difference(_sessionStartTime!).inSeconds;
      final remaining = (_totalSeconds - elapsed).clamp(0, _totalSeconds);
      setState(() => _remainingSeconds = remaining);

      FlutterForegroundTask.updateService(
        notificationTitle: 'Ananda',
        notificationText: _formatTime(remaining),
      );

      if (remaining == _fadeOutSeconds && !_isFadingOut) {
        _startFadeOut();
      }
      if (remaining <= 0 && !_isFadingOut) {
        _endSession();
      }
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
    final tracks = await _fetchTracks(
      'https://www.eoni.cloud/ANANDA/AUDIO/VOID/',
    );
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

  Future<void> _playBell() async {
    await _bellPlayer.setUrl(_bellUrl);
    await _bellPlayer.play();
  }

  void _startFadeOut() {
    _isFadingOut = true;
    const totalSteps = _fadeOutSeconds;
    int step = 0;
    // fade out audio
    Timer.periodic(const Duration(seconds: 1), (timer) {
      step++;
      final volume = 1.0 - (step / totalSteps);
      _player.setVolume(volume.clamp(0.0, 1.0));
      if (step == totalSteps - 10) {
        _playBell();
      }
      if (step >= totalSteps) {
        timer.cancel();
        _endSession();
      }
    });
    // fade out animazione
    _fadeOutAnimation();
  }

  Future<void> _endSession() async {
    _ticker?.cancel();
    _fadeTicker?.cancel();
    await _player.stop();
    await _stopForegroundTask();
    WakelockPlus.disable();
    _lissajousController.stop();
    setState(() {
      _isPlaying = false;
      _isFadingOut = false;
      _amplitude = 0.0;
      _remainingSeconds = 0;
    });
  }

  void _togglePlay() {
    if (_isPlaying) {
      _ticker?.cancel();
      _fadeTicker?.cancel();
      _fadeOutAnimation(onComplete: () {
        _player.stop();
        _player.setVolume(1.0);
        _lissajousController.stop();
        _stopForegroundTask();
        WakelockPlus.disable();
        setState(() {
          _isPlaying = false;
          _isFadingOut = false;
          _remainingSeconds = _selectedMinutes * 60;
        });
      });
    } else {
      setState(() {
        _isPlaying = true;
        _remainingSeconds = _selectedMinutes * 60;
      });
      _lissajousController.repeat();
      WakelockPlus.enable();
      _startForegroundTask();
      _playBell();
      _startAudio();
      _startRealTimer();
      _fadeIn();
    }
  }

  void _setDuration(int minutes) {
    _ticker?.cancel();
    _fadeTicker?.cancel();
    _player.stop();
    _player.setVolume(1.0);
    _lissajousController.stop();
    _stopForegroundTask();
    WakelockPlus.disable();
    setState(() {
      _selectedMinutes = minutes;
      _remainingSeconds = minutes * 60;
      _totalSeconds = minutes * 60;
      _showDurationPicker = false;
      _isPlaying = false;
      _isFadingOut = false;
      _amplitude = 0.0;
    });
  }

  void _closeScreen() {
    _ticker?.cancel();
    _fadeTicker?.cancel();
    _player.stop();
    _bellPlayer.stop();
    _lissajousController.stop();
    _stopForegroundTask();
    WakelockPlus.disable();
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
    _player.dispose();
    _bellPlayer.dispose();
    _lissajousController.dispose();
    _starController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _totalSeconds > 0
        ? ((_totalSeconds - _remainingSeconds) / _totalSeconds).clamp(0.0, 1.0)
        : 0.0;

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
            // ── stelle ──
            AnimatedBuilder(
              animation: _starController,
              builder: (_, __) => CustomPaint(
                painter: StarfieldPainter(t: _starController.value),
                child: const SizedBox.expand(),
              ),
            ),
            // ── contenuto ──
            GestureDetector(
              onTap: () {
                if (_showDurationPicker) {
                  setState(() => _showDurationPicker = false);
                }
              },
              child: SafeArea(
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
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.08),
                                  width: 1,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: AnimatedBuilder(
                                        animation: _lissajousController,
                                        builder: (_, __) => Stack(
                                          children: [
                                            CustomPaint(
                                              painter: TimerRingPainter(
                                                progress: progress,
                                                isPlaying: _isPlaying,
                                              ),
                                              child: const SizedBox.expand(),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(20),
                                              child: CustomPaint(
                                                painter: VectorscopePainter(
                                                  t: _lissajousController.value,
                                                  isPlaying: _isPlaying,
                                                  amplitude: _amplitude,
                                                ),
                                                child: const SizedBox.expand(),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
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
                                      'Pure Tones',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.35),
                                        fontSize: 15,
                                        letterSpacing: 3.5,
                                        fontWeight: FontWeight.w300,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
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
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        GestureDetector(
                                          onTap: () => setState(() =>
                                              _showDurationPicker = !_showDurationPicker),
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
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
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
                                        ),
                                        const SizedBox(width: 20),
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
                        child: Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.08), width: 1,
                            ),
                          ),
                          child: Icon(Icons.close,
                              color: Colors.white.withOpacity(0.55), size: 16),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 20, right: 35,
                      child: GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          PageRouteBuilder(
                            transitionDuration: const Duration(milliseconds: 1200),
                            pageBuilder: (_, __, ___) => const InfoScreen(),
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
                        child: Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.08), width: 1,
                            ),
                          ),
                          child: Icon(Icons.info_outline,
                              color: Colors.white.withOpacity(0.55), size: 16),
                        ),
                      ),
                    ),

                    if (_showDurationPicker)
                      Positioned(
                        bottom: 100, left: 24, right: 24,
                        child: GestureDetector(
                          onTap: () {},
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1E18).withOpacity(0.95),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1), width: 1,
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
          ],
        ),
      ),
    );
  }
}