import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/editing_object.dart';
import '../providers/drawing_provider.dart';
import '../providers/editing_objects_provider.dart';
import 'pdf_coordinate_converter.dart';

const _uuid = Uuid();

/// Canvas ottimizzato per editing PDF con selezione e spostamento oggetti
/// Performance: usa RepaintBoundary e minimizza i rebuild
class EditingCanvas extends ConsumerStatefulWidget {
  final Widget child;
  final PdfViewerController controller;

  const EditingCanvas({
    super.key,
    required this.child,
    required this.controller,
  });

  @override
  ConsumerState<EditingCanvas> createState() => _EditingCanvasState();
}

class _EditingCanvasState extends ConsumerState<EditingCanvas> {
  // Notifier singolo per tutti i repaint - riduce overhead
  final _repaintNotifier = _RepaintNotifier();

  // Cache del converter per evitare ricreazioni
  late final PdfCoordinateConverter _converter;

  @override
  void initState() {
    super.initState();
    _converter = PdfCoordinateConverter(widget.controller);
  }

  @override
  void dispose() {
    _repaintNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDrawingMode = ref.watch(drawingModeProvider);
    final selectedTool = ref.watch(selectedToolProvider);

    // Solo i dati necessari per il painter - evita rebuild inutili
    final editingObjects = ref.watch(editingObjectsProvider);
    final selectedObjectId = ref.watch(selectedObjectIdProvider);

    return Stack(
      children: [
        // RepaintBoundary per isolare i repaint del canvas dal resto dell'UI
        RepaintBoundary(
          child: CustomPaint(
            foregroundPainter: _EditingPainter(
              controller: widget.controller,
              objects: editingObjects,
              selectedObjectId: selectedObjectId,
              ref: ref,
              repaintNotifier: _repaintNotifier,
            ),
            child: widget.child,
          ),
        ),
        // Layer gesture - costruito condizionalmente per efficienza
        if (isDrawingMode)
          Positioned.fill(
            child: selectedTool == DrawingTool.text
                ? _TextCreationGestureLayer(
                    converter: _converter,
                    repaintNotifier: _repaintNotifier,
                  )
                : _DrawingCreationGestureLayer(
                    converter: _converter,
                    repaintNotifier: _repaintNotifier,
                  ),
          )
        else
          Positioned.fill(
            child: _SelectionGestureLayer(
              converter: _converter,
              repaintNotifier: _repaintNotifier,
            ),
          ),
      ],
    );
  }
}

/// Notifier leggero per repaint - usa solo notifyListeners
class _RepaintNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

/// Painter ottimizzato per disegnare oggetti editing
/// Performance: caching, early returns, minimizza allocazioni
class _EditingPainter extends CustomPainter {
  final PdfViewerController controller;
  final List<EditingObject> objects;
  final String? selectedObjectId;
  final WidgetRef ref;
  final Listenable? repaintNotifier;

  // Cache per Paint riutilizzabili
  static final _selectionPaint = Paint()
    ..color = Colors.blue
    ..strokeWidth = 2.0
    ..style = PaintingStyle.stroke;

  _EditingPainter({
    required this.controller,
    required this.objects,
    required this.selectedObjectId,
    required this.ref,
    this.repaintNotifier,
  }) : super(repaint: repaintNotifier);

