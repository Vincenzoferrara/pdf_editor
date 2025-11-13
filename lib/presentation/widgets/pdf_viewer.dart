import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';
import '../../data/models/pdf_document.dart' as app_doc;
import '../providers/pdf_viewer_provider.dart';
import '../providers/editing_objects_provider.dart';
import 'editing_canvas.dart';


/// Widget ottimizzato per la visualizzazione PDF con pdfrx
/// Implementa caching, gesture handling ottimizzato e gestione memoria
class PdfViewerWidget extends ConsumerStatefulWidget {
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
  ConsumerState<PdfViewerWidget> createState() => _PdfViewerWidgetState();
}

class _PdfViewerWidgetState extends ConsumerState<PdfViewerWidget> {
  late final PdfViewerController _controller;

  @override
  void initState() {
    super.initState();
    // Inizializza controller con gestione ottimizzata del ciclo di vita
    _controller = widget.controller ?? PdfViewerController();
  }

  @override
  void dispose() {
    // NOTA: PdfViewerController di pdfrx non ha metodo dispose
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

    // PDF base con nuovo sistema di editing objects
    // Non facciamo watch di isActivelyDrawingProvider qui per evitare rebuild del PdfViewer
    return EditingCanvas(
      controller: _controller,
      child: PdfViewer.file(
        file.path,
        key: ValueKey(widget.document.filePath),
        controller: _controller,
        params: PdfViewerParams(
          scrollPhysics: const FixedOverscrollPhysics(maxOverscroll: 50),
          minScale: 0.5,
          maxScale: 3.0,
          // Sempre abilitato - il controllo dei gesti lo fa EditingCanvas
          panEnabled: true,
          scaleEnabled: true,
          panAxis: PanAxis.free,
          limitRenderingCache: true,
          maxImageBytesCachedOnMemory: 50 * 1024 * 1024,
          horizontalCacheExtent: 0.5,
          verticalCacheExtent: 0.5,
          textSelectionParams: const PdfTextSelectionParams(enabled: true),
          onePassRenderingScaleThreshold: 150 / 72,
          onePassRenderingSizeThreshold: 1500,
          pageDropShadow: null,
          backgroundColor: Colors.grey,
          margin: 4.0,
          annotationRenderingMode: PdfAnnotationRenderingMode.none,
          interactionEndFrictionCoefficient: 0.8,
          scrollByMouseWheel: 1.5,
          scrollHorizontallyByMouseWheel: false,
          enableKeyboardNavigation: false,
          boundaryMargin: const EdgeInsets.all(100),
          // NO pagePaintCallbacks - le annotazioni le disegna EditingCanvas
        ),
      ),
    );
  }
}