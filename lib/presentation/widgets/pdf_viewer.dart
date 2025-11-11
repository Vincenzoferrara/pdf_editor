import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import '../../data/models/pdf_document.dart' as app_doc;
import '../providers/pdf_viewer_provider.dart';

/// Widget ottimizzato per la visualizzazione PDF con pdfrx
/// Implementa caching, gesture handling ottimizzato e gestione memoria
class PdfViewerWidget extends StatefulWidget {
  final PdfViewerState state;
  final app_doc.PdfDocument document;
  final PdfViewerController? controller;

  const PdfViewerWidget({
    super.key,
    required this.state,
    required this.document,
    this.controller,
  });

  @override
  State<PdfViewerWidget> createState() => _PdfViewerWidgetState();
}

class _PdfViewerWidgetState extends State<PdfViewerWidget> {
  late final PdfViewerController _controller;

  @override
  void initState() {
    super.initState();
    // Inizializza controller con gestione ottimizzata del ciclo di vita
    _controller = widget.controller ?? PdfViewerController();
  }

  @override
  void dispose() {
    // Pulizia risorse per prevenire memory leak
    // NOTA: PdfViewerController di pdfrx non ha metodo dispose
    // _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Handle loading state
    if (widget.state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    // Handle error state
    if (widget.state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 120,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 24),
            Text(
              'Errore nel caricamento PDF',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              widget.state.error!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Check if file exists before trying to load
    final file = File(widget.document.filePath);
    if (!file.existsSync()) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.file_present,
              size: 120,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 24),
            Text(
              'File non trovato',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Il file PDF non esiste nel percorso specificato',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RepaintBoundary(
      child: Stack(
        children: [
          // Visualizzatore PDF ottimizzato per massime prestazioni
          // Configurazione aggressiva per ridurre consumo memoria e migliorare rendering
          PdfViewer.file(
            file.path,
            controller: _controller,
            params: PdfViewerParams(
              // Fisica di scrolling ottimizzata per separazione gesture
              scrollPhysics: const FixedOverscrollPhysics(maxOverscroll: 50),
              
              // Limiti zoom ottimizzati per prestazioni e usabilità
              minScale: 0.5,
              maxScale: 3.0,
              
              // Configurazione gesture per prevenire conflitti
              panEnabled: true,
              scaleEnabled: true,
              panAxis: PanAxis.free,
              
              // Ottimizzazione memoria e cache rendering
              limitRenderingCache: true,
              maxImageBytesCachedOnMemory: 50 * 1024 * 1024, // 50MB cache
              
              // Cache extents ottimizzati per scrolling più fluido
              horizontalCacheExtent: 0.5,
              verticalCacheExtent: 0.5,
              
              // Disabilita selezione testo per migliori prestazioni
              textSelectionParams: const PdfTextSelectionParams(enabled: false),
              
              // Soglie rendering ottimizzate per rendering più rapido
              onePassRenderingScaleThreshold: 150 / 72,
              onePassRenderingSizeThreshold: 1500,
              
              // Riduci effetti visivi per prestazioni
              pageDropShadow: null, // Rimuove ombre per performance
              backgroundColor: Colors.grey,
              margin: 4.0,
              
              // Disabilita rendering annotazioni per performance
              annotationRenderingMode: PdfAnnotationRenderingMode.none,
              
              // Ottimizzazione interazione e gesture handling
              interactionEndFrictionCoefficient: 0.8,
              
              // Configurazione mouse wheel per scrolling verticale
              scrollByMouseWheel: 1.5,
              scrollHorizontallyByMouseWheel: false,
              
              // Disabilita navigazione tastiera per performance
              enableKeyboardNavigation: false,
              
              // Margini gesture per prevenire conflitti zoom
              boundaryMargin: const EdgeInsets.all(100),
            ),
          ),
        ],
      ),
    );
  }

}