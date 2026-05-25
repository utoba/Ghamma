import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import '../logo_painter.dart';
import '../meditation_task_handler.dart';

class SilenceScreen extends StatefulWidget {
  const SilenceScreen({super.key});
  @override
  State<SilenceScreen> createState() => _SilenceScreenState();
}

class _SilenceScreenState extends State<SilenceScreen> with TickerProviderStateMixin {

  int _selectedMinutes = 20;
  int _totalSeconds = 0;
  bool _isRunning = false;
  bool _sessionEnded = false;
  bool _showDurationPicker = false;
  Timer? _timer;
  final AudioPlayer _bellPlayer = AudioPlayer();
  static const String _bellAsset = 'assets/audio/bell1.aac';
  late AnimationController _pulseController;
  late AnimationController _lotusController;

  DateTime? _sessionStartTime;
  int _elapsedSecondsAtPause = 0;

  static const List<int> _minuteOptions = [5, 10, 15, 20, 25, 30, 45, 60];

  @override
  void initState() {
    super.initState();
    _totalSeconds = _selectedMinutes * 60;
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
    _lotusController = AnimationController(vsync: this, duration: const Duration(seconds: 120))..repeat();
    _initForegroundTask();
  }

  void _initForegroundTask() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'ghamma_silence',
        channelName: 'GHAMMA Silence',
        channelDescription: 'Keeps timer running during silence session',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(showNotification: false, playSound: false),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(1000),
        autoRunOnBoot: false,
        allowWifiLock: false,
      ),
    );
  }

  Future<void> _startForegroundTask() async {
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
      await Future.delayed(const Duration(milliseconds: 300));
    }

    final endTimeMs = DateTime.now().millisecondsSinceEpoch + (_remainingSeconds * 1000);

    // Salva i dati PRIMA di startService — letti dall'handler in onStart
    await FlutterForegroundTask.saveData(key: 'endTime', value: endTimeMs.toString());
    await FlutterForegroundTask.saveData(key: 'title', value: 'GHAMMA · Silence');

    await FlutterForegroundTask.startService(
      serviceId: 257,
      notificationTitle: 'GHAMMA · Silence',
      notificationText: _formatTime(_remainingSeconds),
      callback: startMeditationCallback,
    );
  }

  Future<void> _stopForegroundTask() async {
    await FlutterForegroundTask.stopService();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _lotusController.dispose();
    _bellPlayer.dispose();
    super.dispose();
  }

  Future<void> _playBell() async {
    try {
      await _bellPlayer.setAsset(_bellAsset);
      await _bellPlayer.seek(Duration.zero);
      await _bellPlayer.play();
    } catch (_) {}
  }

  int get _elapsedSeconds {
    if (!_isRunning || _sessionStartTime == null) return _elapsedSecondsAtPause;
    final sinceStart = DateTime.now().difference(_sessionStartTime!).inSeconds;
    return (_elapsedSecondsAtPause + sinceStart).clamp(0, _totalSeconds);
  }

  int get _remainingSeconds => (_totalSeconds - _elapsedSeconds).clamp(0, _totalSeconds);

  void _startStop() {
    if (_isRunning) {
      _elapsedSecondsAtPause = _elapsedSeconds;
      _sessionStartTime = null;
      _timer?.cancel();
      _stopForegroundTask();
      setState(() => _isRunning = false);
    } else {
      if (_sessionEnded) {
        _elapsedSecondsAtPause = 0;
        setState(() { _sessionEnded = false; _totalSeconds = _selectedMinutes * 60; });
      }
      _sessionStartTime = DateTime.now();
      _playBell();
      _startForegroundTask();
      setState(() => _isRunning = true);

      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_elapsedSeconds >= _totalSeconds) {
          _timer?.cancel();
          _stopForegroundTask();
          _playBell();
          setState(() { _isRunning = false; _sessionEnded = true; });
        } else {
          setState(() {});
        }
      });
    }
  }

  void _reset() {
    _timer?.cancel();
    _stopForegroundTask();
    _elapsedSecondsAtPause = 0;
    _sessionStartTime = null;
    setState(() { _isRunning = false; _sessionEnded = false; _totalSeconds = _selectedMinutes * 60; });
  }

  void _setDuration(int minutes) {
    _timer?.cancel();
    _stopForegroundTask();
    _elapsedSecondsAtPause = 0;
    _sessionStartTime = null;
    setState(() { _selectedMinutes = minutes; _totalSeconds = minutes * 60; _isRunning = false; _sessionEnded = false; _showDurationPicker = false; });
  }

  String _formatTime(int seconds) =>
      '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';

  String get _displayTime => _formatTime(_remainingSeconds);
  double get _progress => _totalSeconds > 0 ? _elapsedSeconds / _totalSeconds : 0.0;
  bool get _showResetSlot => !_isRunning && (_elapsedSecondsAtPause > 0 || _sessionEnded);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () { if (_showDurationPicker) setState(() => _showDurationPicker = false); },
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1E18),
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
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _lotusController,
                builder: (_, __) => Center(
                  child: GhammaLogo(
                    size: MediaQuery.of(context).size.shortestSide * 1.2,
                    rotation: _lotusController.value * 2 * math.pi,
                    opacity: 0.25,
                  ),
                ),
              ),
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
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                children: [
                                  Expanded(
                                    child: AnimatedBuilder(
                                      animation: _pulseController,
                                      builder: (context, _) => CustomPaint(
                                        painter: _SilenceRingPainter(progress: _progress, pulse: _isRunning ? _pulseController.value : 0.0),
                                        child: SizedBox.expand(
                                          child: Center(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(_displayTime, style: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 52, fontWeight: FontWeight.w200, letterSpacing: 6)),
                                                const SizedBox(height: 4),
                                                Text(
                                                  _isRunning ? 'running' : _sessionEnded ? 'complete' : 'ready',
                                                  style: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 15, fontWeight: FontWeight.w300, letterSpacing: 3),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text('S I L E N C E', style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 28, fontWeight: FontWeight.w200, letterSpacing: 10)),
                                  const SizedBox(height: 6),
                                  Text('Meditation Timer', style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 15, fontWeight: FontWeight.w300, letterSpacing: 3)),
                                  const SizedBox(height: 24),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      AnimatedSwitcher(
                                        duration: const Duration(milliseconds: 200),
                                        child: _showResetSlot
                                            ? _ResetButton(key: const ValueKey('reset'), onTap: _reset)
                                            : _DurationButton(key: const ValueKey('duration'), minutes: _selectedMinutes, onTap: () => setState(() => _showDurationPicker = !_showDurationPicker)),
                                      ),
                                      const SizedBox(width: 20),
                                      GestureDetector(
                                        onTap: _startStop,
                                        child: SizedBox(
                                          width: 130, height: 48,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.09),
                                              borderRadius: BorderRadius.circular(14),
                                              border: Border.all(color: Colors.white.withOpacity(0.12), width: 1),
                                            ),
                                            child: Center(child: Text(_isRunning ? 'STOP' : 'START', style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 12, letterSpacing: 2.5, fontWeight: FontWeight.w400))),
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
                      onTap: () { _timer?.cancel(); _stopForegroundTask(); Navigator.pop(context); },
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
                        ),
                        child: Icon(Icons.close, color: Colors.white.withOpacity(0.55), size: 16),
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
                            border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.55), blurRadius: 24, offset: const Offset(0, 8))],
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8, runSpacing: 8,
                            children: _minuteOptions.map((min) {
                              final isSelected = min == _selectedMinutes;
                              return GestureDetector(
                                onTap: () => _setDuration(min),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.white.withOpacity(0.12) : Colors.white.withOpacity(0.06),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: isSelected ? Colors.white.withOpacity(0.35) : Colors.white.withOpacity(0.08), width: 1),
                                  ),
                                  child: Text('$min min', style: TextStyle(color: isSelected ? Colors.white.withOpacity(0.90) : Colors.white.withOpacity(0.55), fontSize: 13, letterSpacing: 1.2, fontWeight: isSelected ? FontWeight.w400 : FontWeight.w300)),
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
          ],
        ),
      ),
    );
  }
}

