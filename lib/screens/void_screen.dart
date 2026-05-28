import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:http/http.dart' as http;
import '../main.dart';
import 'info_screen.dart';
import '../meditation_task_handler.dart';

bool _headphoneWarningShown = false;
bool _brainwavePickerShown = false;

class _BrainwaveType {
  final String name;
  final String range;
  final String description;
  final String prefix;
  const _BrainwaveType({
    required this.name,
    required this.range,
    required this.description,
    required this.prefix,
  });
}

const List<_BrainwaveType> _brainwaves = [
  _BrainwaveType(name: 'DELTA', range: '0.5–4 Hz', description: 'Deep sleep · Recovery', prefix: 'void1_'),
  _BrainwaveType(name: 'THETA', range: '4–8 Hz', description: 'Deep meditation · Creativity', prefix: 'void2_'),
  _BrainwaveType(name: 'ALPHA', range: '8–13 Hz', description: 'Relaxed focus · Calm alertness', prefix: 'void3_'),
  _BrainwaveType(name: 'BETA', range: '13–30 Hz', description: 'Active attention · Concentration', prefix: 'void4_'),
  _BrainwaveType(name: 'GAMMA', range: '30–100 Hz', description: 'Intense focus · Memory (40 Hz)', prefix: 'void5_'),
];

class VoidScreen extends StatefulWidget {
  // Callback opzionali dal NavigatorScreen
  // Se null, lo screen funziona standalone (compatibilità)
  final VoidCallback? onOpenInfo;
  final void Function(VoidCallback)? onRegisterInfo;

  const VoidScreen({
    super.key,
    this.onOpenInfo,
    this.onRegisterInfo,
  });

  @override
  State<VoidScreen> createState() => _VoidScreenState();
}

class _VoidScreenState extends State<VoidScreen> with TickerProviderStateMixin {

  final AudioPlayer _player = AudioPlayer();
  final AudioPlayer _bellPlayer = AudioPlayer();

  static const String _bellAsset = 'assets/audio/bell1.aac';
  static const String _voidBaseUrl = 'https://www.eoni.cloud/ANANDA/AUDIO/VOID/';
  static const int _fadeOutSeconds = 20;

  late AnimationController _lissajousController;
  late AnimationController _starController;

  bool _isPlaying = false;
  int _selectedMinutes = 20;
  int _remainingSeconds = 0;
  bool _showDurationPicker = false;
  bool _showBrainwavePicker = false;
  bool _isFadingOut = false;
  int _selectedBrainwaveIndex = 0;
  double _amplitude = 0.0;

  Timer? _fadeTicker;
  Timer? _ticker;
  DateTime? _sessionStartTime;
  int _totalSeconds = 0;

  final List<int> _minuteOptions = [5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60];
  _BrainwaveType get _currentBrainwave => _brainwaves[_selectedBrainwaveIndex];

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

    // Registra il callback per aprire info (swipe down dal NavigatorScreen)
    widget.onRegisterInfo?.call(_openInfo);

