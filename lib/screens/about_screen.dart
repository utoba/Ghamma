import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  final ScrollController? scrollController;
  const AboutScreen({super.key, this.scrollController});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 24),

        // Scrollable content
        Expanded(
          child: SingleChildScrollView(
            controller: scrollController,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildParagraph(
                  'This app was born from a desire to bring together two paths I\'ve walked for years — working in a professional audio studio and exploring meditation practice — and merge them into an artistic form. It is not meant to be an exhaustive app, a scientific instrument, or an absolute reference for any particular spiritual tradition; above all, it is a work of contemporary art.',
                ),
                _buildDivider(),
                _buildParagraph(
                  'If I feel I\'ve succeeded in my intention, and if the humans out there offer the support needed, I\'d love to keep updating Ghamma continuously — with new musical productions and with audio material drawn from advances in research on Binaural Beats, Isochronic Tones, Bilateral Alternating Stimulation, and whatever else the future of this fascinating field may bring.',
                ),
                const SizedBox(height: 16),
                _buildParagraph(
                  'Research in this area is growing rapidly, alongside increasing interest, but it is far from conclusive and results remain mixed. This app can also be the tool that offers an opportunity to explore the subject in practice — and who knows, perhaps to contribute to its evolution.',
                ),
                _buildDivider(),
                _buildParagraph(
                  'The simplicity of the app is a deliberate choice. My idea is to give the user an immediate, ready, working experience — one that skips the time needed to navigate through menus, questions, and decisions. The user should know that Ghamma does what it does, and does it well.',
                ),
                const SizedBox(height: 16),
                _buildParagraph(
                  'All that\'s needed is a pair of headphones (required for the Void section, and ideally good quality ones), some free time, a place to relax, and a single start button to begin the experience. I\'ve always found "focus and meditation" apps with many menus and many choices to be misleading.',
                ),
                const SizedBox(height: 16),
                _buildParagraph(
                  'The audio material in Ghamma has already been prepared and formatted to offer a coherent and meaningful experience. The focus should be entirely on the present-moment experience, and nothing more. The app offers each session through a random algorithm, making every session unique and completely different.',
                ),
                _buildDivider(),
                _buildParagraph(
                  'I won\'t dwell too long on describing the frequencies used, the techniques involved, or the science behind them. Being an artistic form, its focus is on use, on experience. Anyone who feels curious and inspired to explore further will find plenty of sources online.',
                ),
                const SizedBox(height: 16),
                _buildParagraph(
                  'The same applies to meditation practice itself — it is not my intention to promote a specific method, but rather to offer a tool for the user, who will then choose their own path according to their inclinations and karma.',
                ),
                _buildDivider(),
                _buildParagraph(
                  'I\'ve also included, as an integral and fundamental part of the app, a simple timer for silent meditation sessions. This is my own daily meditation practice, and the one I find most beneficial for my spiritual development.',
                ),
                const SizedBox(height: 48),
                Center(
                  child: Text(
                    'May all be happy.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.40),
                      fontSize: 14,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 2,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildParagraph(String text) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white.withOpacity(0.60),
        fontSize: 15,
        fontWeight: FontWeight.w300,
        height: 1.75,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Container(
        width: 32,
        height: 1,
        color: Colors.white.withOpacity(0.12),
      ),
    );
  }
}