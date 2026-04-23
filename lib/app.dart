import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'providers/app_providers.dart';
import 'providers/sync_provider.dart';

class ScoreCaddieApp extends ConsumerWidget {
  const ScoreCaddieApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    // Initialize autonomous sync
    ref.watch(syncControllerProvider);

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
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