  @override
  void paint(Canvas canvas, Size size) {
    // Early return se controller non pronto - evita calcoli inutili
    if (!controller.isReady || controller.layout == null) return;

    final layout = controller.layout!;
    final matrix = controller.value;

    // Leggi oggetto corrente solo una volta
    final currentObject = ref.read(currentEditingObjectProvider);

    // Itera solo pagine visibili (ottimizzazione viewport)
    final pageLayouts = layout.pageLayouts;
    for (int i = 0; i < pageLayouts.length; i++) {
      final pageNumber = i + 1;
      final pageRect = pageLayouts[i];

      // Salva stato canvas
      canvas.save();
      canvas.transform(matrix.storage);

      // Filtra oggetti per pagina - evita iterazioni inutili
      for (final obj in objects) {
        if (obj.pageNumber != pageNumber) continue;

        final isSelected = obj.id == selectedObjectId;
        obj.paint(canvas, pageRect, isSelected: isSelected);
      }

      // Disegna oggetto in creazione se applicabile
      if (currentObject != null && currentObject.pageNumber == pageNumber) {
        currentObject.paint(canvas, pageRect, isSelected: false);
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _EditingPainter oldDelegate) {
    // Repaint solo se dati cambiati - non su ogni frame
    final currentObject = ref.read(currentEditingObjectProvider);
    final oldCurrentObject = oldDelegate.ref.read(currentEditingObjectProvider);

    return oldDelegate.objects != objects ||
        oldDelegate.selectedObjectId != selectedObjectId ||
        currentObject != oldCurrentObject;
  }

  @override
  bool shouldRebuildSemantics(covariant _EditingPainter oldDelegate) => false;
}

/// Layer ottimizzato per creazione disegni
/// Performance: usa converter cached, minimizza allocazioni
class _DrawingCreationGestureLayer extends ConsumerWidget {
  final PdfCoordinateConverter converter;
  final _RepaintNotifier repaintNotifier;

  const _DrawingCreationGestureLayer({
    required this.converter,
    required this.repaintNotifier,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanDown: (details) => _handlePanDown(details, ref),
      onPanUpdate: (details) => _handlePanUpdate(details, ref),
      onPanEnd: (details) => _handlePanEnd(ref),
    );
  }

  void _handlePanDown(DragDownDetails details, WidgetRef ref) {
    final pageInfo = converter.screenToPage(details.localPosition);
    if (pageInfo == null) return;

    // Leggi provider solo quando necessario
    final selectedTool = ref.read(selectedToolProvider);
    final selectedColor = ref.read(selectedColorProvider);
    final strokeWidth = ref.read(strokeWidthProvider);

    // Crea nuovo oggetto
    final newObject = DrawingObject(
      id: _uuid.v4(),
      position: Offset.zero,
      pageNumber: pageInfo.pageNumber,
      points: [pageInfo.pagePoint],
      color: selectedColor,
      strokeWidth: strokeWidth,
      tool: selectedTool,
    );

    ref.read(currentEditingObjectProvider.notifier).state = newObject;
    ref.read(isActivelyDrawingProvider.notifier).state = true;
    repaintNotifier.notify();
  }

  void _handlePanUpdate(DragUpdateDetails details, WidgetRef ref) {
    final currentObject = ref.read(currentEditingObjectProvider);
    if (currentObject == null || currentObject is! DrawingObject) return;

    final pageInfo = converter.screenToPage(details.localPosition);
    if (pageInfo == null || pageInfo.pageNumber != currentObject.pageNumber) {
      return;
    }

    // Ottimizzazione: riusa tutto tranne points
    final updatedObject = DrawingObject(
      id: currentObject.id,
      position: currentObject.position,
      pageNumber: currentObject.pageNumber,
      points: [...currentObject.points, pageInfo.pagePoint],
      color: currentObject.color,
      strokeWidth: currentObject.strokeWidth,
      tool: currentObject.tool,
    );

    ref.read(currentEditingObjectProvider.notifier).state = updatedObject;
    repaintNotifier.notify();
  }

  void _handlePanEnd(WidgetRef ref) {
    final currentObject = ref.read(currentEditingObjectProvider);
    if (currentObject == null) {
      ref.read(isActivelyDrawingProvider.notifier).state = false;
      return;
    }

    // Aggiungi a lista finale
    final objects = ref.read(editingObjectsProvider);
    ref.read(editingObjectsProvider.notifier).state = [
      ...objects,
      currentObject,
    ];

    // Cleanup
    ref.read(currentEditingObjectProvider.notifier).state = null;
    ref.read(isActivelyDrawingProvider.notifier).state = false;
    repaintNotifier.notify();
  }
}

/// Layer per creazione testo - dialog ottimizzato
class _TextCreationGestureLayer extends ConsumerWidget {
  final PdfCoordinateConverter converter;
  final _RepaintNotifier repaintNotifier;

  const _TextCreationGestureLayer({
    required this.converter,
    required this.repaintNotifier,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapUp: (details) async => _handleTapUp(details, context, ref),
    );
  }

  Future<void> _handleTapUp(
    TapUpDetails details,
    BuildContext context,
    WidgetRef ref,
  ) async {
    final pageInfo = converter.screenToPage(details.localPosition);
    if (pageInfo == null) return;

    final text = await _showTextInputDialog(context);
    if (text == null || text.isEmpty) return;

    // Usa provider dedicati per il testo
    final selectedColor = ref.read(selectedColorProvider);
    final fontSize = ref.read(textFontSizeProvider);
    final fontFamily = ref.read(textFontFamilyProvider);

    final textObject = TextObject(
      id: _uuid.v4(),
      position: pageInfo.pagePoint,
      pageNumber: pageInfo.pageNumber,
      text: text,
      color: selectedColor,
      fontSize: fontSize,
      fontFamily: fontFamily,
    );

    // Aggiungi a lista
    final objects = ref.read(editingObjectsProvider);
    ref.read(editingObjectsProvider.notifier).state = [...objects, textObject];
    repaintNotifier.notify();
  }

  /// Dialog semplificato per input testo
  Future<String?> _showTextInputDialog(BuildContext context) async {
    String? text;
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Inserisci testo'),
        content: TextField(
          autofocus: true,
          maxLines: null,
          decoration: const InputDecoration(
            hintText: 'Scrivi qui...',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => text = value,
          onSubmitted: (value) {
            text = value;
            Navigator.of(dialogContext).pop(text);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(text),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

/// Layer ottimizzato per selezione e spostamento
/// Performance: hit test efficiente, batch updates
class _SelectionGestureLayer extends ConsumerWidget {
  final PdfCoordinateConverter converter;
  final _RepaintNotifier repaintNotifier;

  const _SelectionGestureLayer({
    required this.converter,
    required this.repaintNotifier,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapUp: (details) => _handleTapUp(details, context, ref),
      onPanStart: (details) => _handlePanStart(details, ref),
      onPanUpdate: (details) => _handlePanUpdate(details, ref),
      onPanEnd: (details) => _handlePanEnd(ref),
    );
  }

  void _handleTapUp(TapUpDetails details, BuildContext context, WidgetRef ref) {
    final pageInfo = converter.screenToPage(details.localPosition);

    // Deseleziona se tap fuori pagina
    if (pageInfo == null) {
      ref.read(selectedObjectIdProvider.notifier).state = null;
      repaintNotifier.notify();
      return;
    }

    final objects = ref.read(editingObjectsProvider);

    // Hit test ottimizzato: cerca dal più recente al più vecchio
    EditingObject? tappedObject;
    for (int i = objects.length - 1; i >= 0; i--) {
      final obj = objects[i];
      if (obj.pageNumber != pageInfo.pageNumber) continue;

      if (obj.hitTest(pageInfo.pagePoint)) {
        tappedObject = obj;
        break; // Early exit
      }
    }

    if (tappedObject != null) {
      final currentSelectedId = ref.read(selectedObjectIdProvider);

      if (currentSelectedId == tappedObject.id) {
        // Già selezionato -> deseleziona e mostra menu
        _showContextMenu(context, ref, tappedObject);
      } else {
        // Seleziona nuovo oggetto
        ref.read(selectedObjectIdProvider.notifier).state = tappedObject.id;
        repaintNotifier.notify();
      }
    } else {
      // Deseleziona
      ref.read(selectedObjectIdProvider.notifier).state = null;
      repaintNotifier.notify();
    }
  }

  void _handlePanStart(DragStartDetails details, WidgetRef ref) {
    final selectedId = ref.read(selectedObjectIdProvider);
    if (selectedId == null) return;

    final pageInfo = converter.screenToPage(details.localPosition);
    if (pageInfo == null) return;

    // Salva offset iniziale per drag
    ref.read(dragOffsetProvider.notifier).state = pageInfo.pagePoint;
  }

  void _handlePanUpdate(DragUpdateDetails details, WidgetRef ref) {
    final selectedId = ref.read(selectedObjectIdProvider);
    if (selectedId == null) return;

    final dragStartOffset = ref.read(dragOffsetProvider);
    if (dragStartOffset == null) return;

    final pageInfo = converter.screenToPage(details.localPosition);
    if (pageInfo == null) return;

    // Calcola delta
    final delta = pageInfo.pagePoint - dragStartOffset;

    // Aggiorna posizione oggetto selezionato
    final objects = ref.read(editingObjectsProvider);
    final updatedObjects = objects.map((obj) {
      if (obj.id == selectedId && obj.pageNumber == pageInfo.pageNumber) {
        return obj.copyWith(position: obj.position + delta);
      }
      return obj;
    }).toList();

    ref.read(editingObjectsProvider.notifier).state = updatedObjects;
    ref.read(dragOffsetProvider.notifier).state = pageInfo.pagePoint;
    repaintNotifier.notify();
  }

  void _handlePanEnd(WidgetRef ref) {
    ref.read(dragOffsetProvider.notifier).state = null;
  }

  /// Menu contestuale ottimizzato
  void _showContextMenu(
    BuildContext context,
    WidgetRef ref,
    EditingObject object,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Azioni'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Elimina'),
              onTap: () {
                final objects = ref.read(editingObjectsProvider);
                ref.read(editingObjectsProvider.notifier).state =
                    objects.where((obj) => obj.id != object.id).toList();
                ref.read(selectedObjectIdProvider.notifier).state = null;
                repaintNotifier.notify();
                Navigator.of(dialogContext).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel),
              title: const Text('Deseleziona'),
              onTap: () {
                ref.read(selectedObjectIdProvider.notifier).state = null;
                repaintNotifier.notify();
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}
