import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart' as pdfrx;
import '../widgets/pdf_viewer.dart';
import '../widgets/warning_banner.dart';
import '../widgets/drawing_toolbar.dart';
import '../widgets/drawing_canvas.dart';

import '../providers/pdf_viewer_provider.dart';
import '../providers/drawing_provider.dart';
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
  Matrix4? _savedViewMatrix;

  @override
  void initState() {
    super.initState();
    // Inizializza controller PDF con gestione ottimizzata del ciclo di vita
    _pdfController = pdfrx.PdfViewerController();

    // Carica documento dopo il frame build per evitare blocchi UI
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pdfViewerProvider.notifier).loadDocument(widget.document);
    });

    // Listener per preservare posizione quando cambia modalità
    ref.listenManual(drawingModeProvider, (previous, next) {
      if (_pdfController.isReady) {
        // Salva la matrice corrente prima del cambio
        _savedViewMatrix = _pdfController.value;

        // Ripristina dopo il rebuild
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_savedViewMatrix != null && _pdfController.isReady) {
            _pdfController.value = _savedViewMatrix!;
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch providers ottimizzati - rebuild solo quando necessario
    final viewerState = ref.watch(pdfViewerProvider);
    final isDrawingMode = ref.watch(drawingModeProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Contenuto principale con layout ottimizzato
          Column(
            children: [
              // Barra superiore con informazioni documento e controlli
              _buildTopBar(context),

              // Toolbar per disegno
              if (isDrawingMode)
                const DrawingToolbar(),

              // Area contenuto PDF
              Expanded(
                child: Stack(
                  children: [
                    _buildPdfContentArea(context, viewerState),
                    // Layer per disegno
                    if (isDrawingMode)
                      _buildDrawingLayer(context, viewerState),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      // Floating action buttons ottimizzati
      floatingActionButton: _buildFloatingActions(context, isDrawingMode),
    );
  }

  /// Costruisce la barra superiore con controlli documento
  Widget _buildTopBar(BuildContext context) {
    return Container(
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
          // Nome documento con ellipsis per overflow
          Expanded(
            child: Text(
              widget.document.name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          // Controlli PDF integrati nella barra
          _PdfControls(
            document: widget.document,
            controller: _pdfController,
          ),
          
          // Menu azioni documento
          _buildActionMenu(context),
        ],
      ),
    );
  }

  /// Costruisce il menu azioni con opzioni stampa, condivisione e info
  Widget _buildActionMenu(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: _handleMenuAction,
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
    );
  }

  /// Gestisce le azioni del menu in modo centralizzato
  void _handleMenuAction(String value) {
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
  }

  /// Costruisce l'area contenuto PDF con gestione stati ottimizzata
  Widget _buildPdfContentArea(BuildContext context, PdfViewerState viewerState) {
    return Stack(
      children: [
        // Banner avviso per PDF senza testo ricercabile
        if (!widget.document.hasSearchableText)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: WarningBanner(),
          ),
        
        // Visualizzatore PDF con gestione stati
        Positioned.fill(
          top: !widget.document.hasSearchableText ? 60 : 0,
          child: _buildPdfViewer(context, viewerState),
        ),
      ],
    );
  }

  /// Costruisce il layer per disegno
  Widget _buildDrawingLayer(BuildContext context, PdfViewerState viewerState) {
    if (viewerState.isLoading) return const SizedBox.shrink();
    
    return Positioned.fill(
      top: !widget.document.hasSearchableText ? 60 : 0,
      child: SimpleDrawingCanvas(
        controller: _pdfController,
        child: const SizedBox.shrink(),
      ),
    );
  }

  /// Costruisce il visualizzatore PDF con gestione loading/error states
  Widget _buildPdfViewer(BuildContext context, PdfViewerState viewerState) {
    if (viewerState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (viewerState.error != null) {
      return _buildErrorState(context, viewerState.error!);
    }
    
    return PdfViewerWidget(
      state: viewerState,
      document: widget.document,
      controller: _pdfController,
    );
  }

  /// Costruisce l'interfaccia di errore con opzioni appropriate
  Widget _buildErrorState(BuildContext context, String error) {
    return Center(
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
    );
  }

  /// Costruisce i floating action buttons ottimizzati
  Widget _buildFloatingActions(BuildContext context, bool isDrawingMode) {
    return FloatingActionButton(
      onPressed: () {
        ref.read(drawingModeProvider.notifier).state = !isDrawingMode;
      },
      backgroundColor: isDrawingMode
          ? Theme.of(context).colorScheme.primary
          : Theme.of(context).colorScheme.surface,
      child: Icon(
        isDrawingMode ? Icons.close : Icons.brush,
        color: isDrawingMode
            ? Theme.of(context).colorScheme.onPrimary
            : Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  /// Stampa il documento PDF utilizzando il servizio di stampa
  void _printPdf() {
    // TODO: Implementare stampa con PdfService.printPdf()
  }

  /// Condivide il documento PDF tramite platform share
  void _sharePdf() {
    // TODO: Implementare condivisione file
  }

  /// Mostra dialogo informazioni documento con formattazione ottimizzata
  void _showDocumentInfo() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Informazioni documento'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Nome:', widget.document.name),
            _buildInfoRow('Dimensione:', _formatFileSize(widget.document.fileSize)),
            _buildInfoRow('Pagine:', widget.document.pageCount.toString()),
            _buildInfoRow('Protetto:', widget.document.isPasswordProtected ? "Sì" : "No"),
            _buildInfoRow('Testo ricercabile:', widget.document.hasSearchableText ? "Sì" : "No"),
            _buildInfoRow('Modificato:', _formatDate(widget.document.lastModified)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Chiudi'),
          ),
        ],
      ),
    );
  }

  /// Costruisce una riga informativa formattata per il dialogo
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  /// Formatta dimensione file in formato leggibile ottimizzato
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Formatta data in formato italiano ottimizzato
  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/${date.year} $hour:$minute';
  }

  /// Mostra dialogo per inserimento password PDF
  void _showPasswordDialog() {
    // TODO: Implementare dialogo password
  }
}

class _PdfControls extends StatefulWidget {
  final PdfDocument document;
  final pdfrx.PdfViewerController controller;

  const _PdfControls({
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
                    ? '${widget.controller.document.pages.length} pagine'
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
                        pageNumber: widget.controller.document.pages.length,
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