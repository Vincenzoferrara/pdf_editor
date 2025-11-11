import 'package:flutter/material.dart';

class AppColors {
  // Material Design 3 base colors
  static const Color primary = Color(0xFF1976D2);
  static const Color primaryContainer = Color(0xFFE3F2FD);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFF0D47A1);
  
  static const Color secondary = Color(0xFF7B1FA2);
  static const Color secondaryContainer = Color(0xFFF3E5F5);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSecondaryContainer = Color(0xFF4A148C);
  
  // Warning colors for OCR banner
  static const Color warning = Color(0xFFFF9800);
  static const Color warningContainer = Color(0xFFFFF3E0);
  static const Color onWarning = Color(0xFF000000);
  static const Color onWarningContainer = Color(0xFFE65100);
  
  // Success colors
  static const Color success = Color(0xFF4CAF50);
  static const Color successContainer = Color(0xFFE8F5E8);
  static const Color onSuccess = Color(0xFFFFFFFF);
  static const Color onSuccessContainer = Color(0xFF1B5E20);
  
  // Error colors
  static const Color error = Color(0xFFF44336);
  static const Color errorContainer = Color(0xFFFFEBEE);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color onErrorContainer = Color(0xFFB71C1C);
  
  // Surface colors
  static const Color surface = Color(0xFFFAFAFA);
  static const Color onSurface = Color(0xFF212121);
  static const Color surfaceVariant = Color(0xFFF5F5F5);
  static const Color onSurfaceVariant = Color(0xFF757575);
  
  // Drawing colors
  static const List<Color> drawingColors = [
    Color(0xFF000000), // Black
    Color(0xFFFFFFFF), // White
    Color(0xFFFF0000), // Red
    Color(0xFF00FF00), // Green
    Color(0xFF0000FF), // Blue
    Color(0xFFFFFF00), // Yellow
    Color(0xFFFF00FF), // Magenta
    Color(0xFF00FFFF), // Cyan
    Color(0xFFA52A2A), // Brown
    Color(0xFF808080), // Gray
    Color(0xFFFFA500), // Orange
    Color(0xFF800080), // Purple
  ];
  
  // Annotation colors
  static const Color highlightYellow = Color(0xFFFFFF00);
  static const Color highlightGreen = Color(0xFF00FF00);
  static const Color highlightBlue = Color(0xFF00B0FF);
  static const Color highlightPink = Color(0xFFFF80AB);
}