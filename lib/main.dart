import 'package:flutter/material.dart' hide ThemeMode;
import 'package:flutter/material.dart' as material show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';
import 'presentation/providers/router_provider.dart';

/// Punto di ingresso principale - Editor PDF ottimizzato
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inizializza pdfrx per rendering PDF
  pdfrxFlutterInitialize();

  runApp(
    const ProviderScope(
      child: EditorPdfApp(),
    ),
  );
}

/// App principale con tema dinamico
class EditorPdfApp extends ConsumerWidget {
  const EditorPdfApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final router = ref.watch(routerProvider);

    // Ottieni tema Flutter in base alla modalità selezionata
    final flutterThemeMode = _getFlutterThemeMode(
      themeState.themeMode,
      context,
    );

    return MaterialApp.router(
      title: 'Editor PDF',
      debugShowCheckedModeBanner: false,

      // Temi con colore primario personalizzabile
      theme: AppTheme.lightTheme(themeState.primaryColor),
      darkTheme: AppTheme.darkTheme(themeState.primaryColor),
      themeMode: flutterThemeMode,

      routerConfig: router,
    );
  }

  /// Converti ThemeMode custom a ThemeMode Flutter
  material.ThemeMode _getFlutterThemeMode(
    ThemeMode mode,
    BuildContext context,
  ) {
    switch (mode) {
      case ThemeMode.light:
        return material.ThemeMode.light;
      case ThemeMode.dark:
        return material.ThemeMode.dark;
      case ThemeMode.system:
        return material.ThemeMode.system;
    }
  }
}
