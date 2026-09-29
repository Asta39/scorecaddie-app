import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'providers/app_providers.dart';
import 'widgets/offline_pill.dart';
import 'screens/onboarding/ob_style.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

bool _pushTapsWired = false;

class ScoreCaddieApp extends ConsumerWidget {
  const ScoreCaddieApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    // Initialize autonomous sync and handicap tracking
    ref.watch(syncControllerProvider);
    ref.watch(handicapTrackerProvider);

    // Tapping a push opens the screen it's about. Registered once: this
    // used to be added on every sign-in, so taps fired once per login.
    if (!_pushTapsWired) {
      _pushTapsWired = true;
      OneSignal.Notifications.addClickListener((event) {
        final data = event.notification.additionalData;
        final route = data?['route'];
        if (route is String && route.startsWith('/')) {
          router.push(route);
        } else if (data?['type'] == 'tee_time_reminder') {
          router.push('/tee-times');
        } else if (data?['club_id'] != null) {
          router.push('/club-life');
        }
      });
    }

    // Initialize Supabase Realtime when user is available
    ref.listen(authStateProvider, (previous, next) {
      if (next.value != null && previous?.value == null) {
        debugPrint('APP: User logged in, initializing Supabase Realtime');
        ref.read(supabaseServiceProvider).init();
      }
    });

    return MaterialApp.router(
      title: 'ScoreCaddie',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      // Keep the app on light surfaces to preserve expected white backgrounds.
      themeMode: ThemeMode.light,
      routerConfig: router,
      builder: (context, child) {
        return Stack(children: [
          Positioned.fill(child: _scaled(context, child)),
          const Positioned(top: 0, left: 0, right: 0, child: Material(type: MaterialType.transparency, child: OfflinePill())),
        ]);
      },
    );
  }

  Widget _scaled(BuildContext context, Widget? child) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          // The app is dark throughout; light status/nav icons everywhere.
          value: Ob.overlay,
          child: child != null
              ? LayoutBuilder(
                  builder: (context, constraints) {
                    final mediaQuery = MediaQuery.of(context);
                    final width = mediaQuery.size.width;
                    final height = mediaQuery.size.height;
                    
                    // Design baseline: 390 width (standard modern mobile screen)
                    const double baselineWidth = 390.0;
                    
                    if (width < baselineWidth && width > 0) {
                      final double scale = width / baselineWidth;
                      return FittedBox(
                        fit: BoxFit.fitWidth,
                        alignment: Alignment.topCenter,
                        child: SizedBox(
                          width: baselineWidth,
                          height: height / scale,
                          child: child,
                        ),
                      );
                    }
                    return child;
                  },
                )
              : const SizedBox.shrink(),
        );
  }
}
