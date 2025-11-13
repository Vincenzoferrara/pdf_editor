import 'package:flutter/material.dart';
import '../../presentation/providers/drawing_provider.dart';

/// Classe base per oggetti di editing sul PDF
/// Performance: usa @immutable per ottimizzazioni del compilatore
@immutable
abstract class EditingObject {
  final String id;
  final Offset position; // Coordinate relative alla pagina PDF
  final int pageNumber; // 1-based page number

  const EditingObject({
    required this.id,
    required this.position,
    required this.pageNumber,
  });

  /// Hit test efficiente per selezione oggetto
  bool hitTest(Offset point);

  /// Rendering ottimizzato su canvas
  void paint(Canvas canvas, Rect pageRect, {bool isSelected = false});

  /// Copia immutabile con modifiche
  EditingObject copyWith({Offset? position, int? pageNumber});

  /// Serializzazione JSON
  Map<String, dynamic> toJson();

  /// Bounds per selezione e hit testing
  Rect getBounds(Rect pageRect);
}

/// Oggetto disegno a mano libera ottimizzato
/// Performance: caching Paint objects, path optimization
@immutable
class DrawingObject extends EditingObject {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;
  final DrawingTool tool;

  const DrawingObject({
    required super.id,
    required super.position,
    required super.pageNumber,
    required this.points,
    required this.color,
    required this.strokeWidth,
    required this.tool,
  });

  // Cache statica per Paint riutilizzabili - evita allocazioni
  static final _paintCache = <String, Paint>{};
  static final _selectionPaint = Paint()
    ..color = Colors.blue
    ..strokeWidth = 2.0
    ..style = PaintingStyle.stroke;
  static final _handlePaint = Paint()
    ..color = Colors.blue
    ..style = PaintingStyle.fill;
  static final _handleBorderPaint = Paint()
    ..color = Colors.white
    ..strokeWidth = 2
    ..style = PaintingStyle.stroke;

  @override
  bool hitTest(Offset point) {
    // Hit test ottimizzato con early exit
    const tolerance = 10.0;
    final radiusSquared = (tolerance + strokeWidth / 2) * (tolerance + strokeWidth / 2);

    for (final p in points) {
      final dx = p.dx + position.dx - point.dx;
      final dy = p.dy + position.dy - point.dy;
      // Usa distanza al quadrato per evitare sqrt
      if (dx * dx + dy * dy <= radiusSquared) {
        return true;
      }
    }
    return false;
  }

  @override
  void paint(Canvas canvas, Rect pageRect, {bool isSelected = false}) {
    if (points.isEmpty) return;

    // Ottieni Paint da cache o crea nuovo
    final cacheKey = '${color.value}_${strokeWidth}_${tool.name}';
    final paint = _paintCache.putIfAbsent(cacheKey, () {
      final p = Paint()
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      p.color = tool == DrawingTool.highlighter
          ? color.withValues(alpha: 0.3)
          : color;

      return p;
    });

    // Disegna path ottimizzato
    if (points.length == 1) {
      // Singolo punto - disegna cerchio
      final point = Offset(
        pageRect.left + position.dx + points[0].dx,
        pageRect.top + position.dy + points[0].dy,
      );
      canvas.drawCircle(point, strokeWidth / 2, paint);
    } else {
      // Path multipunto - costruisci e disegna
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

    // Disegna decorazioni selezione
    if (isSelected) {
      _paintSelection(canvas, pageRect);
    }
  }

  /// Rendering selezione separato per chiarezza
  void _paintSelection(Canvas canvas, Rect pageRect) {
    final bounds = getBounds(pageRect);
    canvas.drawRect(bounds, _selectionPaint);

    // Handle agli angoli
    _drawHandle(canvas, bounds.topLeft);
    _drawHandle(canvas, bounds.topRight);
    _drawHandle(canvas, bounds.bottomLeft);
    _drawHandle(canvas, bounds.bottomRight);
  }

  /// Disegna handle riutilizzabile
  static void _drawHandle(Canvas canvas, Offset center) {
    canvas.drawCircle(center, 6, _handlePaint);
    canvas.drawCircle(center, 6, _handleBorderPaint);
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

    // Calcolo bounds ottimizzato
    double minX = points[0].dx;
    double maxX = points[0].dx;
    double minY = points[0].dy;
    double maxY = points[0].dy;

    for (int i = 1; i < points.length; i++) {
      final p = points[i];
      if (p.dx < minX) minX = p.dx;
      if (p.dx > maxX) maxX = p.dx;
      if (p.dy < minY) minY = p.dy;
      if (p.dy > maxY) maxY = p.dy;
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
      'color': color.value,
      'strokeWidth': strokeWidth,
      'tool': tool.name,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DrawingObject &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Oggetto testo ottimizzato
/// Performance: cache TextPainter, minimizza layout calls
@immutable
class TextObject extends EditingObject {
  final String text;
  final Color color;
  final double fontSize;
  final String fontFamily;

  const TextObject({
    required super.id,
    required super.position,
    required super.pageNumber,
    required this.text,
    required this.color,
    required this.fontSize,
    this.fontFamily = 'Roboto',
  });

  // Cache statica Paint per selezione
  static final _selectionPaint = Paint()
    ..color = Colors.blue
    ..strokeWidth = 2.0
    ..style = PaintingStyle.stroke;
  static final _handlePaint = Paint()
    ..color = Colors.blue
    ..style = PaintingStyle.fill;
  static final _handleBorderPaint = Paint()
    ..color = Colors.white
    ..strokeWidth = 2
    ..style = PaintingStyle.stroke;

  /// Crea TextPainter - usato sia per hit test che rendering
  TextPainter _createTextPainter() {
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: FontWeight.w500,
        fontFamily: fontFamily,
      ),
    );

    return TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
  }

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

  @override
  void paint(Canvas canvas, Rect pageRect, {bool isSelected = false}) {
    final textPainter = _createTextPainter();
    textPainter.layout();

    final paintPosition = Offset(
      pageRect.left + position.dx,
      pageRect.top + position.dy,
    );

    textPainter.paint(canvas, paintPosition);

    if (isSelected) {
      _paintSelection(canvas, pageRect, textPainter);
    }
  }

  /// Rendering selezione separato
  void _paintSelection(Canvas canvas, Rect pageRect, TextPainter textPainter) {
    final bounds = getBounds(pageRect);
    canvas.drawRect(bounds, _selectionPaint);

    // Handle agli angoli
    _drawHandle(canvas, bounds.topLeft);
    _drawHandle(canvas, bounds.topRight);
    _drawHandle(canvas, bounds.bottomLeft);
    _drawHandle(canvas, bounds.bottomRight);
  }

  /// Handle riutilizzabile
  static void _drawHandle(Canvas canvas, Offset center) {
    canvas.drawCircle(center, 6, _handlePaint);
    canvas.drawCircle(center, 6, _handleBorderPaint);
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
      fontFamily: fontFamily,
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
      'color': color.value,
      'fontSize': fontSize,
      'fontFamily': fontFamily,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TextObject &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
