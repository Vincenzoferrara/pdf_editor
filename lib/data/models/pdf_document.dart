import 'package:equatable/equatable.dart';

/// Modello immutabile per rappresentare un documento PDF
/// Ottimizzato con Equatable per confronti efficienti e prestazioni superiori
class PdfDocument extends Equatable {
  /// Identificatore unico del documento
  final String id;
  
  /// Nome visualizzato del file
  final String name;
  
  /// Percorso completo del file su disco
  final String filePath;
  
  /// Dimensione del file in bytes
  final int fileSize;
  
  /// Timestamp dell'ultima modifica
  final DateTime lastModified;
  
  /// Indica se il documento è protetto da password
  final bool isPasswordProtected;
  
  /// Indica se il documento contiene testo ricercabile (OCR)
  final bool hasSearchableText;
  
  /// Numero totale di pagine nel documento
  final int pageCount;
  
  /// Percorso dell'anteprima/thumbnail (opzionale)
  final String? thumbnailPath;
  
  const PdfDocument({
    required this.id,
    required this.name,
    required this.filePath,
    required this.fileSize,
    required this.lastModified,
    this.isPasswordProtected = false,
    this.hasSearchableText = true,
    this.pageCount = 0,
    this.thumbnailPath,
  });
  
  /// Metodo copyWith ottimizzato per creare copie con valori modificati
  /// Essenziale per pattern immutabili e gestione stato efficiente
  PdfDocument copyWith({
    String? id,
    String? name,
    String? filePath,
    int? fileSize,
    DateTime? lastModified,
    bool? isPasswordProtected,
    bool? hasSearchableText,
    int? pageCount,
    String? thumbnailPath,
  }) {
    return PdfDocument(
      id: id ?? this.id,
      name: name ?? this.name,
      filePath: filePath ?? this.filePath,
      fileSize: fileSize ?? this.fileSize,
      lastModified: lastModified ?? this.lastModified,
      isPasswordProtected: isPasswordProtected ?? this.isPasswordProtected,
      hasSearchableText: hasSearchableText ?? this.hasSearchableText,
      pageCount: pageCount ?? this.pageCount,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
    );
  }
  
  /// Props per Equatable - ottimizza confronti e previene rebuild non necessari
  @override
  List<Object?> get props => [
        id,
        name,
        filePath,
        fileSize,
        lastModified,
        isPasswordProtected,
        hasSearchableText,
        pageCount,
        thumbnailPath,
      ];
}