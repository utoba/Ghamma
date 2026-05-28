import 'package:flutter/material.dart';

class InfoScreen extends StatefulWidget {
  const InfoScreen({super.key});
  @override
  State<InfoScreen> createState() => _InfoScreenState();
}

class _InfoScreenState extends State<InfoScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController _ctrl;
  late Animation<Offset> _slideAnim;
  double _dragStartY = 0;
  double _dragCurrentY = 0;
  static const double _closeThreshold = 60.0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 480));
    _slideAnim = Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _close() {
    _ctrl.reverse().then((_) { if (mounted) Navigator.pop(context); });
  }

  void _onDragStart(DragStartDetails d) {
    _dragStartY = d.globalPosition.dy;
    _dragCurrentY = _dragStartY;
  }

  void _onDragUpdate(DragUpdateDetails d) {
    _dragCurrentY = d.globalPosition.dy;
    final dy = _dragCurrentY - _dragStartY;
    if (dy < 0) {
      _ctrl.value = (1.0 + (dy / 300)).clamp(0.0, 1.0);
    }
  }

  void _onDragEnd(DragEndDetails d) {
    final dy = _dragCurrentY - _dragStartY;
    final vy = d.velocity.pixelsPerSecond.dy;
    if (dy < -_closeThreshold || vy < -400) { _close(); } else { _ctrl.forward(); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Align(
        alignment: Alignment.topCenter,
        child: SlideTransition(
          position: _slideAnim,
          child: GestureDetector(
            onVerticalDragStart:  _onDragStart,
            onVerticalDragUpdate: _onDragUpdate,
            onVerticalDragEnd:    _onDragEnd,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [Color(0xFF1A1E18), Color(0xFF1A1E18), Color(0x5973521F)],
                  stops: [0.0, 0.45, 1.0],
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 16),
                    // titolo
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      child: Center(
                        child: Text(
                          'P U R E   T O N E S',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.55),
                            fontSize: 15,
                            letterSpacing: 3,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ),
                    ),
                    // contenuto
                    SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          _paragraph('This is a selection of binaural beats, isochronic tones, and bilateral beats — to offer a complete experience of what the study of sound and psychophysical states has to offer today. This section is best experienced with quality headphones.'),
                          _divider(),
                          _paragraph('These pure tones are the result of hours of personal meditation. They were recorded during my own sessions.'),
                          _divider(),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                    // drag handle in fondo — invito swipe up per chiudere
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 16),
                      child: Center(
                        child: Container(
                          width: 36, height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.20),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _paragraph(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: Text(text, style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 15, fontWeight: FontWeight.w300, letterSpacing: 0.3, height: 1.75)),
  );

  Widget _divider() => Container(height: 1, color: Colors.white.withOpacity(0.06));
}