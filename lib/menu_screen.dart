import 'package:flutter/material.dart';
import 'screens/void_screen.dart';
import 'screens/samsara_screen.dart';
import 'screens/about_screen.dart';
import 'screens/silence_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _sheetController;
  late Animation<Offset> _sheetAnimation;
  final ScrollController _aboutScrollController = ScrollController();
  bool _sheetOpen = false;
  double _sheetHeight = 0;
  double _dragStartY = 0;

  @override
  void initState() {
    super.initState();
    _sheetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _sheetAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _sheetController,
      curve: Curves.easeOutQuart,
      reverseCurve: Curves.easeInQuart,
    ));
  }

  @override
  void dispose() {
    _sheetController.dispose();
    _aboutScrollController.dispose();
    super.dispose();
  }

  void _openSheet() {
    setState(() => _sheetOpen = true);
    _sheetController.forward();
  }

  void _closeSheet() {
    _sheetController.reverse().then((_) {
      setState(() => _sheetOpen = false);
      if (_aboutScrollController.hasClients) {
        _aboutScrollController.jumpTo(0);
      }
    });
  }

  void _onVerticalDragStart(DragStartDetails details) {
    _dragStartY = details.globalPosition.dy;
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (_sheetHeight == 0) return;
    final delta = details.globalPosition.dy - _dragStartY;
    if (!_sheetOpen) {
      final value = (delta / _sheetHeight).clamp(0.0, 1.0);
      _sheetController.value = value;
    } else {
      final value = 1.0 + (delta / _sheetHeight).clamp(-1.0, 0.0);
      _sheetController.value = value;
    }
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (!_sheetOpen) {
      if (velocity > 300 || _sheetController.value > 0.4) {
        _openSheet();
      } else {
        _sheetController.reverse();
      }
    } else {
      if (velocity < -300 || _sheetController.value < 0.6) {
        _closeSheet();
      } else {
        _sheetController.forward();
      }
    }
  }

  PageRouteBuilder _slideRoute(Widget page) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 1200),
      pageBuilder: (_, __, ___) => page,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    _sheetHeight = screenHeight * 0.92;

    return Scaffold(
      body: Stack(
        children: [

          // ── Background gradient ──────────────────────────────────
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

          // ── Menu content ─────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 30),

                  // Lineetta swipe — apre about
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onVerticalDragStart: _onVerticalDragStart,
                    onVerticalDragUpdate: _onVerticalDragUpdate,
                    onVerticalDragEnd: _onVerticalDragEnd,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Center(
                    child: Text(
                      'G H A M M A',
                      style: TextStyle(
                        color: Color(0xFFCCCCCC),
                        fontSize: 34,
                        fontWeight: FontWeight.w200,
                        letterSpacing: 12,
                      ),
                    ),
                  ),

                  Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 16),
                    color: Colors.white.withOpacity(0.1),
                  ),

                  const SizedBox(height: 30),

                  Center(
                    child: Text(
                      'S E L E C T   Y O U R   P A T H',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.75),
                        fontSize: 15,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 4,
                      ),
                    ),
                  ),

                  const SizedBox(height: 45),

                  _MenuCard(
                    title: 'V O I D',
                    subtitle: 'Pure Tones',
                    onTap: () => Navigator.push(context, _slideRoute(const VoidScreen())),
                  ),

                  const SizedBox(height: 27),

                  _MenuCard(
                    title: 'S A M S A R A',
                    subtitle: 'Ambient Soundscapes',
                    onTap: () => Navigator.push(context, _slideRoute(const SamsaraScreen())),
                  ),

                  const SizedBox(height: 27),

                  _MenuCard(
                    title: 'S I L E N C E',
                    subtitle: 'Meditation Timer',
                    onTap: () => Navigator.push(context, _slideRoute(const SilenceScreen())),
                  ),

                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),

          // ── Overlay scuro dietro la sheet ────────────────────────
          AnimatedBuilder(
            animation: _sheetController,
            builder: (_, __) => IgnorePointer(
              ignoring: _sheetController.value == 0,
              child: GestureDetector(
                onTap: _sheetOpen ? _closeSheet : null,
                child: Opacity(
                  opacity: _sheetController.value * 0.35,
                  child: Container(color: Colors.black),
                ),
              ),
            ),
          ),

          // ── About sheet ──────────────────────────────────────────
          SlideTransition(
            position: _sheetAnimation,
            child: Align(
              alignment: Alignment.topCenter,
              child: GestureDetector(
                onVerticalDragStart: _onVerticalDragStart,
                onVerticalDragUpdate: _onVerticalDragUpdate,
                onVerticalDragEnd: _onVerticalDragEnd,
                child: Container(
                  height: _sheetHeight,
                  width: double.infinity,
                  padding: const EdgeInsets.only(bottom: 28),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E231C),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(28),
                      bottomRight: Radius.circular(28),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 32,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      children: [
                        Expanded(
                          child: AboutScreen(
                            scrollController: _aboutScrollController,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.20),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

        ],
      ),
    );
  }
}

// ── Menu Card ─────────────────────────────────────────────────────────────────

class _MenuCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  State<_MenuCard> createState() => _MenuCardState();
}

class _MenuCardState extends State<_MenuCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        decoration: BoxDecoration(
          color: _pressed
              ? Colors.white.withOpacity(0.12)
              : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _pressed
                ? Colors.white.withOpacity(0.20)
                : Colors.white.withOpacity(0.08),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: const TextStyle(
                color: Color(0xFFCCCCCC),
                fontSize: 25,
                fontWeight: FontWeight.w200,
                letterSpacing: 6,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              widget.subtitle,
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 15,
                fontWeight: FontWeight.w300,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}