import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Provider to store/retrieve SharedPreferences
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences not initialized');
});

// Provider for the current locale
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocaleNotifier(prefs);
});

class LocaleNotifier extends StateNotifier<Locale> {
  final SharedPreferences _prefs;
  static const String _localeKey = 'selected_locale';

  LocaleNotifier(this._prefs) : super(_getInitialLocale(_prefs));

  static Locale _getInitialLocale(SharedPreferences prefs) {
    final savedCode = prefs.getString(_localeKey);
    if (savedCode != null) {
      return Locale(savedCode);
    }
    // Default to English
    return const Locale('en');
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    await _prefs.setString(_localeKey, locale.languageCode);
  }

  void toggleLocale() {
    if (state.languageCode == 'en') {
      setLocale(const Locale('id'));
    } else {
      setLocale(const Locale('en'));
    }
  }
}
