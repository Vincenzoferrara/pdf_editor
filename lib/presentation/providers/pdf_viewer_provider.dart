import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/pdf_document.dart';
import '../../data/services/pdf_service.dart';

class PdfViewerState {
  final PdfDocument? document;
  final int currentPage;
  final int totalPages;
  final bool isLoading;
  final String? error;
  
  const PdfViewerState({
    this.document,
    this.currentPage = 1,
    this.totalPages = 0,
    this.isLoading = false,
    this.error,
  });
  
  PdfViewerState copyWith({
    PdfDocument? document,
    int? currentPage,
    int? totalPages,
    bool? isLoading,
    String? error,
  }) {
    return PdfViewerState(
      document: document ?? this.document,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class PdfViewerNotifier extends StateNotifier<PdfViewerState> {
  PdfViewerNotifier() : super(const PdfViewerState());

  Future<void> loadDocument(PdfDocument document) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // Syncfusion handles platform compatibility automatically
      // We'll let the viewer handle the actual PDF loading
      // Just estimate page count from file size for now
      final file = File(document.filePath);
      final fileSize = await file.length();
      final pageCount = (fileSize / (3 * 1024)).ceil();
      
      state = state.copyWith(
        document: document,
        totalPages: pageCount > 0 ? pageCount : 1,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load PDF: ${e.toString()}',
      );
    }
  }

  Future<void> loadPasswordProtectedDocument(
    PdfDocument document,
    String password,
  ) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final loadedDocument = await PdfService.openPasswordProtectedPdf(
        document.filePath,
        password,
      );
      
      state = state.copyWith(
        document: loadedDocument,
        totalPages: loadedDocument.pageCount,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void updateCurrentPage(int page) {
    state = state.copyWith(currentPage: page);
  }


}

final pdfViewerProvider = StateNotifierProvider<PdfViewerNotifier, PdfViewerState>((ref) {
  return PdfViewerNotifier();
});