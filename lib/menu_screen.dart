import 'package:flutter/material.dart';
import 'main.dart'; // importa PlayerScreen (void page)

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // stesso gradient di void page
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
                const SizedBox(height: 64),

                // ── titolo ANANDA ──
                const Center(
                  child: Text(
                    'A N A N D A',
                    style: TextStyle(
                      color: Color(0xFFCCCCCC),
                      fontSize: 32,
                      fontWeight: FontWeight.w200,
                      letterSpacing: 12,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ── sottotitolo ──
                Center(
                  child: Text(
                    'S E L E C T   Y O U R   P A T H',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.35),
                      fontSize: 11,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 4,
                    ),
                  ),
                ),

                const SizedBox(height: 72),

                // ── card VOID ──
                _MenuCard(
                  title: 'V O I D',
                  subtitle: 'Pure Tones',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PlayerScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),

                // ── card SAMSARA ──
                _MenuCard(
                  title: 'S A M S A R A',
                  subtitle: 'Ambient Soundscapes',
                  onTap: () {
                    // pagina futura
                  },
                ),

                const SizedBox(height: 20),

                // ── card SILENCE ──
                _MenuCard(
                  title: 'S I L E N C E',
                  subtitle: 'Meditation Timer',
                  onTap: () {
                    // pagina futura
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  CARD SINGOLA
// ─────────────────────────────────────────────
class _MenuCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.08),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFFCCCCCC),
                fontSize: 22,
                fontWeight: FontWeight.w200,
                letterSpacing: 6,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 13,
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