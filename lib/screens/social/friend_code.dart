import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/services/friend_service.dart';
import '../../providers/app_providers.dart';
import '../../widgets/profile_image.dart';
import '../../widgets/top_notification.dart';
import '../onboarding/ob_forms.dart';
import '../onboarding/ob_style.dart';

const _prefix = 'scorecaddie://friend/add/';

/// "My code": the QR friends scan to add you, plus the code to type.
Future<void> showMyFriendCode(BuildContext context, WidgetRef ref) {
  final p = ref.read(userProfileProvider).valueOrNull;
  if (p?.friendCode == null) {
    ref.read(friendServiceProvider).ensureFriendCode().then((_) => ref.invalidate(userProfileProvider));
  }
  return showObSheet(context, (_) => const _MyCodeSheet());
}

class _MyCodeSheet extends ConsumerWidget {
  const _MyCodeSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(userProfileProvider).valueOrNull;
    final code = p?.friendCode;
    return ObSheet(
      title: 'Your friend code',
      subtitle: 'Friends scan this on the 1st tee to add you.',
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Ob.cream, borderRadius: BorderRadius.circular(28)),
            child: SizedBox(
              width: 210,
              height: 210,
              child: code == null
                  ? const Center(child: CupertinoActivityIndicator(color: Ob.ink))
                  : QrImageView(
                      data: '$_prefix$code',
                      version: QrVersions.auto,
                      eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Ob.ink),
                      dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.circle, color: Ob.ink),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          ProfileImage(url: p?.avatarUrl, name: p?.name, size: 28, isCircle: true),
          const SizedBox(width: 8),
          Text(p?.name ?? 'Golfer', style: Ob.body(15, weight: FontWeight.w800)),
        ]),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: code == null
              ? null
              : () {
                  Clipboard.setData(ClipboardData(text: code));
                  TopNotification.showSuccess(context, 'Code copied');
                },
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(code ?? 'Making your code…', style: Ob.display(24, color: Ob.lime).copyWith(letterSpacing: 2)),
            if (code != null) ...[const SizedBox(width: 8), Icon(LucideIcons.copy, size: 16, color: Ob.creamA(.6))],
          ]),
        ),
        const SizedBox(height: 16),
        ObButton(
          tone: ObButtonTone.dark,
          onPressed: code == null ? null : () => Share.share('Add me on ScoreCaddie: $code'),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(LucideIcons.share2, size: 18, color: Ob.cream),
            const SizedBox(width: 8),
            Text('Share my code', style: Ob.label(15, weight: FontWeight.w800)),
          ]),
        ),
      ]),
    );
  }
}

/// Scans a friend's code and offers to send them a request.
Future<void> scanFriendCode(BuildContext context, WidgetRef ref) async {
  final status = await Permission.camera.request();
  if (!context.mounted) return;
  if (!status.isGranted) {
    TopNotification.showError(context, 'ScoreCaddie needs the camera to scan codes.');
    return;
  }
  final code = await Navigator.of(context).push<String>(MaterialPageRoute(fullscreenDialog: true, builder: (_) => const _Scanner()));
  if (code != null && context.mounted) await addFriendByCode(context, ref, code);
}

