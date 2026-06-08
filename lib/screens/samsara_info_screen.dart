import 'package:flutter/material.dart';

class SamsaraInfoScreen extends StatefulWidget {
  const SamsaraInfoScreen({super.key});
  @override
  State<SamsaraInfoScreen> createState() => _SamsaraInfoScreenState();
}

class _SamsaraInfoScreenState extends State<SamsaraInfoScreen>
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12), 
            child: GestureDetector(
              onVerticalDragStart:  _onDragStart,
              onVerticalDragUpdate: _onDragUpdate,
              onVerticalDragEnd:    _onDragEnd,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),         // ← tutti e 4
                  gradient: const LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [Color(0xFF1A1E18), Color(0xFF1A1E18), Color(0x5973521F)],
                    stops: [0.0, 0.45, 1.0],
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),                          
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
                              'A M B I E N T   S O U N D S C A P E S',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.55),
                                fontSize: 14,
                                letterSpacing: 2,
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
                              _paragraph('This section contains a constantly updated selection of audio material that can offer support and assistance to states of relaxation, focus, and insight, or serve as a sonic background for work, study, or moments of socialization.'),
                              _divider(),
                              _paragraph('All music by eoni (eoni.cloud) - mixed and mastered at idiom studio (idiomstudio.net)'),
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