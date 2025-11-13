import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Enum per gli strumenti di disegno (senza gomma)
enum DrawingTool {
  pen,
  highlighter,
  text,
}

/// Provider per la modalità di disegno
final drawingModeProvider = StateProvider<bool>((ref) => false);

/// Provider per lo strumento di disegno selezionato
final selectedToolProvider = StateProvider<DrawingTool>((ref) => DrawingTool.pen);

/// Provider per il colore selezionato
final selectedColorProvider = StateProvider<Color>((ref) => Colors.black);

/// Provider per lo spessore del tratto (pen/highlighter)
final strokeWidthProvider = StateProvider<double>((ref) => 3.0);

/// Provider per la grandezza del font (testo)
final textFontSizeProvider = StateProvider<double>((ref) => 16.0);

/// Provider per il font family (testo)
final textFontFamilyProvider = StateProvider<String>((ref) => 'Roboto');