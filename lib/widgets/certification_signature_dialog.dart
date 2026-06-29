import 'package:flutter/material.dart';
import 'signature_pad.dart';
import '../core/theme/app_theme.dart';

class CertificationSignatureDialog extends StatefulWidget {
  final String playerName;
  final String markerName;

  const CertificationSignatureDialog({
    super.key,
    required this.playerName,
    required this.markerName,
  });

  @override
  State<CertificationSignatureDialog> createState() => _CertificationSignatureDialogState();
}

class _CertificationSignatureDialogState extends State<CertificationSignatureDialog> {
  bool _playerSigned = false;
  bool _markerSigned = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: AppColors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Review & Sign Scorecard',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.grey900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Both player and marker must digitally sign to certify scores for handicap calculation.',
              style: TextStyle(color: AppColors.grey500, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 24),
            SignaturePad(
              label: 'Player Signature',
              name: widget.playerName,
              onSigned: (points) {
                final hasDrawing = points.any((p) => p != null);
                if (hasDrawing != _playerSigned) {
                  setState(() {
                    _playerSigned = hasDrawing;
                  });
                }
              },
              onClear: () {
                setState(() {
                  _playerSigned = false;
                });
              },
            ),
            const SizedBox(height: 24),
            SignaturePad(
              label: 'Marker Signature',
              name: widget.markerName,
              onSigned: (points) {
                final hasDrawing = points.any((p) => p != null);
                if (hasDrawing != _markerSigned) {
                  setState(() {
                    _markerSigned = hasDrawing;
                  });
                }
              },
              onClear: () {
                setState(() {
                  _markerSigned = false;
                });
              },
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.grey300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Cancel', style: TextStyle(color: AppColors.grey700, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: (_playerSigned && _markerSigned)
                          ? () => Navigator.pop(context, true)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.golfLime,
                        foregroundColor: AppColors.grey900,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        disabledBackgroundColor: AppColors.grey100,
                        disabledForegroundColor: AppColors.grey400,
                      ),
                      child: const Text('Certify & Submit', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
