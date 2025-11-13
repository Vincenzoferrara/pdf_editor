import 'package:flutter/material.dart';
import '../../presentation/providers/drawing_provider.dart';

/// Classe base per tutti gli oggetti di editing sul PDF
/// Ogni oggetto ha coordinate relative alla pagina e può essere selezionato/spostato
abstract class EditingObject {
  final String id;
  final Offset position; // Coordinate relative alla pagina PDF
  final int pageNumber; // 1-based page number

  EditingObject({
    required this.id,
    required this.position,
    required this.pageNumber,
  });

  /// Verifica se un punto tocca questo oggetto
  bool hitTest(Offset point);

  /// Disegna l'oggetto sul canvas
  void paint(Canvas canvas, Rect pageRect, {bool isSelected = false});

  /// Crea una copia dell'oggetto con nuova posizione
  EditingObject copyWith({Offset? position, int? pageNumber});

  /// Converte in JSON per salvataggio
  Map<String, dynamic> toJson();

  /// Bounds dell'oggetto per selezione
  Rect getBounds(Rect pageRect);
}

/// Oggetto di disegno a mano libera (pen/highlighter)
class DrawingObject extends EditingObject {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;
  final DrawingTool tool;

  DrawingObject({
    required super.id,
    required super.position,
    required super.pageNumber,
    required this.points,
    required this.color,
    required this.strokeWidth,
    required this.tool,
  });

  @override
  bool hitTest(Offset point) {
    // Verifica se il punto è vicino a qualsiasi punto del path
    const tolerance = 10.0;
    for (final p in points) {
      final distance = (p + position - point).distance;
      if (distance < tolerance + strokeWidth / 2) {
        return true;
      }
    }
    return false;
  }

  @override
  void paint(Canvas canvas, Rect pageRect, {bool isSelected = false}) {
    if (points.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    if (tool == DrawingTool.highlighter) {
      paint.color = color.withValues(alpha: 0.3);
    }

    // Disegna il path
    if (points.length == 1) {
      final point = Offset(
        pageRect.left + position.dx + points[0].dx,
        pageRect.top + position.dy + points[0].dy,
      );
      canvas.drawCircle(point, strokeWidth / 2, paint);
    } else {
      final path = Path();
      final firstPoint = Offset(
        pageRect.left + position.dx + points[0].dx,
        pageRect.top + position.dy + points[0].dy,
      );
      path.moveTo(firstPoint.dx, firstPoint.dy);

      for (int i = 1; i < points.length; i++) {
        final point = Offset(
          pageRect.left + position.dx + points[i].dx,
          pageRect.top + position.dy + points[i].dy,
        );
        path.lineTo(point.dx, point.dy);
      }

      canvas.drawPath(path, paint);
    }

    // Se selezionato, disegna il bounding box
    if (isSelected) {
      final bounds = getBounds(pageRect);
      final selectionPaint = Paint()
        ..color = Colors.blue
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;
      canvas.drawRect(bounds, selectionPaint);

      // Disegna i handle agli angoli
      _drawHandle(canvas, bounds.topLeft);
      _drawHandle(canvas, bounds.topRight);
      _drawHandle(canvas, bounds.bottomLeft);
      _drawHandle(canvas, bounds.bottomRight);
    }
  }

  void _drawHandle(Canvas canvas, Offset center) {
    final handlePaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 6, handlePaint);

    final borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, 6, borderPaint);
  }

  @override
  Rect getBounds(Rect pageRect) {
    if (points.isEmpty) {
      return Rect.fromCenter(
        center: Offset(pageRect.left + position.dx, pageRect.top + position.dy),
        width: strokeWidth,
        height: strokeWidth,
      );
    }

    double minX = points[0].dx;
    double maxX = points[0].dx;
    double minY = points[0].dy;
    double maxY = points[0].dy;

    for (final p in points) {
      minX = minX < p.dx ? minX : p.dx;
      maxX = maxX > p.dx ? maxX : p.dx;
      minY = minY < p.dy ? minY : p.dy;
      maxY = maxY > p.dy ? maxY : p.dy;
    }

    final padding = strokeWidth / 2 + 10;
    return Rect.fromLTRB(
      pageRect.left + position.dx + minX - padding,
      pageRect.top + position.dy + minY - padding,
      pageRect.left + position.dx + maxX + padding,
      pageRect.top + position.dy + maxY + padding,
    );
  }

  @override
  DrawingObject copyWith({Offset? position, int? pageNumber}) {
    return DrawingObject(
      id: id,
      position: position ?? this.position,
      pageNumber: pageNumber ?? this.pageNumber,
      points: points,
      color: color,
      strokeWidth: strokeWidth,
      tool: tool,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': 'drawing',
      'position': {'dx': position.dx, 'dy': position.dy},
      'pageNumber': pageNumber,
      'points': points.map((p) => {'dx': p.dx, 'dy': p.dy}).toList(),
      'color': color.toARGB32(),
      'strokeWidth': strokeWidth,
      'tool': tool.toString(),
    };
  }
}

/// Oggetto di testo
class TextObject extends EditingObject {
  final String text;
  final Color color;
  final double fontSize;

  TextObject({
    required super.id,
    required super.position,
    required super.pageNumber,
    required this.text,
    required this.color,
    required this.fontSize,
  });

  @override
  bool hitTest(Offset point) {
    final textPainter = _createTextPainter();
    textPainter.layout();

    final bounds = Rect.fromLTWH(
      position.dx,
      position.dy,
      textPainter.width,
      textPainter.height,
    );

    return bounds.contains(point);
  }

  TextPainter _createTextPainter() {
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: FontWeight.w500,
      ),
    );

    return TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
  }

  @override
  void paint(Canvas canvas, Rect pageRect, {bool isSelected = false}) {
    final textPainter = _createTextPainter();
    textPainter.layout();

    final paintPosition = Offset(
      pageRect.left + position.dx,
      pageRect.top + position.dy,
    );

    textPainter.paint(canvas, paintPosition);

    // Se selezionato, disegna il bounding box
    if (isSelected) {
      final bounds = getBounds(pageRect);
      final selectionPaint = Paint()
        ..color = Colors.blue
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;
      canvas.drawRect(bounds, selectionPaint);

      // Disegna i handle agli angoli
      _drawHandle(canvas, bounds.topLeft);
      _drawHandle(canvas, bounds.topRight);
      _drawHandle(canvas, bounds.bottomLeft);
      _drawHandle(canvas, bounds.bottomRight);
    }
  }

  void _drawHandle(Canvas canvas, Offset center) {
    final handlePaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 6, handlePaint);

    final borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, 6, borderPaint);
  }

  @override
  Rect getBounds(Rect pageRect) {
    final textPainter = _createTextPainter();
    textPainter.layout();

    const padding = 8.0;
    return Rect.fromLTWH(
      pageRect.left + position.dx - padding,
      pageRect.top + position.dy - padding,
      textPainter.width + padding * 2,
      textPainter.height + padding * 2,
    );
  }

  @override
  TextObject copyWith({Offset? position, int? pageNumber}) {
    return TextObject(
      id: id,
      position: position ?? this.position,
      pageNumber: pageNumber ?? this.pageNumber,
      text: text,
      color: color,
      fontSize: fontSize,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': 'text',
      'position': {'dx': position.dx, 'dy': position.dy},
      'pageNumber': pageNumber,
      'text': text,
      'color': color.toARGB32(),
      'fontSize': fontSize,
    };
  }
}
