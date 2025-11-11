import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import '../../data/models/pdf_document.dart' as app_doc;
import '../providers/pdf_viewer_provider.dart';

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
    _controller = widget.controller ?? PdfViewerController();
  }

  @override
  void dispose() {
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
          // Aggressively optimized PDF viewer for maximum performance
          PdfViewer.file(
          file.path,
          controller: _controller,
          params: PdfViewerParams(
            // Use FixedOverscrollPhysics for better gesture separation
            scrollPhysics: FixedOverscrollPhysics(maxOverscroll: 50),
            // Optimize rendering scale for performance
            minScale: 0.5,
            maxScale: 3.0,
            // Configure gestures properly to prevent conflicts
            panEnabled: true,
            scaleEnabled: true, // Re-enable zoom with proper configuration
            // Allow free panning but with gesture separation
            panAxis: PanAxis.free,
            // Reduce memory usage and improve performance
            limitRenderingCache: true,
            maxImageBytesCachedOnMemory: 50 * 1024 * 1024, // 50MB cache
            // Optimize cache extents for faster scrolling
            horizontalCacheExtent: 0.5,
            verticalCacheExtent: 0.5,
            // Disable text selection for better performance
            textSelectionParams: PdfTextSelectionParams(enabled: false),
            // Optimize rendering thresholds
            onePassRenderingScaleThreshold: 150 / 72, // Lower threshold for faster rendering
            onePassRenderingSizeThreshold: 1500, // Smaller threshold
            // Reduce visual effects for performance
            pageDropShadow: null, // Remove shadow for performance
            backgroundColor: Colors.grey, // Simple background
            margin: 4.0, // Smaller margin
            // Disable annotation rendering for performance
            annotationRenderingMode: PdfAnnotationRenderingMode.none,
            // Optimize interaction and gesture handling
            interactionEndFrictionCoefficient: 0.8, // Higher friction to prevent accidental zoom
            // Configure mouse wheel for vertical scrolling only
            scrollByMouseWheel: 1.5,
            scrollHorizontallyByMouseWheel: false,
            // Disable keyboard navigation for performance
            enableKeyboardNavigation: false,
            // Add gesture boundaries to prevent zoom conflicts
            boundaryMargin: const EdgeInsets.all(100),
          ),
        ),
      ],
    ),
    );
  }

}