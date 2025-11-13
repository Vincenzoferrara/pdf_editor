import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/editing_object.dart';
import '../providers/drawing_provider.dart';
import '../providers/editing_objects_provider.dart';
import 'pdf_coordinate_converter.dart';

const _uuid = Uuid();

/// Canvas per la gestione degli oggetti di editing con selezione e spostamento
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
  final _repaintNotifier = _RepaintNotifier();

  @override
  void dispose() {
    _repaintNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDrawingMode = ref.watch(drawingModeProvider);
    final selectedTool = ref.watch(selectedToolProvider);
    final editingObjects = ref.watch(editingObjectsProvider);
    final selectedObjectId = ref.watch(selectedObjectIdProvider);

    return Stack(
      children: [
        // CustomPaint per disegnare gli oggetti
        CustomPaint(
          foregroundPainter: _EditingPainter(
            controller: widget.controller,
            objects: editingObjects,
            selectedObjectId: selectedObjectId,
            ref: ref,
            repaintNotifier: _repaintNotifier,
          ),
          child: widget.child,
        ),
        // Layer gesture
        if (isDrawingMode)
          Positioned.fill(
            child: selectedTool == DrawingTool.text
                ? _TextCreationGestureLayer(
                    controller: widget.controller,
                    repaintNotifier: _repaintNotifier,
                  )
                : _DrawingCreationGestureLayer(
                    controller: widget.controller,
                    repaintNotifier: _repaintNotifier,
                  ),
          )
        else
          // Modalità selezione/spostamento
          Positioned.fill(
            child: _SelectionGestureLayer(
              controller: widget.controller,
              repaintNotifier: _repaintNotifier,
            ),
          ),
      ],
    );
  }
}

/// Notifier per forzare repaint
class _RepaintNotifier extends ChangeNotifier {
  void notify() {
    notifyListeners();
  }
}

/// Painter per disegnare gli oggetti di editing
class _EditingPainter extends CustomPainter {
  final PdfViewerController controller;
  final List<EditingObject> objects;
  final String? selectedObjectId;
  final WidgetRef ref;
  final Listenable? repaintNotifier;

  _EditingPainter({
    required this.controller,
    required this.objects,
    required this.selectedObjectId,
    required this.ref,
    this.repaintNotifier,
  }) : super(repaint: repaintNotifier);

