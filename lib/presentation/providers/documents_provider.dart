import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/pdf_document.dart';

class DocumentsState {
  final List<PdfDocument> documents;
  final bool isLoading;
  final String? error;
  
  const DocumentsState({
    this.documents = const [],
    this.isLoading = false,
    this.error,
  });
  
  DocumentsState copyWith({
    List<PdfDocument>? documents,
    bool? isLoading,
    String? error,
  }) {
    return DocumentsState(
      documents: documents ?? this.documents,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class DocumentsNotifier extends StateNotifier<DocumentsState> {
  DocumentsNotifier() : super(const DocumentsState());

  Future<void> loadDocuments() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // TODO: Implement actual document loading from storage
      await Future.delayed(const Duration(seconds: 1));
      
      final mockDocuments = <PdfDocument>[];
      
      state = state.copyWith(
        documents: mockDocuments,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> addDocument(PdfDocument document) async {
    final updatedDocuments = [...state.documents, document];
    state = state.copyWith(documents: updatedDocuments);
  }

  Future<void> removeDocument(String documentId) async {
    final updatedDocuments = state.documents
        .where((doc) => doc.id != documentId)
        .toList();
    state = state.copyWith(documents: updatedDocuments);
  }

  Future<void> refreshDocuments() async {
    await loadDocuments();
  }
}

final documentsProvider = StateNotifierProvider<DocumentsNotifier, DocumentsState>((ref) {
  return DocumentsNotifier();
});