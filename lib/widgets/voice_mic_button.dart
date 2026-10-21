import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'voice_orb_visualizer.dart' show OrbState;

/// The mic control for the voice screens: shows "talk" when idle and "send"
/// while listening. Pass [onTap] to handle taps here, or leave it null when a
/// parent GestureDetector already handles them. The glow itself lives along
/// the bottom edge (VoiceBeam).
class VoiceMicButton extends StatelessWidget {
  final OrbState state;
  final VoidCallback? onTap;

  const VoiceMicButton({super.key, required this.state, this.onTap});

  @override
  Widget build(BuildContext context) {
    final listening = state == OrbState.listening;
    final busy = state == OrbState.thinking || state == OrbState.speaking;

    return Semantics(
      button: true,
      label: listening ? 'Stop and send' : 'Start talking',
      child: GestureDetector(
        onTap: busy || onTap == null ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            // Light theme: green when ready, dark when listening, grey when busy.
            color: listening
                ? const Color(0xFF1C1C1E)
                : busy
                ? const Color(0x1F767680)
                : const Color(0xFF3F7D0F),
            boxShadow: busy ? null : const [BoxShadow(color: Color(0x33000000), blurRadius: 18, offset: Offset(0, 8))],
          ),
          child: Icon(
            listening ? LucideIcons.arrowUp : LucideIcons.mic,
            size: 32,
            color: busy ? const Color(0x663C3C43) : Colors.white,
          ),
        ),
      ),
    );
  }
}
