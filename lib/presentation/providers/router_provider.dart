import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../pages/home_page.dart';
import '../pages/pdf_viewer_page.dart';
import '../pages/settings/settings_page.dart';
import '../../data/models/pdf_document.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/pdf_viewer',
        builder: (context, state) {
          final document = state.extra as PdfDocument?;
          if (document == null) {
            return const Scaffold(
              body: Center(
                child: Text('Documento non trovato'),
              ),
            );
          }
          return PdfViewerPage(document: document);
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Errore')),
      body: Center(
        child: Text('Pagina non trovata: ${state.uri.toString()}'),
      ),
    ),
  );
});