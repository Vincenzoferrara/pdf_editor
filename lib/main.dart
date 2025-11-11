import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/theme_provider.dart';
import '../presentation/providers/router_provider.dart';

/// Punto di ingresso principale dell'applicazione PDF Editor
/// Ottimizzato per prestazioni con inizializzazione controllata
void main() async {
  // Garantisce che i binding di Flutter siano completamente inizializzati
  // prima di eseguire qualsiasi operazione asincrona
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inizializza la libreria pdfrx per il supporto PDF multipiattaforma
  // Essenziale per il rendering ottimizzato dei documenti PDF
  pdfrxFlutterInitialize();
  
  // Avvia l'app con ProviderScope per la gestione dello stato globale
  // Riverpod offre prestazioni superiori e gestione dello stato reattiva
  runApp(
    const ProviderScope(
      child: EditorPdfApp(),
    ),
  );
}

/// Widget principale dell'applicazione che gestisce tema e routing
/// Utilizza ConsumerWidget per ottimizzare i rebuild solo quando necessario
class EditorPdfApp extends ConsumerWidget {
  const EditorPdfApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch del provider del tema - rebuild solo quando il tema cambia
    final themeMode = ref.watch(themeProvider);
    
    // Watch del router - rebuild solo quando la configurazione del routing cambia
    final router = ref.watch(routerProvider);
    
    // Costruzione dell'app con supporto per colori dinamici (Material You)
    return AppTheme.buildWithTheme(
      builder: (lightTheme, darkTheme) {
        return MaterialApp.router(
          title: 'Editor PDF',
          // Disabilita il banner di debug per prestazioni migliori in produzione
          debugShowCheckedModeBanner: false,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeMode,
          // Configurazione del routing con GoRouter per navigazione ottimizzata
          routerConfig: router,
        );
      },
    );
  }
}