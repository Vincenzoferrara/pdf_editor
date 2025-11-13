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
      
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'documentId': documentId,
      'pageNumber': pageNumber,
      'type': type.name,
      'data': data,
      'createdAt': createdAt.toIso8601String(),
      'modifiedAt': modifiedAt?.toIso8601String(),
    };
  }
  
  factory Annotation.fromJson(Map<String, dynamic> json) {
    return Annotation(
      id: json['id'],
      documentId: json['documentId'],
      pageNumber: json['pageNumber'],
      type: AnnotationType.values.firstWhere((e) => e.name == json['type']),
      data: Map<String, dynamic>.from(json['data']),
      createdAt: DateTime.parse(json['createdAt']),
      modifiedAt: json['modifiedAt'] != null ? DateTime.parse(json['modifiedAt']) : null,
    );
  }
}

enum AnnotationType {
  drawing,
  text,
  highlight,
  signature,
  shape,
  note,
}