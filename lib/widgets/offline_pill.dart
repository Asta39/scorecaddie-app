import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../screens/onboarding/ob_style.dart';

/// Whether the server is reachable. Wi-Fi with no internet (as happened on
/// the test phone) still reports "connected", so this looks the host up
/// rather than trusting the connection type.
final onlineProvider = StreamProvider<bool>((ref) {
  // No network probing under `flutter test`.
  if (Platform.environment.containsKey('FLUTTER_TEST')) return Stream.value(true);
  final controller = StreamController<bool>();
  bool? last;
  Timer? timer;

  Future<void> check() async {
    bool ok;
    try {
      final r = await InternetAddress.lookup('supabase.co').timeout(const Duration(seconds: 4));
      ok = r.isNotEmpty && r.first.rawAddress.isNotEmpty;
    } catch (_) {
      ok = false;
    }
    if (ok != last && !controller.isClosed) {
      last = ok;
      controller.add(ok);
    }
    // Recheck often while offline so the pill clears promptly.
    timer?.cancel();
    timer = Timer(Duration(seconds: ok ? 60 : 10), check);
  }

  final sub = Connectivity().onConnectivityChanged.listen((_) => check());
  check();
  ref.onDispose(() {
    timer?.cancel();
    sub.cancel();
    controller.close();
  });
  return controller.stream;
});

/// A small pill under the status bar while the app can't reach the server.
class OfflinePill extends ConsumerWidget {
  const OfflinePill({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offline = ref.watch(onlineProvider).valueOrNull == false;
    final top = MediaQuery.of(context).padding.top;
    return IgnorePointer(
      child: AnimatedSlide(
        offset: offline ? Offset.zero : const Offset(0, -2),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutBack,
        child: Padding(
          padding: EdgeInsets.only(top: top + 6),
          child: Align(
            alignment: Alignment.topCenter,
            child: Semantics(
              liveRegion: true,
              label: offline ? 'Offline. Changes save on your phone and sync later.' : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Ob.warn,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 12, offset: Offset(0, 4))],
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(LucideIcons.wifiOff, size: 14, color: Ob.ink),
                  const SizedBox(width: 6),
                  Text('Offline · saving on your phone', style: Ob.body(12, weight: FontWeight.w800, color: Ob.ink)),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
