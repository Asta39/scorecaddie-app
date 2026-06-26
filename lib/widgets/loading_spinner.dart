import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LoadingSpinner extends StatelessWidget {
  final double size;
  final bool isFullScreen;

  const LoadingSpinner({
    super.key,
    this.size = 120,
    this.isFullScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    final spinner = Center(
      child: Lottie.asset(
        'assets/animations/sandy-loading.json',
        width: size,
        height: size,
      ),
    );

    if (isFullScreen) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: spinner,
      );
    }
    return spinner;
  }
}
