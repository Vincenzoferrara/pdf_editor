import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:printing/printing.dart';
import '../models/pdf_document.dart';
import '../../core/utils/file_utils.dart';

class PdfService {
  static Future<PdfDocument> loadPdfDocument(String filePath) async {
    try {
      final file = File(filePath);
      final stat = await file.stat();
      final fileSize = stat.size;
      final lastModified = stat.modified;
      final fileName = FileUtils.getFileName(filePath);
      
      // Check if password protected
      final isPasswordProtected = await FileUtils.isPasswordProtected(filePath);
      
      // Check if has searchable text
      final hasSearchableText = await FileUtils.hasSearchableText(filePath);
      
      // Get page count
      int pageCount = 1; // Default fallback
      try {
        // Use a simple file read approach for page count estimation
        // Syncfusion will be used in the viewer itself
        final file = File(filePath);
        final fileSize = await file.length();
        
        // Rough estimation: ~3KB per page average
        pageCount = (fileSize / (3 * 1024)).ceil();
        if (pageCount < 1) pageCount = 1;
        if (pageCount > 1000) pageCount = 1000; // Reasonable limit
      } catch (e) {
        // Handle password protected, corrupted PDFs, or unsupported platforms
        debugPrint('PDF page count detection failed: $e');
        pageCount = 1; // Default fallback
      }
      
      return PdfDocument(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: fileName,
        filePath: filePath,
        fileSize: fileSize,
        lastModified: lastModified,
        isPasswordProtected: isPasswordProtected,
        hasSearchableText: hasSearchableText,
        pageCount: pageCount,
      );
    } catch (e) {
      throw Exception('Failed to load PDF document: $e');
    }
  }
  
  static Future<PdfDocument> openPasswordProtectedPdf(
    String filePath, 
    String password
  ) async {
    try {
      // For password protected PDFs, we'll estimate page count from file size
      // Syncfusion will handle the actual password in the viewer
      final file = File(filePath);
      final stat = await file.stat();
      final fileSize = stat.size;
      final lastModified = stat.modified;
      final fileName = FileUtils.getFileName(filePath);
      
      // Rough estimation: ~3KB per page average
      final pageCount = (fileSize / (3 * 1024)).ceil();
      
      return PdfDocument(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: fileName,
        filePath: filePath,
        fileSize: fileSize,
        lastModified: lastModified,
        isPasswordProtected: true,
        hasSearchableText: true, // Assume it has text if we can open it
        pageCount: pageCount,
      );
    } catch (e) {
      throw Exception('Failed to open password protected PDF: $e');
    }
  }
  
  static Future<Uint8List> getPdfPageAsImage(
    String filePath, 
    int pageNumber, {
    String? password,
  }) async {
    try {
      // Syncfusion doesn't directly support page export to image
      // For now, we'll return a placeholder or use alternative method
      // This would need additional implementation for full functionality
      throw Exception('Page export to image not yet implemented with Syncfusion');
    } catch (e) {
      throw Exception('Failed to get PDF page as image: $e');
    }
  }
  
  static Future<void> printPdf(
    String filePath, {
    String? password,
  }) async {
    try {
      Uint8List pdfData;
      
      if (password != null) {
        // For password protected PDFs, we need to decrypt in memory
        // This is a simplified approach - in production, you'd need proper PDF decryption
        final file = File(filePath);
        pdfData = await file.readAsBytes();
      } else {
        final file = File(filePath);
        pdfData = await file.readAsBytes();
      }
      
      await Printing.layoutPdf(
        onLayout: (format) => pdfData,
        name: FileUtils.getFileName(filePath),
      );
    } catch (e) {
      throw Exception('Failed to print PDF: $e');
    }
  }
  
  static Future<String> extractTextFromPage(
    String filePath, 
    int pageNumber, {
    String? password,
  }) async {
    try {
      // Syncfusion doesn't have built-in text extraction
      // This would need OCR implementation or alternative library
      // For now, return empty string
      return '';
    } catch (e) {
      return '';
    }
  }
  
  static Future<bool> validatePassword(String filePath, String password) async {
    try {
      // For password validation, we'll use a simple approach
      // Syncfusion will handle the actual validation in the viewer
      final file = File(filePath);
      final fileSize = await file.length();
      
      // If we can read the file, assume password might be valid
      // Real validation will happen in the viewer
      return fileSize > 0;
    } catch (e) {
      return false;
    }
  }
}