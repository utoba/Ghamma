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
                  'VOID:\nThis section offers a rich, varied soundscape featuring pure forms of binaural beats, isochronic tones, and bilateral beats. The category is split into 5 sub-sections based on brainwave frequency range. A session timer completes the experience. Good-quality headphones are required for full immersion.',
                ),
                _buildDivider(),
               
                const SizedBox(height: 16),
                _buildParagraph(
                  'SAMSARA:\nThis section offers a constantly updated selection of ambient tracks designed for deep contemplation and insight. Tracks are created by a collective of artists revolving around idiom studio, particularly the eoni project. For more info and to support the artists: www.eoni.cloud and www.idiomstudio.net',
                ),
                _buildDivider(),
                
                const SizedBox(height: 16),
                _buildParagraph(
                  'SILENCE:\nTimer for silent meditation.',
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