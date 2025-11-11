import 'package:equatable/equatable.dart';

class Annotation extends Equatable {
  final String id;
  final String documentId;
  final int pageNumber;
  final AnnotationType type;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final DateTime? modifiedAt;
  
  const Annotation({
    required this.id,
    required this.documentId,
    required this.pageNumber,
    required this.type,
    required this.data,
    required this.createdAt,
    this.modifiedAt,
  });
  
  Annotation copyWith({
    String? id,
    String? documentId,
    int? pageNumber,
    AnnotationType? type,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    DateTime? modifiedAt,
  }) {
    return Annotation(
      id: id ?? this.id,
      documentId: documentId ?? this.documentId,
      pageNumber: pageNumber ?? this.pageNumber,
      type: type ?? this.type,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? DateTime.now(),
    );
  }
  
  @override
  List<Object?> get props => [
        id,
        documentId,
        pageNumber,
        type,
        data,
        createdAt,
        modifiedAt,
      ];
}

enum AnnotationType {
  drawing,
  text,
  highlight,
  signature,
  shape,
  note,
}