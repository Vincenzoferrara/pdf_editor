import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../widgets/floating_action_button.dart';
import '../widgets/custom_window_controls.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/document_grid.dart';
import '../widgets/warning_banner.dart';
import '../../core/theme/theme_provider.dart';

/// Pagina principale dell'app con layout adattivo per desktop/mobile
/// Ottimizzata per prestazioni con widget const dove possibile
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Rilevamento piattaforma ottimizzato - calcolato una sola volta
    final isDesktop = !kIsWeb && (
      defaultTargetPlatform == TargetPlatform.windows || 
      defaultTargetPlatform == TargetPlatform.linux || 
      defaultTargetPlatform == TargetPlatform.macOS
    );
    
    if (isDesktop) {
      // Layout desktop con controlli finestra nativi
      return _buildDesktopLayout();
    } else {
      // Layout mobile con AppBar standard
      return _buildMobileLayout(ref);
    }
  }

  /// Costruisce il layout specifico per desktop con controlli finestra
  Widget _buildDesktopLayout() {
    return Scaffold(
      body: Column(
        children: [
          // Barra dei controlli finestra desktop
          const CustomWindowControls(),
          
          // Contenuto principale
          Expanded(
            child: Column(
              children: [
                // Banner di avviso per funzionalità OCR
                const WarningBanner(),
                
                // Griglia documenti espansa per riempire lo spazio disponibile
                const Expanded(child: DocumentGrid()),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: const CustomFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: const BottomNavigationWidget(),
    );
  }

  /// Costruisce il layout specifico per mobile con AppBar
  Widget _buildMobileLayout(WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editor PDF'),
        actions: [
          // Pulsante toggle tema con ottimizzazione rebuild
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: () {
              // Usa read invece di watch per evitare rebuild non necessari
              ref.read(themeProvider.notifier).toggleTheme();
            },
          ),
        ],
      ),
      body: const Column(
        children: [
          // Banner di avviso per funzionalità OCR
          WarningBanner(),
          
          // Griglia documenti espansa
          Expanded(child: DocumentGrid()),
        ],
      ),
      floatingActionButton: const CustomFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: const BottomNavigationWidget(),
    );
  }
}