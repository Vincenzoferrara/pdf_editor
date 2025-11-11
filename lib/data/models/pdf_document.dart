import 'package:equatable/equatable.dart';

class PdfDocument extends Equatable {
  final String id;
  final String name;
  final String filePath;
  final int fileSize;
  final DateTime lastModified;
  final bool isPasswordProtected;
  final bool hasSearchableText;
  final int pageCount;
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