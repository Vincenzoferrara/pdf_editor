import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

/// Classe dedicata per convertire coordinate schermo <-> PDF pagina
/// Gestisce la trasformazione tra lo spazio dello schermo e lo spazio delle pagine PDF
class PdfCoordinateConverter {
  final PdfViewerController controller;

  PdfCoordinateConverter(this.controller);

  /// Converti coordinate schermo in coordinate relative alla pagina PDF
  /// Restituisce null se il punto non è su nessuna pagina
  PageCoordinateInfo? screenToPage(Offset screenPoint) {
    final layout = controller.layout;
    if (!controller.isReady || layout == null) return null;

    // Ottieni la matrice di trasformazione del viewer (zoom e pan)
    final matrix = controller.value;

    // Converti il punto schermo in coordinate documento (senza trasformazioni)
    final invertedMatrix = Matrix4.inverted(matrix);
    final documentPoint = MatrixUtils.transformPoint(invertedMatrix, screenPoint);

    // Ottieni i rettangoli delle pagine dal layout
    final pageLayouts = layout.pageLayouts;

    // Trova quale pagina contiene il punto
    for (int i = 0; i < pageLayouts.length; i++) {
      final pageRect = pageLayouts[i];

      if (pageRect.contains(documentPoint)) {
        // Converti coordinate da document space a page space
        final pageX = documentPoint.dx - pageRect.left;
        final pageY = documentPoint.dy - pageRect.top;

        return PageCoordinateInfo(
          pageNumber: i + 1, // pageNumber è 1-based
          pagePoint: Offset(pageX, pageY),
          pageRect: pageRect,
        );
      }
    }

    return null;
  }

  /// Converti coordinate pagina PDF in coordinate schermo
  Offset? pageToScreen(int pageNumber, Offset pagePoint) {
    final layout = controller.layout;
    if (!controller.isReady || layout == null) return null;

    final pageLayouts = layout.pageLayouts;
    if (pageNumber < 1 || pageNumber > pageLayouts.length) return null;

    final pageRect = pageLayouts[pageNumber - 1];

    // Converti da page space a document space
    final documentPoint = Offset(
      pageRect.left + pagePoint.dx,
      pageRect.top + pagePoint.dy,
    );

    // Applica la trasformazione del viewer
    final matrix = controller.value;
    return MatrixUtils.transformPoint(matrix, documentPoint);
  }
}

/// Info per coordinate convertite
class PageCoordinateInfo {
  final int pageNumber;
  final Offset pagePoint;
  final Rect pageRect;

  PageCoordinateInfo({
    required this.pageNumber,
    required this.pagePoint,
    required this.pageRect,
  });
}
