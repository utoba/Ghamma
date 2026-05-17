import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../main.dart';

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
  late AnimationController _tickController;

  bool _isPlaying = false;
  bool _isLoading = false;
  int _selectedMinutes = 20;
  late int _remainingSeconds;
  bool _showDurationPicker = false;
  bool _isFadingOut = false;

  static const int _fadeOutSeconds = 20;

  final List<int> _minuteOptions = [
    5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60
  ];

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
      if (_remainingSeconds == _fadeOutSeconds - 10 && !_isFadingOut) {
        _playBell();
      }
      if (_remainingSeconds == _fadeOutSeconds && !_isFadingOut) {
        _startFadeOut();
        return;
      }
      if (_remainingSeconds <= 0) return;
      _tickController.forward(from: 0);
    }
  }

  Future<void> _startAudio() async {
    final tracks = List<String>.from(_voidTracks)..shuffle(Random());
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

  Future<void> _playBell() async {
    await _bellPlayer.setUrl(_bellUrl);
    await _bellPlayer.play();
  }

  void _startFadeOut() {
    _isFadingOut = true;
    const totalSteps = _fadeOutSeconds;
    int step = 0;
    Timer.periodic(const Duration(seconds: 1), (timer) {
      step++;
      final volume = 1.0 - (step / totalSteps);
      _player.setVolume(volume.clamp(0.0, 1.0));
      setState(() {
        if (_remainingSeconds > 0) _remainingSeconds--;
      });
      if (step >= totalSteps) {
        timer.cancel();
        _endSession();
      }
    });
  }

  Future<void> _endSession() async {
    await _player.stop();
    _lissajousController.stop();
    setState(() {
      _isPlaying = false;
      _isFadingOut = false;
      _remainingSeconds = 0;
    });
  }

  void _togglePlay() {
    if (_isPlaying) {
      _player.stop();
      _lissajousController.stop();
      _tickController.stop();
      setState(() {
        _isPlaying = false;
        _isFadingOut = false;
        _isLoading = false;
        _remainingSeconds = _selectedMinutes * 60;
      });
      _player.setVolume(1.0);
    } else {
      if (_remainingSeconds <= 0) {
        setState(() => _remainingSeconds = _selectedMinutes * 60);
      }
      setState(() => _isPlaying = true);
      _lissajousController.repeat();
      _tickController.forward(from: 0);
      _playBell();
      _startAudio();
    }
  }

  void _setDuration(int minutes) {
    _player.stop();
    _player.setVolume(1.0);
    _lissajousController.stop();
    _tickController.stop();
    setState(() {
      _selectedMinutes = minutes;
      _remainingSeconds = minutes * 60;
      _showDurationPicker = false;
      _isPlaying = false;
      _isFadingOut = false;
      _isLoading = false;
    });
  }

  String _formatTime(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _player.dispose();
    _bellPlayer.dispose();
    _lissajousController.dispose();
    _tickController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        child: GestureDetector(
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
                    const SizedBox(height: 24),
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
                                          _showDurationPicker =
                                              !_showDurationPicker),
                                      child: Container(
                                        height: 48,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.09),
                                          borderRadius: BorderRadius.circular(14),
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
                if (_showDurationPicker)
                  Positioned(
                    bottom: 100,
                    left: 24,
                    right: 24,
                    child: GestureDetector(
                      onTap: () {},
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