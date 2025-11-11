import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/theme_provider.dart';
import '../presentation/providers/router_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize pdfrx for cross-platform PDF support
  pdfrxFlutterInitialize();
  
  runApp(
    const ProviderScope(
      child: EditorPdfApp(),
    ),
  );
}

class EditorPdfApp extends ConsumerWidget {
  const EditorPdfApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final router = ref.watch(routerProvider);
    
    return AppTheme.buildWithTheme(
      builder: (lightTheme, darkTheme) {
        return MaterialApp.router(
          title: 'Editor PDF',
          debugShowCheckedModeBanner: false,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeMode,
          routerConfig: router,
        );
      },
    );
  }
}