class _DurationButton extends StatelessWidget {
  final int minutes;
  final VoidCallback onTap;
  const _DurationButton({super.key, required this.minutes, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
              Text('$minutes min', style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 14, letterSpacing: 1.2, fontWeight: FontWeight.w300)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResetButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ResetButton({super.key, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 130, height: 48,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.10), width: 1),
          ),
          child: Center(child: Text('RESET', style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 12, letterSpacing: 2.5, fontWeight: FontWeight.w300))),
        ),
      ),
    );
  }
}

class _SilenceRingPainter extends CustomPainter {
  final double progress;
  final double pulse;
  const _SilenceRingPainter({required this.progress, required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 16;

    if (pulse > 0) {
      canvas.drawCircle(center, radius, Paint()
        ..color = Colors.white.withOpacity(0.03 * pulse)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 24
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12));
    }

    canvas.drawCircle(center, radius, Paint()
      ..color = Colors.white.withOpacity(0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round);

    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2, 2 * math.pi * progress, false,
        Paint()..color = Colors.white.withOpacity(0.55)..style = PaintingStyle.stroke..strokeWidth = 1.5..strokeCap = StrokeCap.round,
      );
      final angle = -math.pi / 2 + 2 * math.pi * progress;
      canvas.drawCircle(
        Offset(center.dx + radius * math.cos(angle), center.dy + radius * math.sin(angle)),
        4,
        Paint()..color = Colors.white.withOpacity(0.80)..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(_SilenceRingPainter old) => old.progress != progress || old.pulse != pulse;
}