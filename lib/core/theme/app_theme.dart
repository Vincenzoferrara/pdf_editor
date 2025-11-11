import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

/// Gestore temi ottimizzato con supporto Material You e performance
/// Implementa caching temi e configurazione ottimizzata per rendering
class AppTheme {
  /// Cache per temi light/dark per evitare ricreazioni non necessarie
  static ThemeData? _cachedLightTheme;
  static ThemeData? _cachedDarkTheme;
  static ColorScheme? _lastLightColorScheme;
  static ColorScheme? _lastDarkColorScheme;

  /// Tema light ottimizzato con caching per performance superiori
  static ThemeData lightTheme(ColorScheme? colorScheme) {
    final defaultColorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    );
    
    final finalColorScheme = colorScheme ?? defaultColorScheme;
    
    // Controlla cache per evitare ricreazioni
    if (_cachedLightTheme != null && _lastLightColorScheme == finalColorScheme) {
      return _cachedLightTheme!;
    }
    
    // Crea e cache tema ottimizzato
    _cachedLightTheme = _buildThemeData(finalColorScheme, Brightness.light);
    _lastLightColorScheme = finalColorScheme;
    
    return _cachedLightTheme!;
  }
  
  /// Tema dark ottimizzato con caching per performance superiori
  static ThemeData darkTheme(ColorScheme? colorScheme) {
    final defaultColorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
    );
    
    final finalColorScheme = colorScheme ?? defaultColorScheme;
    
    // Controlla cache per evitare ricreazioni
    if (_cachedDarkTheme != null && _lastDarkColorScheme == finalColorScheme) {
      return _cachedDarkTheme!;
    }
    
    // Crea e cache tema ottimizzato
    _cachedDarkTheme = _buildThemeData(finalColorScheme, Brightness.dark);
    _lastDarkColorScheme = finalColorScheme;
    
    return _cachedDarkTheme!;
  }

  /// Costruisce dati tema ottimizzati per entrambe le varianti
  /// Riduce duplicazione codice e migliora manutenibilità
  static ThemeData _buildThemeData(ColorScheme colorScheme, Brightness brightness) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: brightness,
      
      // AppBar theme ottimizzato
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: true,
        titleTextStyle: AppTextStyles.titleLarge.copyWith(
          color: colorScheme.onSurface,
        ),
      ),
      
      // Card theme ottimizzato con bordi arrotondati moderni
      cardTheme: CardThemeData(
        elevation: 1,
        color: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      
      // Elevated button theme ottimizzato
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: AppTextStyles.labelLarge,
        ),
      ),
      
      // FAB theme ottimizzato
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        shape: CircleBorder(),
        elevation: 4,
      ),
      
      // Bottom navigation bar theme ottimizzato
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 3,
        selectedLabelStyle: AppTextStyles.labelMedium,
        unselectedLabelStyle: AppTextStyles.labelMedium,
      ),
      
      // Input decoration theme ottimizzato
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      
      // Text theme ottimizzato con stili predefiniti
      textTheme: TextTheme(
        displayLarge: AppTextStyles.headlineLarge,
        displayMedium: AppTextStyles.headlineMedium,
        displaySmall: AppTextStyles.headlineSmall,
        headlineLarge: AppTextStyles.headlineLarge,
        headlineMedium: AppTextStyles.headlineMedium,
        headlineSmall: AppTextStyles.headlineSmall,
        titleLarge: AppTextStyles.titleLarge,
        titleMedium: AppTextStyles.titleMedium,
        titleSmall: AppTextStyles.titleSmall,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        bodySmall: AppTextStyles.bodySmall,
        labelLarge: AppTextStyles.labelLarge,
        labelMedium: AppTextStyles.labelMedium,
        labelSmall: AppTextStyles.labelSmall,
      ),
    );
  }
  
  /// Builder per tema con supporto Material You ottimizzato
  /// Utilizza DynamicColorBuilder per colori dinamici del sistema
  static Widget buildWithTheme({
    required Widget Function(ThemeData light, ThemeData dark) builder,
  }) {
    return DynamicColorBuilder(
      builder: (lightColorScheme, darkColorScheme) {
        // Costruisce temi con colori dinamici del sistema
        return builder(
          lightTheme(lightColorScheme),
          darkTheme(darkColorScheme),
        );
      },
    );
  }

  /// Pulisce cache temi per liberare memoria (chiamare quando necessario)
  static void clearThemeCache() {
    _cachedLightTheme = null;
    _cachedDarkTheme = null;
    _lastLightColorScheme = null;
    _lastDarkColorScheme = null;
  }
}