    WidgetsBinding.instance.addPostFrameCallback((_) => _onScreenReady());
  }

  void _openInfo() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 480),
      pageBuilder: (_, __, ___) => const InfoScreen(),
      transitionBuilder: (_, animation, __, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  Future<void> _onScreenReady() async {
    await _showHeadphoneWarning();
    if (!mounted) return;
    if (!_brainwavePickerShown) {
      _brainwavePickerShown = true;
      setState(() => _showBrainwavePicker = true);
    }
  }

  Future<void> _showHeadphoneWarning() async {
    if (_headphoneWarningShown) return;
    _headphoneWarningShown = true;
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1E18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withOpacity(0.10)),
        ),
        title: Row(
          children: [
            Icon(Icons.headphones_outlined, color: Colors.white.withOpacity(0.75), size: 22),
            const SizedBox(width: 12),
            Text('Use headphones', style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 16, fontWeight: FontWeight.w300, letterSpacing: 1.5)),
          ],
        ),
        content: Text(
          'Binaural beats require stereo headphones to work correctly. Speakers will not produce the effect.',
          style: TextStyle(color: Colors.white.withOpacity(0.50), fontSize: 14, fontWeight: FontWeight.w300, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('GOT IT', style: TextStyle(color: Colors.white.withOpacity(0.65), letterSpacing: 2, fontWeight: FontWeight.w400, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  void _initForegroundTask() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'ghamma_meditation',
        channelName: 'GHAMMA Meditation',
        channelDescription: 'Keeps audio running during meditation',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(showNotification: false, playSound: false),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(1000),
        autoRunOnBoot: false,
        allowWifiLock: true,
      ),
    );
  }

  Future<void> _startForegroundTask() async {
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
      await Future.delayed(const Duration(milliseconds: 300));
    }
    final endTimeMs = DateTime.now().millisecondsSinceEpoch + (_totalSeconds * 1000);
    final title = 'GHAMMA · ${_currentBrainwave.name}';
    await FlutterForegroundTask.saveData(key: 'endTime', value: endTimeMs.toString());
    await FlutterForegroundTask.saveData(key: 'title', value: title);
    await FlutterForegroundTask.startService(
      serviceId: 256,
      notificationTitle: title,
      notificationText: _formatTime(_totalSeconds),
      callback: startMeditationCallback,
    );
  }

  Future<void> _stopForegroundTask() async {
    await FlutterForegroundTask.stopService();
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

  void _fadeOutAnimation({VoidCallback? onComplete}) {
    _fadeTicker?.cancel();
    _fadeTicker = Timer.periodic(const Duration(milliseconds: 30), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        _amplitude = (_amplitude - 0.02).clamp(0.0, 1.0);
        if (_amplitude <= 0.0) { t.cancel(); onComplete?.call(); }
      });
    });
  }

  void _startRealTimer() {
    _sessionStartTime = DateTime.now();
    _totalSeconds = _selectedMinutes * 60;
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isPlaying) return;
      final elapsed = DateTime.now().difference(_sessionStartTime!).inSeconds;
      final remaining = (_totalSeconds - elapsed).clamp(0, _totalSeconds);
      setState(() => _remainingSeconds = remaining);
      if (remaining == _fadeOutSeconds && !_isFadingOut) _startFadeOut();
      if (remaining <= 0 && !_isFadingOut) _endSession();
    });
  }

  Future<List<String>> _fetchTracksForBrainwave(_BrainwaveType bw) async {
    final response = await http.get(Uri.parse(_voidBaseUrl));
    if (response.statusCode != 200) return [];
    final regExp = RegExp(r'href="([^"]+\.mp3)"', caseSensitive: false);
    final all = regExp.allMatches(response.body).map((m) => m.group(1)!).toList();
    final filtered = all
        .where((n) => n.toLowerCase().startsWith(bw.prefix.toLowerCase()))
        .map((n) => _voidBaseUrl + n)
        .toList();
    if (filtered.isEmpty) {
      return all.where((n) => n.toLowerCase().startsWith('void1_')).map((n) => _voidBaseUrl + n).toList();
    }
    return filtered;
  }

  Future<void> _startAudio() async {
    final tracks = await _fetchTracksForBrainwave(_currentBrainwave);
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
    try {
      await _bellPlayer.setAsset(_bellAsset);
      await _bellPlayer.seek(Duration.zero);
      await _bellPlayer.play();
    } catch (_) {}
  }

  void _startFadeOut() {
    _isFadingOut = true;
    const totalSteps = _fadeOutSeconds;
    int step = 0;
    Timer.periodic(const Duration(seconds: 1), (timer) {
      step++;
      _player.setVolume((1.0 - step / totalSteps).clamp(0.0, 1.0));
      if (step == totalSteps - 10) _playBell();
      if (step >= totalSteps) { timer.cancel(); _endSession(); }
    });
    _fadeOutAnimation();
  }

  Future<void> _endSession() async {
    _ticker?.cancel();
    _fadeTicker?.cancel();
    await _player.stop();
    await _stopForegroundTask();
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
      _isFadingOut = true;
      const totalTicks = 40;
      int tick = 0;
      Timer.periodic(const Duration(milliseconds: 50), (timer) {
        tick++;
        _player.setVolume((1.0 - tick / totalTicks).clamp(0.0, 1.0));
        if (tick >= totalTicks) {
          timer.cancel();
          _player.stop();
          _player.setVolume(1.0);
          _lissajousController.stop();
          _stopForegroundTask();
          if (mounted) {
            setState(() {
              _isPlaying = false;
              _isFadingOut = false;
              _remainingSeconds = _selectedMinutes * 60;
            });
          }
        }
      });
      _fadeOutAnimation();
    } else {
      setState(() {
        _isPlaying = true;
        _showBrainwavePicker = false;
        _showDurationPicker = false;
        _remainingSeconds = _selectedMinutes * 60;
      });
      _lissajousController.repeat();
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

  void _setBrainwave(int index) {
    if (_isPlaying) return;
    setState(() { _selectedBrainwaveIndex = index; _showBrainwavePicker = false; });
  }

  String _formatTime(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

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
    final bw = _currentBrainwave;

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
                  colors: [Color(0xFF1A1E18), Color(0xFF1A1E18), Color(0x5973521F)],
                  stops: [0.0, 0.45, 1.0],
                ),
              ),
            ),
            AnimatedBuilder(
              animation: _starController,
              builder: (_, __) => CustomPaint(
                painter: StarfieldPainter(t: _starController.value),
                child: const SizedBox.expand(),
              ),
            ),
            GestureDetector(
              onTap: () {
                if (_showDurationPicker || _showBrainwavePicker) {
                  setState(() { _showDurationPicker = false; _showBrainwavePicker = false; });
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
                                border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  children: [
                                    // drag handle — invito swipe down per info
                                    Center(
                                      child: Container(
                                        width: 36, height: 4,
                                        margin: const EdgeInsets.only(bottom: 12),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.18),
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: AnimatedBuilder(
                                        animation: _lissajousController,
                                        builder: (_, __) => Stack(
                                          children: [
                                            CustomPaint(
                                              painter: TimerRingPainter(progress: progress, isPlaying: _isPlaying),
                                              child: const SizedBox.expand(),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(20),
                                              child: CustomPaint(
                                                painter: VectorscopePainter(t: _lissajousController.value, isPlaying: _isPlaying, amplitude: _amplitude),
                                                child: const SizedBox.expand(),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text('VOID', style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 28, letterSpacing: 10, fontWeight: FontWeight.w200)),
                                    const SizedBox(height: 6),
                                    Text('Pure Tones', style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 15, letterSpacing: 3.5, fontWeight: FontWeight.w300)),
                                    const SizedBox(height: 8),
                                    Text(_formatTime(_remainingSeconds), style: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 52, fontWeight: FontWeight.w200, letterSpacing: 6)),
                                    const SizedBox(height: 16),
                                    // Bottone brainwave
                                    GestureDetector(
                                      onTap: _isPlaying ? null : () => setState(() { _showBrainwavePicker = !_showBrainwavePicker; _showDurationPicker = false; }),
                                      child: Container(
                                        height: 44,
                                        padding: const EdgeInsets.symmetric(horizontal: 20),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.07),
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(color: Colors.white.withOpacity(0.10), width: 1),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(bw.name, style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 13, letterSpacing: 3, fontWeight: FontWeight.w300)),
                                            const SizedBox(width: 10),
                                            Container(width: 1, height: 14, color: Colors.white.withOpacity(0.15)),
                                            const SizedBox(width: 10),
                                            Text(bw.range, style: TextStyle(color: Colors.white.withOpacity(0.40), fontSize: 12, letterSpacing: 1.5, fontWeight: FontWeight.w300)),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    // Duration + Start
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        GestureDetector(
                                          onTap: () => setState(() { _showDurationPicker = !_showDurationPicker; _showBrainwavePicker = false; }),
                                          child: SizedBox(
                                            width: 130, height: 48,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.09),
                                                borderRadius: BorderRadius.circular(14),
                                                border: Border.all(color: Colors.white.withOpacity(0.12), width: 1),
                                              ),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.timer_outlined, color: Colors.white.withOpacity(0.65), size: 18),
                                                  const SizedBox(width: 8),
                                                  Text('$_selectedMinutes min', style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 14, letterSpacing: 1.2, fontWeight: FontWeight.w300)),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 20),
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
                                              child: Center(
                                                child: Text(_isPlaying ? 'STOP' : 'START', style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 12, letterSpacing: 2.5, fontWeight: FontWeight.w400)),
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
                        const SizedBox(height: 28), // spazio per i dots
                      ],
                    ),
                    // Picker brainwave
                    if (_showBrainwavePicker)
                      Positioned(
                        bottom: 108, left: 24, right: 24,
                        child: GestureDetector(
                          onTap: () {},
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1E18).withOpacity(0.97),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: Colors.white.withOpacity(0.10), width: 1),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.60), blurRadius: 28, offset: const Offset(0, 8))],
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: _brainwaves.asMap().entries.map((entry) {
                                final i = entry.key;
                                final b = entry.value;
                                final isSelected = i == _selectedBrainwaveIndex;
                                return GestureDetector(
                                  onTap: () => _setBrainwave(i),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: isSelected ? const Color.fromRGBO(30, 200, 80, 0.12) : Colors.white.withOpacity(0.04),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: isSelected ? const Color.fromRGBO(30, 200, 80, 0.45) : Colors.white.withOpacity(0.07), width: 1),
                                    ),
                                    child: Row(
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(b.name, style: TextStyle(color: isSelected ? const Color.fromRGBO(30, 200, 80, 1) : Colors.white.withOpacity(0.70), fontSize: 13, letterSpacing: 2.5, fontWeight: isSelected ? FontWeight.w400 : FontWeight.w300)),
                                            const SizedBox(height: 2),
                                            Text(b.range, style: TextStyle(color: isSelected ? const Color.fromRGBO(30, 200, 80, 0.65) : Colors.white.withOpacity(0.30), fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.w300)),
                                          ],
                                        ),
                                        const SizedBox(width: 16),
                                        Container(width: 1, height: 28, color: Colors.white.withOpacity(0.08)),
                                        const SizedBox(width: 16),
                                        Expanded(child: Text(b.description, style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 12, letterSpacing: 0.5, fontWeight: FontWeight.w300))),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    // Picker duration
                    if (_showDurationPicker)
                      Positioned(
                        bottom: 108, left: 24, right: 24,
                        child: GestureDetector(
                          onTap: () {},
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1E18).withOpacity(0.95),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.55), blurRadius: 24, offset: const Offset(0, 8))],
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
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
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isSelected ? const Color.fromRGBO(30, 200, 80, 0.18) : Colors.white.withOpacity(0.06),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: isSelected ? const Color.fromRGBO(30, 200, 80, 0.55) : Colors.white.withOpacity(0.08), width: 1),
                                    ),
                                    child: Text('$min min', style: TextStyle(color: isSelected ? const Color.fromRGBO(30, 200, 80, 1) : Colors.white.withOpacity(0.55), fontSize: 13, letterSpacing: 1.2, fontWeight: isSelected ? FontWeight.w400 : FontWeight.w300)),
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