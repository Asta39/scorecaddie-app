import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_providers.dart';

final navIndexProvider = StateProvider<int>((ref) => 0);

final themeModeProvider = Provider<ThemeMode>((ref) {
  final profile = ref.watch(userProfileProvider).valueOrNull;
  final mode = profile?.themeMode ?? 'Light';
  
  switch (mode) {
    case 'Dark': return ThemeMode.dark;
    case 'Light': return ThemeMode.light;
    case 'System': return ThemeMode.system;
    default: return ThemeMode.light;
  }
});
