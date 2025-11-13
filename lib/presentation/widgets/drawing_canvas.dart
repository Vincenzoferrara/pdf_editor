import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';
import 'pdf_coordinate_converter.dart';
import '../providers/drawing_provider.dart';

/// Provider per gestire i tratti di disegno
/// Ora ogni stroke ha anche il numero di pagina
final drawingStrokesProvider = StateProvider<List<DrawingStroke>>((ref) => []);
final currentStrokeProvider = StateProvider<DrawingStroke?>((ref) => null);

/// Modello per un'annotazione di testo
class TextAnnotation {
  final Offset position; // Coordinate relative alla pagina PDF
  final String text;
  final Color color;
  final double fontSize;
  final int pageNumber; // 1-based page number

  TextAnnotation({
    required this.position,
    required this.text,
    required this.color,
    required this.fontSize,
    required this.pageNumber,
  });
}

/// Provider per le annotazioni di testo
final textAnnotationsProvider = StateProvider<List<TextAnnotation>>((ref) => []);

/// Modello per un singolo tratto di disegno (coordinate PDF page-relative)
class DrawingStroke {
  final List<Offset> points; // Coordinate relative alla pagina PDF
  final Color color;
  final double strokeWidth;
  final DrawingTool tool;
  final int pageNumber; // 1-based page number

  DrawingStroke({
    required this.points,
    required this.color,
    required this.strokeWidth,
    required this.tool,
    required this.pageNumber,
  });

  DrawingStroke copyWith({
    List<Offset>? points,
    Color? color,
    double? strokeWidth,
    DrawingTool? tool,
    int? pageNumber,
  }) {
    return DrawingStroke(
      points: points ?? this.points,
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      tool: tool ?? this.tool,
      pageNumber: pageNumber ?? this.pageNumber,
    );
  }
  
  /// Converte il tratto in JSON per salvataggio
  Map<String, dynamic> toJson() {
    return {
      'points': points.map((p) => {'dx': p.dx, 'dy': p.dy}).toList(),
      'color': color.toARGB32(),
      'strokeWidth': strokeWidth,
      'tool': tool.toString(),
      'pageNumber': pageNumber,
    };
  }
}

/// Provider per tracking se si sta attivamente disegnando
final isActivelyDrawingProvider = StateProvider<bool>((ref) => false);

/// Paint callback per disegnare annotazioni sulle pagine PDF
/// Viene chiamato da pdfrx per ogni pagina visibile
void paintAnnotationsCallback(
  Canvas canvas,
  Rect pageRect,
  PdfPage page,
  List<DrawingStroke> allStrokes,
  DrawingStroke? currentStroke,
  List<TextAnnotation> textAnnotations,
) {
  // Filtra solo i tratti di questa pagina
  final pageStrokes = allStrokes.where((s) => s.pageNumber == page.pageNumber).toList();

  // Aggiungi stroke corrente se è per questa pagina
  if (currentStroke != null && currentStroke.pageNumber == page.pageNumber) {
    pageStrokes.add(currentStroke);
  }

  // Disegna tutti i tratti
  for (final stroke in pageStrokes) {
    _drawStrokeOnPage(canvas, stroke);
  }

  // Disegna le annotazioni di testo
  final pageTextAnnotations = textAnnotations.where((t) => t.pageNumber == page.pageNumber);
  for (final textAnnotation in pageTextAnnotations) {
    _drawTextAnnotation(canvas, textAnnotation);
  }
}

/// Disegna un'annotazione di testo sul canvas
void _drawTextAnnotation(Canvas canvas, TextAnnotation annotation) {
  final textSpan = TextSpan(
    text: annotation.text,
    style: TextStyle(
      color: annotation.color,
      fontSize: annotation.fontSize,
      fontWeight: FontWeight.w500,
    ),
  );

  final textPainter = TextPainter(
    text: textSpan,
    textDirection: TextDirection.ltr,
  );

  textPainter.layout();
  textPainter.paint(canvas, annotation.position);
}

