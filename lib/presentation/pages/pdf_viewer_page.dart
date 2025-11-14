import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pdfrx/pdfrx.dart' as pdfrx;
import '../widgets/pdf_viewer.dart';
import '../widgets/warning_banner.dart';
import '../widgets/drawing_toolbar.dart';

import '../providers/pdf_viewer_provider.dart';
import '../providers/drawing_provider.dart';
import '../../data/models/pdf_document.dart';
import '../../data/services/pdf_manipulation_service.dart';

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
                child: _buildPdfContentArea(context, viewerState),
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
        const PopupMenuItem(
          value: 'settings',
          child: Row(
            children: [
              Icon(Icons.settings_outlined),
              SizedBox(width: 8),
              Text('Impostazioni'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'rotate',
          child: Row(
            children: [
              Icon(Icons.rotate_90_degrees_cw),
              SizedBox(width: 8),
              Text('Ruota pagina'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'merge',
          child: Row(
            children: [
              Icon(Icons.merge_type),
              SizedBox(width: 8),
              Text('Unisci PDF'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'reorder',
          child: Row(
            children: [
              Icon(Icons.reorder),
              SizedBox(width: 8),
              Text('Riordina pagine'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'extract',
          child: Row(
            children: [
              Icon(Icons.content_cut),
              SizedBox(width: 8),
              Text('Estrai pagine'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete_pages',
          child: Row(
            children: [
              Icon(Icons.delete_outline),
              SizedBox(width: 8),
              Text('Elimina pagine'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'add_image',
          child: Row(
            children: [
              Icon(Icons.image),
              SizedBox(width: 8),
              Text('Aggiungi immagine'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'add_link',
          child: Row(
            children: [
              Icon(Icons.link),
              SizedBox(width: 8),
              Text('Aggiungi link'),
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
      case 'settings':
        context.push('/settings');
        break;
      case 'rotate':
        _rotatePage();
        break;
      case 'merge':
        _mergePdf();
        break;
      case 'reorder':
        _reorderPages();
        break;
      case 'extract':
        _extractPages();
        break;
      case 'delete_pages':
        _deletePages();
        break;
      case 'add_image':
        _addImage();
        break;
      case 'add_link':
        _addLink();
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

  /// Ruota la pagina corrente di 90 gradi
  void _rotatePage() async {
    // Ottieni pagina corrente dal controller
    int currentPage = 0;
    if (_pdfController.isReady) {
      // pdfrx non ha un metodo diretto per ottenere la pagina corrente
      // Useremo la prima pagina come default
      currentPage = 0;
    }

    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ruota pagina'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Ruota la pagina ${currentPage + 1}'),
            const SizedBox(height: 16),
            const Text('Seleziona l\'angolo di rotazione:'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 90),
            child: const Text('90° →'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 180),
            child: const Text('180° ↓'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 270),
            child: const Text('270° ←'),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      _performRotation(currentPage, result);
    }
  }

  Future<void> _performRotation(int pageIndex, int angle) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final outputPath = await PdfManipulationService.rotatePage(
        filePath: widget.document.filePath,
        pageIndex: pageIndex,
        rotationAngle: angle,
      );

      if (mounted) {
        Navigator.pop(context); // Chiudi loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pagina ruotata! Salvato in: $outputPath')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Chiudi loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Unisci un altro PDF con questo
  void _mergePdf() async {
    try {
      final selectedFiles = await PdfManipulationService.pickPdfsToMerge();

      if (selectedFiles == null || selectedFiles.isEmpty) {
        return;
      }

      // Aggiungi il PDF corrente all'inizio della lista
      final filesToMerge = [widget.document.filePath, ...selectedFiles];

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator()),
        );
      }

      final outputPath = await PdfManipulationService.mergePdfs(
        filePaths: filesToMerge,
      );

      if (mounted) {
        Navigator.pop(context); // Chiudi loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF uniti! Salvato in: $outputPath')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Chiudi loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Riordina le pagine del PDF
  void _reorderPages() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Usa Estrai o Elimina pagine per riorganizzare'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  /// Estrai pagine selezionate in un nuovo PDF
  void _extractPages() async {
    final TextEditingController controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Estrai pagine'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Documento ha ${widget.document.pageCount} pagine'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Pagine da estrarre',
                hintText: 'es: 1,3,5-7',
                helperText: 'Usa virgole e trattini',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Estrai'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && mounted) {
      _performExtraction(result);
    }
  }

  Future<void> _performExtraction(String pagesString) async {
    try {
      final List<int> pageIndices = _parsePageNumbers(pagesString);

      if (pageIndices.isEmpty) {
        throw Exception('Nessuna pagina valida specificata');
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final outputPath = await PdfManipulationService.extractPages(
        filePath: widget.document.filePath,
        pageIndices: pageIndices,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pagine estratte! Salvato in: $outputPath')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Elimina pagine selezionate
  void _deletePages() async {
    final TextEditingController controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina pagine'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Documento ha ${widget.document.pageCount} pagine'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Pagine da eliminare',
                hintText: 'es: 2,4,6-8',
                helperText: 'Usa virgole e trattini',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && mounted) {
      _performDeletion(result);
    }
  }

  Future<void> _performDeletion(String pagesString) async {
    try {
      final List<int> pageIndices = _parsePageNumbers(pagesString);

      if (pageIndices.isEmpty) {
        throw Exception('Nessuna pagina valida specificata');
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final outputPath = await PdfManipulationService.deletePages(
        filePath: widget.document.filePath,
        pageIndices: pageIndices,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pagine eliminate! Salvato in: $outputPath')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Parse page numbers from string like "1,3,5-7"
  List<int> _parsePageNumbers(String input) {
    final List<int> pages = [];
    final parts = input.split(',');

    for (final part in parts) {
      final trimmed = part.trim();
      if (trimmed.contains('-')) {
        final range = trimmed.split('-');
        if (range.length == 2) {
          final start = int.tryParse(range[0].trim());
          final end = int.tryParse(range[1].trim());
          if (start != null && end != null) {
            for (int i = start; i <= end; i++) {
              if (i > 0 && i <= widget.document.pageCount) {
                pages.add(i - 1); // Convert to 0-based index
              }
            }
          }
        }
      } else {
        final num = int.tryParse(trimmed);
        if (num != null && num > 0 && num <= widget.document.pageCount) {
          pages.add(num - 1); // Convert to 0-based index
        }
      }
    }

    return pages.toSet().toList()..sort();
  }

  /// Aggiungi immagine al PDF
  void _addImage() async {
    try {
      final imagePath = await PdfManipulationService.pickImage();

      if (imagePath == null) {
        return;
      }

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator()),
        );
      }

      // Aggiungi immagine alla prima pagina, centrata
      final outputPath = await PdfManipulationService.addImageToPage(
        filePath: widget.document.filePath,
        pageIndex: 0,
        imagePath: imagePath,
        x: 50,
        y: 50,
        width: 200,
        height: 200,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Immagine aggiunta! Salvato in: $outputPath')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Aggiungi link al PDF
  void _addLink() async {
    final TextEditingController urlController = TextEditingController();
    final TextEditingController textController = TextEditingController();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aggiungi link'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: 'URL',
                hintText: 'https://esempio.com',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: textController,
              decoration: const InputDecoration(
                labelText: 'Testo (opzionale)',
                hintText: 'Clicca qui',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () {
              if (urlController.text.isNotEmpty) {
                Navigator.pop(context, {
                  'url': urlController.text,
                  'text': textController.text,
                });
              }
            },
            child: const Text('Aggiungi'),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      _performAddLink(result['url']!, result['text']);
    }
  }

  Future<void> _performAddLink(String url, String? text) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final outputPath = await PdfManipulationService.addLinkToPage(
        filePath: widget.document.filePath,
        pageIndex: 0,
        url: url,
        x: 50,
        y: 100,
        width: 200,
        height: 30,
        text: text,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Link aggiunto! Salvato in: $outputPath')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e'), backgroundColor: Colors.red),
        );
      }
    }
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