/// Looks a code up and confirms before sending the request.
Future<void> addFriendByCode(BuildContext context, WidgetRef ref, String code) async {
  final service = ref.read(friendServiceProvider);
  if (FriendService.normalizeFriendCode(code) == null) {
    TopNotification.showError(context, 'Friend codes look like SC-AB12-CD34. Check it and try again.');
    return;
  }
  final profile = await service.fetchProfile(code);
  if (!context.mounted) return;
  if (profile == null) {
    TopNotification.showError(context, 'No golfer with that code. Check it and try again.');
    return;
  }
  if (profile['uid'] == ref.read(authStateProvider).valueOrNull?.id) {
    TopNotification.showError(context, 'That\'s your own code.');
    return;
  }
  final ok = await showObSheet<bool>(
    context,
    (ctx) => ObSheet(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Center(child: ProfileImage(url: profile['avatarUrl'], name: profile['name'], size: 84, isCircle: true)),
        const SizedBox(height: 12),
        Text('${profile['name'] ?? 'Golfer'}', textAlign: TextAlign.center, style: Ob.display(26)),
        const SizedBox(height: 4),
        Text('Send a friend request?', textAlign: TextAlign.center, style: Ob.body(14, color: Ob.creamA(.65))),
        const SizedBox(height: 18),
        Row(children: [
          Expanded(child: ObButton(tone: ObButtonTone.dark, onPressed: () => Navigator.pop(ctx, false), child: Text('Not now', style: Ob.label(15, weight: FontWeight.w800)))),
          const SizedBox(width: 10),
          Expanded(child: ObButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Send request', style: Ob.label(15, weight: FontWeight.w800)))),
        ]),
      ]),
    ),
  );
  if (ok != true || !context.mounted) return;
  final result = await ref.read(friendServiceProvider).sendFriendRequest(profile['uid'] as String);
  if (!context.mounted) return;
  final name = '${profile['name'] ?? 'They'}';
  switch (result) {
    case FriendRequestResult.sent:
      TopNotification.showSuccess(context, 'Request sent to $name');
    case FriendRequestResult.nowFriends:
      TopNotification.showSuccess(context, '$name had already asked. You\'re friends now.');
    case FriendRequestResult.alreadySent:
      TopNotification.showSuccess(context, 'You already asked $name. Waiting for them to accept.');
    case FriendRequestResult.alreadyFriends:
      TopNotification.showSuccess(context, 'You and $name are already friends.');
    case FriendRequestResult.self:
      TopNotification.showError(context, 'That\'s your own code.');
    case FriendRequestResult.failed:
      TopNotification.showError(context, 'Couldn\'t send the request. Check your connection and try again.');
  }
}

class _Scanner extends StatefulWidget {
  const _Scanner();

  @override
  State<_Scanner> createState() => _ScannerState();
}

class _ScannerState extends State<_Scanner> {
  final _controller = MobileScannerController();
  bool _done = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_done) return;
    for (final b in capture.barcodes) {
      final raw = b.rawValue;
      if (raw == null) continue;
      final code = FriendService.normalizeFriendCode(raw.startsWith(_prefix) ? raw.substring(_prefix.length) : raw);
      if (code != null) {
        _done = true;
        HapticFeedback.mediumImpact();
        Navigator.pop(context, code);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: Ob.overlay,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(children: [
          Positioned.fill(child: MobileScanner(controller: _controller, onDetect: _onDetect)),
          Positioned.fill(child: CustomPaint(painter: _ScrimPainter())),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                Row(children: [
                  ObIconButton(icon: LucideIcons.x, label: 'Close', onPressed: () => Navigator.pop(context)),
                  const Spacer(),
                  ObIconButton(icon: LucideIcons.zap, label: 'Torch', onPressed: () => _controller.toggleTorch()),
                ]),
                const Spacer(),
                Text('Scan a friend\'s code', style: Ob.display(26)),
                const SizedBox(height: 6),
                Text('It\'s on their profile, under the QR button.', style: Ob.body(14, color: Ob.creamA(.7))),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

/// Darkens everything but a rounded lime-edged window in the middle.
class _ScrimPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final side = size.width * .68;
    final r = RRect.fromRectAndRadius(Rect.fromCenter(center: size.center(Offset.zero).translate(0, -30), width: side, height: side), const Radius.circular(28));
    canvas.drawPath(
      Path.combine(PathOperation.difference, Path()..addRect(Offset.zero & size), Path()..addRRect(r)),
      Paint()..color = const Color(0xB3060F0A),
    );
    canvas.drawRRect(r, Paint()
      ..color = Ob.lime
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