/// Disegna un singolo tratto sul canvas
void _drawStrokeOnPage(Canvas canvas, DrawingStroke stroke) {
  if (stroke.points.isEmpty) return;

  final paint = Paint()
    ..color = stroke.color
    ..strokeWidth = stroke.strokeWidth
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..style = PaintingStyle.stroke;

  // Per evidenziatore usa alpha ridotto
  if (stroke.tool == DrawingTool.highlighter) {
    paint.color = stroke.color.withValues(alpha: 0.3);
  }

  // Disegna linea che connette tutti i punti
  if (stroke.points.length == 1) {
    // Singolo punto - disegna un cerchio
    canvas.drawCircle(stroke.points[0], stroke.strokeWidth / 2, paint);
  } else {
    // Multipli punti - disegna path
    final path = Path();
    path.moveTo(stroke.points[0].dx, stroke.points[0].dy);

    for (int i = 1; i < stroke.points.length; i++) {
      path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
    }

    canvas.drawPath(path, paint);
  }
}

/// DEPRECATO - Non più usato, sostituito da DrawingGestureLayer
/// Mantenerlo per compatibilità temporanea
class DrawingCanvas extends StatelessWidget {
  final Widget child;

  const DrawingCanvas({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

/// Painter per disegnare i tratti sul canvas
class DrawingPainter extends CustomPainter {
  final List<DrawingStroke> strokes;
  final DrawingStroke? currentStroke;

  DrawingPainter({
    required this.strokes,
    this.currentStroke,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Disegna tutti i tratti completati
    for (final stroke in strokes) {
      _drawStroke(canvas, stroke);
    }

    // Disegna il tratto corrente (in progress)
    if (currentStroke != null) {
      _drawStroke(canvas, currentStroke!);
    }
  }

  void _drawStroke(Canvas canvas, DrawingStroke stroke) {
    if (stroke.points.isEmpty) return;

    final paint = Paint()
      ..color = stroke.color
      ..strokeWidth = stroke.strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // Per evidenziatore usa alpha ridotto
    if (stroke.tool == DrawingTool.highlighter) {
      paint.color = stroke.color.withValues(alpha: 0.3);
    }

    // Disegna linea che connette tutti i punti
    if (stroke.points.length == 1) {
      // Singolo punto - disegna un cerchio
      canvas.drawCircle(stroke.points[0], stroke.strokeWidth / 2, paint);
    } else {
      // Multipli punti - disegna path
      final path = Path();
      path.moveTo(stroke.points[0].dx, stroke.points[0].dy);

      for (int i = 1; i < stroke.points.length; i++) {
        path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant DrawingPainter oldDelegate) {
    return oldDelegate.strokes != strokes ||
        oldDelegate.currentStroke != currentStroke;
  }
}


/// Canvas che gestisce il disegno sopra il PDF con coordinate relative alle pagine
/// Usa CustomPaint per disegnare annotazioni SOPRA il PDF senza causare rebuild
class SimpleDrawingCanvas extends ConsumerStatefulWidget {
  final Widget child;
  final PdfViewerController controller;

  const SimpleDrawingCanvas({
    super.key,
    required this.child,
    required this.controller,
  });

  @override
  ConsumerState<SimpleDrawingCanvas> createState() => _SimpleDrawingCanvasState();
}

class _SimpleDrawingCanvasState extends ConsumerState<SimpleDrawingCanvas> {
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

    // Watch SOLO completed annotations - NON currentStroke per evitare rebuild durante disegno
    final allStrokes = ref.watch(drawingStrokesProvider);
    final textAnnotations = ref.watch(textAnnotationsProvider);

    return Stack(
      children: [
        // CustomPaint wraps the PDF and paints annotations on top
        CustomPaint(
          foregroundPainter: _AnnotationsPainter(
            controller: widget.controller,
            allStrokes: allStrokes,
            textAnnotations: textAnnotations,
            ref: ref,
            repaintNotifier: _repaintNotifier,
          ),
          child: widget.child,
        ),
        // Layer gesture SOLO in editing mode
        if (isDrawingMode)
          Positioned.fill(
            child: selectedTool == DrawingTool.text
                ? _TextInputGestureLayer(controller: widget.controller)
                : _DrawingGestureLayer(
                    controller: widget.controller,
                    repaintNotifier: _repaintNotifier,
                  ),
          ),
      ],
    );
  }
}

/// Notifier personalizzato per forzare repaint senza rebuild
class _RepaintNotifier extends ChangeNotifier {
  void notify() {
    notifyListeners();
  }
}

/// Painter che disegna le annotazioni sopra il PDF
class _AnnotationsPainter extends CustomPainter {
  final PdfViewerController controller;
  final List<DrawingStroke> allStrokes;
  final List<TextAnnotation> textAnnotations;
  final WidgetRef ref;
  final Listenable? repaintNotifier;

  _AnnotationsPainter({
    required this.controller,
    required this.allStrokes,
    required this.textAnnotations,
    required this.ref,
    this.repaintNotifier,
  }) : super(repaint: repaintNotifier);

  @override
  void paint(Canvas canvas, Size size) {
    if (!controller.isReady || controller.layout == null) return;

    final layout = controller.layout!;
    final matrix = controller.value;

    // Leggi currentStroke FRESCO senza causare rebuild del widget
    final currentStroke = ref.read(currentStrokeProvider);

    // Disegna per ogni pagina visibile
    for (int i = 0; i < layout.pageLayouts.length; i++) {
      final pageNumber = i + 1;
      final pageRect = layout.pageLayouts[i];

      // Trasforma il canvas per questa pagina
      canvas.save();
      canvas.transform(matrix.storage);

      // Disegna stroke per questa pagina
      for (final stroke in allStrokes.where((s) => s.pageNumber == pageNumber)) {
        _drawStrokeForPage(canvas, stroke, pageRect);
      }

      // Disegna stroke corrente se è per questa pagina
      final stroke = currentStroke;
      if (stroke != null && stroke.pageNumber == pageNumber) {
        _drawStrokeForPage(canvas, stroke, pageRect);
      }

      // Disegna testo per questa pagina
      for (final textAnn in textAnnotations.where((t) => t.pageNumber == pageNumber)) {
        _drawTextForPage(canvas, textAnn, pageRect);
      }

      canvas.restore();
    }
  }

  void _drawStrokeForPage(Canvas canvas, DrawingStroke stroke, Rect pageRect) {
    if (stroke.points.isEmpty) return;

    final paint = Paint()
      ..color = stroke.color
      ..strokeWidth = stroke.strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    if (stroke.tool == DrawingTool.highlighter) {
      paint.color = stroke.color.withValues(alpha: 0.3);
    }

    if (stroke.points.length == 1) {
      final point = Offset(
        pageRect.left + stroke.points[0].dx,
        pageRect.top + stroke.points[0].dy,
      );
      canvas.drawCircle(point, stroke.strokeWidth / 2, paint);
    } else {
      final path = Path();
      final firstPoint = Offset(
        pageRect.left + stroke.points[0].dx,
        pageRect.top + stroke.points[0].dy,
      );
      path.moveTo(firstPoint.dx, firstPoint.dy);

      for (int i = 1; i < stroke.points.length; i++) {
        final point = Offset(
          pageRect.left + stroke.points[i].dx,
          pageRect.top + stroke.points[i].dy,
        );
        path.lineTo(point.dx, point.dy);
      }

      canvas.drawPath(path, paint);
    }
  }

  void _drawTextForPage(Canvas canvas, TextAnnotation annotation, Rect pageRect) {
    final textSpan = TextSpan(
      text: annotation.text,
      style: TextStyle(
        color: annotation.color,
        fontSize: annotation.fontSize,
        fontWeight: FontWeight.w500,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    final position = Offset(
      pageRect.left + annotation.position.dx,
      pageRect.top + annotation.position.dy,
    );

    textPainter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(covariant _AnnotationsPainter oldDelegate) {
    // Repaint SOLO quando cambiano stroke completati o testo
    // NON per currentStroke - quello viene letto fresco ad ogni paint
    return oldDelegate.allStrokes != allStrokes ||
        oldDelegate.textAnnotations != textAnnotations;
  }

  @override
  bool shouldRebuildSemantics(covariant _AnnotationsPainter oldDelegate) => false;
}

/// Layer per gestire l'inserimento di testo
class _TextInputGestureLayer extends ConsumerWidget {
  final PdfViewerController controller;

  const _TextInputGestureLayer({required this.controller});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final converter = PdfCoordinateConverter(controller);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapUp: (details) async {
        if (!controller.isReady || controller.layout == null) return;

        // Converti coordinate usando il converter modulare
        final pageInfo = converter.screenToPage(details.localPosition);
        if (pageInfo == null) return;

        // Mostra dialogo per inserire testo
        final text = await _showTextInputDialog(context);
        if (text == null || text.isEmpty) return;

        final selectedColor = ref.read(selectedColorProvider);
        final fontSize = ref.read(strokeWidthProvider) * 3; // Usa strokeWidth come fontSize

        final textAnnotation = TextAnnotation(
          position: pageInfo.pagePoint,
          text: text,
          color: selectedColor,
          fontSize: fontSize,
          pageNumber: pageInfo.pageNumber,
        );

        final annotations = ref.read(textAnnotationsProvider);
        ref.read(textAnnotationsProvider.notifier).state = [
          ...annotations,
          textAnnotation,
        ];
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

/// Layer separato per gestire i gesture di disegno
class _DrawingGestureLayer extends ConsumerWidget {
  final PdfViewerController controller;
  final _RepaintNotifier repaintNotifier;

  const _DrawingGestureLayer({
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

        // Converti coordinate usando il converter modulare
        final pageInfo = converter.screenToPage(details.localPosition);
        if (pageInfo == null) return;

        final newStroke = DrawingStroke(
          points: [pageInfo.pagePoint],
          color: selectedColor,
          strokeWidth: strokeWidth,
          tool: selectedTool,
          pageNumber: pageInfo.pageNumber,
        );

        ref.read(currentStrokeProvider.notifier).state = newStroke;
        ref.read(isActivelyDrawingProvider.notifier).state = true;

        // Notifica repaint
        repaintNotifier.notify();
      },
      onPanUpdate: (details) {
        final currentStroke = ref.read(currentStrokeProvider);
        if (currentStroke == null) return;
        if (!controller.isReady || controller.layout == null) return;

        // Converti coordinate usando il converter modulare
        final pageInfo = converter.screenToPage(details.localPosition);
        if (pageInfo == null) return;

        // Se l'utente ha cambiato pagina durante il disegno, ignora
        if (pageInfo.pageNumber != currentStroke.pageNumber) return;

        final updatedStroke = currentStroke.copyWith(
          points: [...currentStroke.points, pageInfo.pagePoint],
        );

        ref.read(currentStrokeProvider.notifier).state = updatedStroke;

        // Notifica repaint per mostrare il nuovo punto
        repaintNotifier.notify();
      },
      onPanEnd: (details) {
        final currentStroke = ref.read(currentStrokeProvider);
        if (currentStroke == null) {
          ref.read(isActivelyDrawingProvider.notifier).state = false;
          return;
        }

        final strokes = ref.read(drawingStrokesProvider);
        ref.read(drawingStrokesProvider.notifier).state = [
          ...strokes,
          currentStroke,
        ];

        ref.read(currentStrokeProvider.notifier).state = null;
        ref.read(isActivelyDrawingProvider.notifier).state = false;

        // Notifica repaint finale
        repaintNotifier.notify();
      },
    );
  }
}
