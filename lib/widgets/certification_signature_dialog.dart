import 'package:flutter/material.dart';
import 'signature_pad.dart';
import '../screens/onboarding/ob_style.dart';

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
    return DefaultTextStyle(
      style: Ob.textBase,
      child: Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: Ob.cardFill,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sign the card', style: Ob.display(26)),
            const SizedBox(height: 6),
            Text(
              'You and your marker both sign so the round counts for your handicap.',
              style: Ob.body(13, height: 1.45, color: Ob.creamA(.7)),
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
            Row(children: [
              Expanded(
                child: ObButton(tone: ObButtonTone.dark, onPressed: () => Navigator.pop(context, false), child: Text('Cancel', style: Ob.label(15, weight: FontWeight.w800))),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ObButton(
                  onPressed: (_playerSigned && _markerSigned) ? () => Navigator.pop(context, true) : null,
                  child: Text('Certify', style: Ob.label(15, weight: FontWeight.w800)),
                ),
              ),
            ]),
          ],
        ),
      ),
      ),
    );
  }
}
