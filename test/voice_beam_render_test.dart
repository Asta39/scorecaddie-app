import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:score_caddie/widgets/voice_beam.dart';
import 'package:score_caddie/widgets/voice_orb_visualizer.dart' show OrbState;

/// Pumps the beam for ~1.5 s of animation in one state.
Future<void> _run(WidgetTester tester, OrbState state, double level) async {
  await tester.binding.setSurfaceSize(const Size(390, 844));
  await tester.pumpWidget(
    MaterialApp(
      home: Container(
        color: Colors.black,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 360,
              child: VoiceBeam(state: state, level: level),
            ),
          ],
        ),
      ),
    ),
  );
  for (var i = 0; i < 90; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

void main() {
  testWidgets('VoiceBeam animates in every state without errors', (
    tester,
  ) async {
    await _run(tester, OrbState.idle, 0);
    await _run(tester, OrbState.listening, 0.85);
    await _run(tester, OrbState.thinking, 0);
    await _run(tester, OrbState.speaking, 0);
    expect(tester.takeException(), isNull);
  });
}
