class AppConstants {
  static const String appName = 'Editor PDF';
  static const String appVersion = '1.0.0';
  
  // Storage paths
  static const String documentsFolder = 'documents';
  static const String tempFolder = 'temp';
  static const String annotationsFolder = 'annotations';
  
  // File types
  static const List<String> supportedPdfTypes = ['pdf'];
  static const List<String> supportedImageTypes = ['jpg', 'jpeg', 'png', 'bmp'];
  
  // OCR settings
  static const int ocrMinConfidence = 70;
  static const int maxImageSize = 2000;
  
  // Drawing settings
  static const double defaultStrokeWidth = 2.0;
  static const double maxStrokeWidth = 20.0;
  static const double minStrokeWidth = 0.5;
  
  // Animation durations
  static const int defaultAnimationDuration = 300;
  static const int fastAnimationDuration = 150;
  static const int slowAnimationDuration = 600;
  
  // PDF viewer settings
  static const double minZoom = 0.5;
  static const double maxZoom = 5.0;
  static const double defaultZoom = 1.0;
}