import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../widgets/floating_action_button.dart';
import '../widgets/custom_window_controls.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/document_grid.dart';
import '../widgets/warning_banner.dart';
import '../../core/theme/theme_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = !kIsWeb && (defaultTargetPlatform == TargetPlatform.windows || 
                                  defaultTargetPlatform == TargetPlatform.linux || 
                                  defaultTargetPlatform == TargetPlatform.macOS);
    
    if (isDesktop) {
      // Desktop layout with native window controls
      return Scaffold(
        body: Column(
          children: [
            // Desktop window controls bar
            const CustomWindowControls(),
            
            // Main content
            Expanded(
              child: Column(
                children: [
                  // Warning banner for OCR functionality
                  const WarningBanner(),
                  
                  // Document grid
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
    } else {
      // Mobile layout with AppBar
      return Scaffold(
        appBar: AppBar(
          title: const Text('Editor PDF'),
          actions: [
            IconButton(
              icon: const Icon(Icons.brightness_6),
              onPressed: () {
                ref.read(themeProvider.notifier).toggleTheme();
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // Warning banner for OCR functionality
            const WarningBanner(),
            
            // Document grid
            const Expanded(child: DocumentGrid()),
          ],
        ),
        floatingActionButton: const CustomFloatingActionButton(),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: const BottomNavigationWidget(),
      );
    }
  }
}