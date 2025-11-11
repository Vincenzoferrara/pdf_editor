import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

class FileUtils {
  static bool isPdfFile(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    return extension == '.pdf';
  }
  
  static bool isImageFile(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    return ['.jpg', '.jpeg', '.png', '.bmp'].contains(extension);
  }
  
  static String getFileName(String filePath) {
    return path.basenameWithoutExtension(filePath);
  }
  
  static String getFileExtension(String filePath) {
    return path.extension(filePath).toLowerCase();
  }
  
  static Future<int> getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.length();
      }
    } catch (e) {
      // Handle error
    }
    return 0;
  }
  
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
  
  static Future<bool> isPasswordProtected(String filePath) async {
    try {
      // For now, assume PDFs are not password protected
      // Syncfusion will handle password protection in the viewer
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      // If we can't access to PDF, it might be password protected
      debugPrint('Password protection check failed: $e');
      return true; // Assume password protected if we can't open it
    }
  }
  
  static Future<bool> hasSearchableText(String filePath) async {
    try {
      // For now, assume PDFs have searchable text
      // This would need OCR implementation for accurate detection
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      debugPrint('Searchable text check failed: $e');
      return false; // Assume no searchable text for unsupported platforms
    }
  }
}