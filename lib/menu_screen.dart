import 'package:flutter/material.dart';
import 'screens/void_screen.dart';
import 'screens/samsara_screen.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

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
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 30),

                const Center(
                  child: Text(
                    'A N A N D A',
                    style: TextStyle(
                      color: Color(0xFFCCCCCC),
                      fontSize: 37,
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

                const SizedBox(height: 8),

                Center(
                  child: Text(
                    'Sound and silence as a tool for the mind.\nVoid is best experienced with high-quality headphones.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.55),
                      fontSize: 15,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 0.5,
                      height: 1.6,
                    ),
                  ),
                ),

                 Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 30),
                  color: Colors.white.withOpacity(0.1),
                ),

                const Spacer(flex: 2),

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

                const SizedBox(height: 30),

                _MenuCard(
                  title: 'V O I D',
                  subtitle: 'Pure Tones',
                  onTap: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        transitionDuration: const Duration(milliseconds: 1200),
                        pageBuilder: (_, __, ___) => const VoidScreen(),
                        transitionsBuilder: (_, animation, __, child) {
                          final curved = CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutQuart,
                          );
                          return ScaleTransition(
                            scale: Tween<double>(
                              begin: 0.1,
                              end: 1.0,
                            ).animate(curved),
                            child: FadeTransition(
                                opacity: Tween<double>(
                                    begin: 0.0,
                                    end: 1.0,
                                ) .animate(curved),
                              child: child,
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                _MenuCard(
                  title: 'S A M S A R A',
                  subtitle: 'Ambient Soundscapes',
                  onTap: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        transitionDuration: const Duration(milliseconds: 1200),
                        pageBuilder: (_, __, ___) => const SamsaraScreen(),
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
                    );
                  },
                ),

                const SizedBox(height: 16),

                _MenuCard(
                  title: 'S I L E N C E',
                  subtitle: 'Meditation Timer',
                  onTap: () {},
                ),

                const Spacer(flex: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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