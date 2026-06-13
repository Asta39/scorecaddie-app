import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'providers/app_providers.dart';

class ScoreCaddieApp extends ConsumerWidget {
  const ScoreCaddieApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    // Initialize autonomous sync and handicap tracking
    ref.watch(syncControllerProvider);
    ref.watch(handicapTrackerProvider);

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
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
            systemNavigationBarColor: Colors.white,
            systemNavigationBarIconBrightness: Brightness.dark,
          ),
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
      },
    );
  }
}
