import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Enum per gli strumenti di disegno
enum DrawingTool {
  pen,
  highlighter,
  eraser,
  text,
}

/// Provider per la modalità di disegno
final drawingModeProvider = StateProvider<bool>((ref) => false);

/// Provider per lo strumento di disegno selezionato
final selectedToolProvider = StateProvider<DrawingTool>((ref) => DrawingTool.pen);

/// Provider per il colore selezionato
final selectedColorProvider = StateProvider<Color>((ref) => Colors.black);

/// Provider per lo spessore del tratto
final strokeWidthProvider = StateProvider<double>((ref) => 3.0);