  @override
  void paint(Canvas canvas, Size size) {
    if (!controller.isReady || controller.layout == null) return;

    final layout = controller.layout!;
    final matrix = controller.value;

    // Leggi l'oggetto corrente in creazione
    final currentObject = ref.read(currentEditingObjectProvider);

    // Disegna per ogni pagina visibile
    for (int i = 0; i < layout.pageLayouts.length; i++) {
      final pageNumber = i + 1;
      final pageRect = layout.pageLayouts[i];

      canvas.save();
      canvas.transform(matrix.storage);

      // Disegna oggetti completati per questa pagina
      for (final obj in objects.where((o) => o.pageNumber == pageNumber)) {
        final isSelected = obj.id == selectedObjectId;
        obj.paint(canvas, pageRect, isSelected: isSelected);
      }

      // Disegna oggetto corrente se è per questa pagina
      if (currentObject != null && currentObject.pageNumber == pageNumber) {
        currentObject.paint(canvas, pageRect, isSelected: false);
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _EditingPainter oldDelegate) {
    return oldDelegate.objects != objects ||
        oldDelegate.selectedObjectId != selectedObjectId;
  }

  @override
  bool shouldRebuildSemantics(covariant _EditingPainter oldDelegate) => false;
}

/// Layer per creare nuovi disegni
class _DrawingCreationGestureLayer extends ConsumerWidget {
  final PdfViewerController controller;
  final _RepaintNotifier repaintNotifier;

  const _DrawingCreationGestureLayer({
    required this.controller,
    required this.repaintNotifier,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final converter = PdfCoordinateConverter(controller);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanDown: (details) {
        if (!controller.isReady || controller.layout == null) return;

        final selectedTool = ref.read(selectedToolProvider);
        final selectedColor = ref.read(selectedColorProvider);
        final strokeWidth = ref.read(strokeWidthProvider);

        final pageInfo = converter.screenToPage(details.localPosition);
        if (pageInfo == null) return;

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
      },
      onPanUpdate: (details) {
        final currentObject = ref.read(currentEditingObjectProvider);
        if (currentObject == null || currentObject is! DrawingObject) return;
        if (!controller.isReady || controller.layout == null) return;

        final pageInfo = converter.screenToPage(details.localPosition);
        if (pageInfo == null) return;
        if (pageInfo.pageNumber != currentObject.pageNumber) return;

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
      },
      onPanEnd: (details) {
        final currentObject = ref.read(currentEditingObjectProvider);
        if (currentObject == null) {
          ref.read(isActivelyDrawingProvider.notifier).state = false;
          return;
        }

        final objects = ref.read(editingObjectsProvider);
        ref.read(editingObjectsProvider.notifier).state = [
          ...objects,
          currentObject,
        ];

        ref.read(currentEditingObjectProvider.notifier).state = null;
        ref.read(isActivelyDrawingProvider.notifier).state = false;
        repaintNotifier.notify();
      },
    );
  }
}

/// Layer per creare nuovo testo
class _TextCreationGestureLayer extends ConsumerWidget {
  final PdfViewerController controller;
  final _RepaintNotifier repaintNotifier;

  const _TextCreationGestureLayer({
    required this.controller,
    required this.repaintNotifier,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final converter = PdfCoordinateConverter(controller);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapUp: (details) async {
        if (!controller.isReady || controller.layout == null) return;

        final pageInfo = converter.screenToPage(details.localPosition);
        if (pageInfo == null) return;

        final text = await _showTextInputDialog(context);
        if (text == null || text.isEmpty) return;

        final selectedColor = ref.read(selectedColorProvider);
        final fontSize = ref.read(strokeWidthProvider) * 3;

        final textObject = TextObject(
          id: _uuid.v4(),
          position: pageInfo.pagePoint,
          pageNumber: pageInfo.pageNumber,
          text: text,
          color: selectedColor,
          fontSize: fontSize,
        );

        final objects = ref.read(editingObjectsProvider);
        ref.read(editingObjectsProvider.notifier).state = [
          ...objects,
          textObject,
        ];

        repaintNotifier.notify();
      },
    );
  }

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

/// Layer per selezionare e spostare oggetti
class _SelectionGestureLayer extends ConsumerWidget {
  final PdfViewerController controller;
  final _RepaintNotifier repaintNotifier;

  const _SelectionGestureLayer({
    required this.controller,
    required this.repaintNotifier,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final converter = PdfCoordinateConverter(controller);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapUp: (details) {
        if (!controller.isReady || controller.layout == null) return;

        final pageInfo = converter.screenToPage(details.localPosition);
        if (pageInfo == null) {
          // Deseleziona se tap fuori
          ref.read(selectedObjectIdProvider.notifier).state = null;
          repaintNotifier.notify();
          return;
        }

        final objects = ref.read(editingObjectsProvider);
        final layout = controller.layout!;
        final pageRect = layout.pageLayouts[pageInfo.pageNumber - 1];

        // Cerca oggetto toccato (dal più recente al più vecchio)
        EditingObject? tappedObject;
        for (int i = objects.length - 1; i >= 0; i--) {
          final obj = objects[i];
          if (obj.pageNumber != pageInfo.pageNumber) continue;

          if (obj.hitTest(pageInfo.pagePoint)) {
            tappedObject = obj;
            break;
          }
        }

        if (tappedObject != null) {
          final currentSelectedId = ref.read(selectedObjectIdProvider);

          if (currentSelectedId == tappedObject.id) {
            // Se già selezionato, mostra menu contestuale
            _showContextMenu(context, ref, tappedObject, repaintNotifier);
          } else {
            // Seleziona l'oggetto
            ref.read(selectedObjectIdProvider.notifier).state = tappedObject.id;
            repaintNotifier.notify();
          }
        } else {
          // Deseleziona
          ref.read(selectedObjectIdProvider.notifier).state = null;
          repaintNotifier.notify();
        }
      },
      onPanStart: (details) {
        if (!controller.isReady || controller.layout == null) return;

        final selectedId = ref.read(selectedObjectIdProvider);
        if (selectedId == null) return;

        final pageInfo = converter.screenToPage(details.localPosition);
        if (pageInfo == null) return;

        // Salva l'offset iniziale per il drag
        ref.read(dragOffsetProvider.notifier).state = pageInfo.pagePoint;
      },
      onPanUpdate: (details) {
        final selectedId = ref.read(selectedObjectIdProvider);
        if (selectedId == null) return;

        final dragStartOffset = ref.read(dragOffsetProvider);
        if (dragStartOffset == null) return;

        final pageInfo = converter.screenToPage(details.localPosition);
        if (pageInfo == null) return;

        // Calcola lo spostamento
        final delta = pageInfo.pagePoint - dragStartOffset;

        // Aggiorna la posizione dell'oggetto
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
      },
      onPanEnd: (details) {
        ref.read(dragOffsetProvider.notifier).state = null;
      },
    );
  }

  void _showContextMenu(
    BuildContext context,
    WidgetRef ref,
    EditingObject object,
    _RepaintNotifier repaintNotifier,
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
