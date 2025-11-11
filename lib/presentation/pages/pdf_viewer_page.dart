import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart' as pdfrx;
import '../widgets/pdf_viewer.dart';
import '../widgets/warning_banner.dart';
import '../widgets/drawing_toolbar.dart';
import '../providers/pdf_viewer_provider.dart';
import '../../data/models/pdf_document.dart';

class PdfViewerPage extends ConsumerStatefulWidget {
  final PdfDocument document;
  
  const PdfViewerPage({
    super.key,
    required this.document,
  });

  @override
  ConsumerState<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends ConsumerState<PdfViewerPage> {
  late final pdfrx.PdfViewerController _pdfController;

  @override
  void initState() {
    super.initState();
    _pdfController = pdfrx.PdfViewerController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pdfViewerProvider.notifier).loadDocument(widget.document);
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewerState = ref.watch(pdfViewerProvider);
    final isDrawingMode = ref.watch(drawingModeProvider);
    
    return Scaffold(
      body: Stack(
        children: [
          // Main content
          Column(
            children: [
              // Top bar with document info
              Container(
                height: 60,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.document.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // PDF controls in title bar
                    _PdfControls(
                      document: widget.document,
                      controller: _pdfController,
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'print':
                            _printPdf();
                            break;
                          case 'share':
                            _sharePdf();
                            break;
                          case 'info':
                            _showDocumentInfo();
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'print',
                          child: Row(
                            children: [
                              Icon(Icons.print),
                              SizedBox(width: 8),
                              Text('Stampa'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'share',
                          child: Row(
                            children: [
                              Icon(Icons.share),
                              SizedBox(width: 8),
                              Text('Condividi'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'info',
                          child: Row(
                            children: [
                              Icon(Icons.info_outline),
                              SizedBox(width: 8),
                              Text('Informazioni'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // PDF content area
              Expanded(
                child: Stack(
                  children: [
                    // Warning banner for non-OCR PDFs
                    if (!widget.document.hasSearchableText)
                      const Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: WarningBanner(),
                      ),
                    
                    // PDF Viewer
                    Positioned.fill(
                      top: !widget.document.hasSearchableText ? 60 : 0,
                      child: viewerState.isLoading 
                          ? const Center(
                              child: CircularProgressIndicator(),
                            )
                          : viewerState.error != null
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        size: 64,
                                        color: Colors.red,
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'Errore nel caricamento del PDF',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                      if (widget.document.isPasswordProtected)
                                        Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: ElevatedButton(
                                            onPressed: _showPasswordDialog,
                                            child: const Text('Inserisci password'),
                                          ),
                                        ),
                                    ],
                                  ),
                                )
                              : PdfViewerWidget(
                                  state: viewerState,
                                  document: widget.document,
                                  controller: _pdfController,
                                ),
                    ),
                    
                    // Drawing toolbar
                    if (isDrawingMode)
                      const Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: DrawingToolbar(),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drawing mode toggle
          FloatingActionButton(
            heroTag: "drawing",
            onPressed: () {
              // TODO: Implement drawing mode toggle
            },
            backgroundColor: isDrawingMode 
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.surface,
            child: Icon(
              isDrawingMode ? Icons.close : Icons.edit,
              color: isDrawingMode 
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          // Page navigation
          FloatingActionButton(
            heroTag: "navigation",
            onPressed: _showPageNavigation,
            child: const Icon(Icons.menu),
          ),
        ],
      ),
    );
  }

  void _printPdf() {
    // TODO: Implement printing
  }

  void _sharePdf() {
    // TODO: Implement sharing
  }

  void _showDocumentInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Informazioni documento'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nome: ${widget.document.name}'),
            Text('Dimensione: ${_formatFileSize(widget.document.fileSize)}'),
            Text('Pagine: ${widget.document.pageCount}'),
            Text('Protetto: ${widget.document.isPasswordProtected ? "Sì" : "No"}'),
            Text('Testo ricercabile: ${widget.document.hasSearchableText ? "Sì" : "No"}'),
            Text('Modificato: ${_formatDate(widget.document.lastModified)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Chiudi'),
          ),
        ],
      ),
    );
  }

  void _showPasswordDialog() {
    // TODO: Implement password dialog
  }

  void _showPageNavigation() {
    // TODO: Implement page navigation
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _PdfControls extends StatefulWidget {
  final PdfDocument document;
  final pdfrx.PdfViewerController controller;

  const _PdfControls({
    super.key,
    required this.document,
    required this.controller,
  });

  @override
  State<_PdfControls> createState() => _PdfControlsState();
}

class _PdfControlsState extends State<_PdfControls> {
  double _zoomLevel = 1.0;

  @override
  void initState() {
    super.initState();
    // Listen to controller to update UI
    widget.controller.addListener(_onControllerUpdate);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerUpdate);
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Zoom controls
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: _zoomLevel > 0.5 && widget.controller.isReady
                  ? () async {
                      final newZoom = (_zoomLevel - 0.25).clamp(0.5, 3.0);
                      await widget.controller.setZoom(const Offset(0, 0), newZoom);
                      setState(() {
                        _zoomLevel = newZoom;
                      });
                    }
                  : null,
              icon: const Icon(Icons.zoom_out, size: 20),
              iconSize: 20,
              style: IconButton.styleFrom(
                minimumSize: const Size(32, 32),
                padding: const EdgeInsets.all(4),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${(_zoomLevel * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            IconButton(
              onPressed: _zoomLevel < 3.0 && widget.controller.isReady
                  ? () async {
                      final newZoom = (_zoomLevel + 0.25).clamp(0.5, 3.0);
                      await widget.controller.setZoom(const Offset(0, 0), newZoom);
                      setState(() {
                        _zoomLevel = newZoom;
                      });
                    }
                  : null,
              icon: const Icon(Icons.zoom_in, size: 20),
              iconSize: 20,
              style: IconButton.styleFrom(
                minimumSize: const Size(32, 32),
                padding: const EdgeInsets.all(4),
              ),
            ),
            IconButton(
              onPressed: _zoomLevel != 1.0 && widget.controller.isReady
                  ? () async {
                      await widget.controller.setZoom(const Offset(0, 0), 1.0);
                      setState(() {
                        _zoomLevel = 1.0;
                      });
                    }
                  : null,
              icon: const Icon(Icons.fit_screen, size: 20),
              iconSize: 20,
              style: IconButton.styleFrom(
                minimumSize: const Size(32, 32),
                padding: const EdgeInsets.all(4),
              ),
            ),
          ],
        ),
        
        const SizedBox(width: 16),
        
        // Page navigation controls
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: widget.controller.isReady
                  ? () => widget.controller.goToPage(pageNumber: 1)
                  : null,
              icon: const Icon(Icons.keyboard_double_arrow_left, size: 20),
              iconSize: 20,
              style: IconButton.styleFrom(
                minimumSize: const Size(32, 32),
                padding: const EdgeInsets.all(4),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.controller.isReady
                    ? '${widget.controller.document?.pages.length ?? 0} pagine'
                    : 'Caricamento...',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            IconButton(
              onPressed: widget.controller.isReady
                  ? () => widget.controller.goToPage(
                        pageNumber: widget.controller.document!.pages.length,
                      )
                  : null,
              icon: const Icon(Icons.keyboard_arrow_right, size: 20),
              iconSize: 20,
              style: IconButton.styleFrom(
                minimumSize: const Size(32, 32),
                padding: const EdgeInsets.all(4),
              ),
            ),
          ],
        ),
      ],
    );
  }
}