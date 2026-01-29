import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Provider for the SharedPreferences instance (already defined in main.dart or locale_provider.dart, 
// but good to ensure availability. We'll reuse the one from main.dart/locale_provider.dart)
// Assuming a sharedProvider exists or we just rely on passing it or recreating a provider.
// Given previous context, there is a `sharedPreferencesProvider`.
// Let's assume it's available in a common location or redefine a localized one for now 
// if we can't find the original definition file easily, but better to import it if possible.
// Waiting to check where `sharedPreferencesProvider` is. It was seen in `locale_provider.dart`.

// Actually, let's look at `locale_provider.dart` to see where `sharedPreferencesProvider` is defined 
// to avoid duplication or import errors.
// For now, I will define the class and assume I can import the provider.

import 'locale_provider.dart'; 

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeNotifier(prefs);
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  final SharedPreferences _prefs;
  static const _key = 'theme_mode';

  ThemeNotifier(this._prefs) : super(_loadTheme(_prefs));

  static ThemeMode _loadTheme(SharedPreferences prefs) {
    final index = prefs.getInt(_key);
    if (index == null) return ThemeMode.system;
    return ThemeMode.values[index];
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    await _prefs.setInt(_key, mode.index);
  }
}
