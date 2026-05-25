import 'package:flutter/material.dart';

class SamsaraInfoScreen extends StatelessWidget {
  const SamsaraInfoScreen({super.key});

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
          child: Column(
            children: [
              // ── header ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.08),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.close,
                          color: Colors.white.withOpacity(0.55),
                          size: 16,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'AMBIENT SOUNDSCAPES',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.55),
                        fontSize: 18,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 32),
                  ],
                ),
              ),

              // ── contenuto ──
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      _paragraph(
                        'This section contains a constantly updated selection of audio material that can offer support and assistance to states of relaxation, focus, and insight, or serve as a sonic background for work, study, or moments of socialization.',
                      ),
                      _divider(),
                      _paragraph(
                        'Tracks are created by a collective of artists revolving around idiom studio, particularly the eoni project. For more info and to support the artists: www.eoni.cloud and www.idiomstudio.net',
                      ),
                      _divider(),
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _paragraph(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withOpacity(0.65),
          fontSize: 15,
          fontWeight: FontWeight.w300,
          letterSpacing: 0.3,
          height: 1.75,
        ),
      ),
    );
  }

  Widget _divider() {
    return Container(
      height: 1,
      color: Colors.white.withOpacity(0.06),
    );
  }
}