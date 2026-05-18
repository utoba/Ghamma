import 'package:flutter/material.dart';

class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

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
                      'P U R E   T O N E S',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.55),
                        fontSize: 15,
                        letterSpacing: 4,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 36),
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
                        'This is a selection of binaural beats, isochronic tones, and bilateral beats — to offer a complete experience of what the study of sound and psychophysical states has to offer today.',
                      ),
                      _divider(),
                      _paragraph(
                        'These pure tones are the result of hours of personal meditation. They were recorded during my own sessions.',
                      ),
                      _divider(),
                      _paragraph(
                        "Even if I still believe vipassana meditation — which doesn't use any external input other than the pure sensory experience of the present moment — is the deepest and most beneficial form of meditation, I think it is worth exploring the relationships between different levels of vibration (sound, mind, the reality around us) and our response to them."
                      ),
                      _divider(),
                      _paragraph(
                        'I also remember that as a beginner, all the tools that helped me relax and focus — music above all — were essential in helping me move forward on my spiritual path.',
                      ),
                      _divider(),
                      _paragraph(
                        'I hope this app can be equally useful to those who are just beginning, and to those already on the path who want to experiment with sound vibrations and psychophysical states.',
                      ),
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