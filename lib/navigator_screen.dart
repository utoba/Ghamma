import 'package:flutter/material.dart';
import 'screens/void_screen.dart';
import 'screens/samsara_screen.dart';
import 'screens/silence_screen.dart';
import 'menu_screen.dart';

enum _DragAxis { none, horizontal, vertical }

class NavigatorScreen extends StatefulWidget {
  final int initialIndex;
  const NavigatorScreen({super.key, this.initialIndex = 0});

  @override
  State<NavigatorScreen> createState() => _NavigatorScreenState();
}

class _NavigatorScreenState extends State<NavigatorScreen> {

  late PageController _pageController;
  int _currentIndex = 0;

  _DragAxis _dragAxis = _DragAxis.none;
  double _dragStartX = 0;
  double _dragStartY = 0;
  double _dragCurrentX = 0;
  double _dragCurrentY = 0;

  static const double _axisThreshold  = 12.0;
  static const double _swipeThreshold = 60.0;
  static const double _velThreshold   = 300.0;

  final List<VoidCallback?> _infoCallbacks = [null, null, null];

  void registerInfoCallback(int index, VoidCallback cb) {
    _infoCallbacks[index] = cb;
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int index) {
    if (index < 0 || index > 2) return;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  void _goToMenu() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) => const MenuScreen(),
        transitionsBuilder: (_, animation, __, child) {
          final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
          return FadeTransition(opacity: curved, child: child);
        },
      ),
    );
  }

  void _onPanStart(DragStartDetails d) {
    _dragAxis    = _DragAxis.none;
    _dragStartX  = d.globalPosition.dx;
    _dragStartY  = d.globalPosition.dy;
    _dragCurrentX = _dragStartX;
    _dragCurrentY = _dragStartY;
  }

  void _onPanUpdate(DragUpdateDetails d) {
    _dragCurrentX = d.globalPosition.dx;
    _dragCurrentY = d.globalPosition.dy;
    if (_dragAxis != _DragAxis.none) return;
    final dx = (_dragCurrentX - _dragStartX).abs();
    final dy = (_dragCurrentY - _dragStartY).abs();
    if (dx < _axisThreshold && dy < _axisThreshold) return;
    _dragAxis = dx > dy ? _DragAxis.horizontal : _DragAxis.vertical;
  }

  void _onPanEnd(DragEndDetails d) {
    if (_dragAxis == _DragAxis.none) return;

    final vx     = d.velocity.pixelsPerSecond.dx;
    final vy     = d.velocity.pixelsPerSecond.dy;
    final totalDx = _dragCurrentX - _dragStartX;
    final totalDy = _dragCurrentY - _dragStartY;

    if (_dragAxis == _DragAxis.horizontal) {
      if (vx < -_velThreshold || totalDx < -_swipeThreshold) {
        _goToPage(_currentIndex + 1);
      } else if (vx > _velThreshold || totalDx > _swipeThreshold) {
        _goToPage(_currentIndex - 1);
      }
    } else {
      // totalDy negativo = swipe UP
      if (vy < -_velThreshold || totalDy < -_swipeThreshold) {
        _goToMenu();
      } else if (vy > _velThreshold || totalDy > _swipeThreshold) {
        // swipe DOWN → info del figlio corrente
        _infoCallbacks[_currentIndex]?.call();
      }
    }

    _dragAxis = _DragAxis.none;
  }

  Widget _buildDots() {
    return Positioned(
      bottom: 14, left: 0, right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (i) {
          final active = i == _currentIndex;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width:  active ? 20 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(active ? 0.55 : 0.18),
              borderRadius: BorderRadius.circular(3),
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1E18),
      body: GestureDetector(
        onPanStart:  _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd:    _onPanEnd,
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (i) => setState(() => _currentIndex = i),
              children: [
                VoidScreen(
                  onRegisterInfo: (cb) => registerInfoCallback(0, cb),
                ),
                SamsaraScreen(
                  onRegisterInfo: (cb) => registerInfoCallback(1, cb),
                ),
                SilenceScreen(
                  onRegisterInfo: (cb) => registerInfoCallback(2, cb),
                ),
              ],
            ),
            _buildDots(),
          ],
        ),
      ),
    );
  }
}