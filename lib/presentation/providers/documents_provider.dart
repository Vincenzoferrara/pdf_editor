import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/pdf_document.dart';

/// Stato immutabile per la gestione dei documenti
/// Ottimizzato con operatori di uguaglianza per rebuild minimi
class DocumentsState {
  final List<PdfDocument> documents;
  final bool isLoading;
  final String? error;
  
  const DocumentsState({
    this.documents = const [],
    this.isLoading = false,
    this.error,
  });
  
  /// CopyWith ottimizzato per aggiornamenti di stato efficienti
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
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocumentsState &&
          runtimeType == other.runtimeType &&
          documents == other.documents &&
          isLoading == other.isLoading &&
          error == other.error;

  @override
  int get hashCode =>
      documents.hashCode ^
      isLoading.hashCode ^
      error.hashCode;
}

/// Notifier per la gestione dei documenti con operazioni ottimizzate
/// Implementa pattern immutabile e gestione efficiente della memoria
class DocumentsNotifier extends StateNotifier<DocumentsState> {
  DocumentsNotifier() : super(const DocumentsState());

  /// Carica i documenti con gestione stati ottimizzata
  /// NOTA: Implementare caricamento effettivo da storage
  Future<void> loadDocuments() async {
    // Imposta stato loading per feedback UI immediato
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // Simulazione caricamento - sostituire con implementazione reale
      await Future.delayed(const Duration(milliseconds: 500));
      
      // TODO: Implementare caricamento documenti da storage locale/cloud
      final mockDocuments = <PdfDocument>[];
      
      // Aggiorna stato con documenti caricati
      state = state.copyWith(
        documents: mockDocuments,
        isLoading: false,
      );
    } catch (e) {
      // Gestione errori con stato informativo
      state = state.copyWith(
        isLoading: false,
        error: 'Errore nel caricamento documenti: ${e.toString()}',
      );
    }
  }

  /// Aggiunge documento con ottimizzazione memoria
  /// Utilizza spread operator per creare nuova lista immutabile
  Future<void> addDocument(PdfDocument document) async {
    // Crea nuova lista con documento aggiunto
    final updatedDocuments = [...state.documents, document];
    state = state.copyWith(documents: updatedDocuments);
  }

  /// Rimuove documento con filtraggio ottimizzato
  /// Utilizza where() per efficiente rimozione senza modificare lista originale
  Future<void> removeDocument(String documentId) async {
    final updatedDocuments = state.documents
        .where((doc) => doc.id != documentId)
        .toList();
    state = state.copyWith(documents: updatedDocuments);
  }

  /// Aggiorna lista documenti con refresh completo
  /// Riutilizza logica loadDocuments per consistenza
  Future<void> refreshDocuments() async {
    await loadDocuments();
  }
}

/// Provider globale per la gestione dei documenti
/// Utilizza StateNotifier per gestione stato ottimizzata e rebuild minimi
final documentsProvider = StateNotifierProvider<DocumentsNotifier, DocumentsState>((ref) {
  return DocumentsNotifier();
});