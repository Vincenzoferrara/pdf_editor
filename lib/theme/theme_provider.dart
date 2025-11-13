import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';

/// Modalità tema
enum ThemeMode {
  light,
  dark,
  system,
}

/// Stato tema completo
class ThemeState {
  final ThemeMode themeMode;
  final String primaryColorName;

  const ThemeState({
    this.themeMode = ThemeMode.system,
    this.primaryColorName = 'Blu',
  });

  ThemeState copyWith({
    ThemeMode? themeMode,
    String? primaryColorName,
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      primaryColorName: primaryColorName ?? this.primaryColorName,
    );
  }

  Color get primaryColor =>
      AppTheme.primaryColors[primaryColorName] ?? Colors.blue;
}

/// Provider tema con persistenza
class ThemeNotifier extends StateNotifier<ThemeState> {
  ThemeNotifier() : super(const ThemeState()) {
    _loadPreferences();
  }

  static const _themeModeKey = 'theme_mode';
  static const _primaryColorKey = 'primary_color';

  /// Carica preferenze salvate
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    final themeModeString = prefs.getString(_themeModeKey);
    final primaryColorName = prefs.getString(_primaryColorKey);

    state = ThemeState(
      themeMode: _parseThemeMode(themeModeString),
      primaryColorName: primaryColorName ?? 'Blu',
    );
  }

  /// Salva preferenze
  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, state.themeMode.name);
    await prefs.setString(_primaryColorKey, state.primaryColorName);
  }

  /// Imposta modalità tema
  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _savePreferences();
  }

  /// Imposta colore primario
  Future<void> setPrimaryColor(String colorName) async {
    state = state.copyWith(primaryColorName: colorName);
    await _savePreferences();
  }

  /// Toggle tema chiaro/scuro
  Future<void> toggleTheme() async {
    final newMode = state.themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    await setThemeMode(newMode);
  }

  ThemeMode _parseThemeMode(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.system;
    }
  }
}

/// Provider principale per il tema
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  return ThemeNotifier();
});
