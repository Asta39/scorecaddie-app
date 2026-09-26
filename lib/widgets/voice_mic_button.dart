import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/theme/app_theme.dart';
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
            color: listening
                ? Colors.white
                : Colors.white.withValues(alpha: busy ? 0.04 : 0.08),
            border: Border.all(
              color: Colors.white.withValues(alpha: listening ? 0 : 0.14),
            ),
          ),
          child: Icon(
            listening ? LucideIcons.arrowUp : LucideIcons.mic,
            size: 32,
            color: listening
                ? Colors.black
                : busy
                ? Colors.white24
                : AppColors.golfLime,
          ),
        ),
      ),
    );
  }
}
