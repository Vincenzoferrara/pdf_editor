import 'package:equatable/equatable.dart';

class OcrResult extends Equatable {
  final bool hasText;
  final String extractedText;
  final List<TextBlock> textBlocks;
  final double confidence;
  final bool isProcessed;
  
  const OcrResult({
    this.hasText = false,
    this.extractedText = '',
    this.textBlocks = const [],
    this.confidence = 0.0,
    this.isProcessed = false,
  });
  
  OcrResult copyWith({
    bool? hasText,
    String? extractedText,
    List<TextBlock>? textBlocks,
    double? confidence,
    bool? isProcessed,
  }) {
    return OcrResult(
      hasText: hasText ?? this.hasText,
      extractedText: extractedText ?? this.extractedText,
      textBlocks: textBlocks ?? this.textBlocks,
      confidence: confidence ?? this.confidence,
      isProcessed: isProcessed ?? this.isProcessed,
    );
  }
  
  @override
  List<Object?> get props => [
        hasText,
        extractedText,
        textBlocks,
        confidence,
        isProcessed,
      ];
}

class TextBlock extends Equatable {
  final String text;
  final Rect boundingBox;
  final List<String> lines;
  final double confidence;
  final String language;
  
  const TextBlock({
    required this.text,
    required this.boundingBox,
    required this.lines,
    this.confidence = 0.0,
    this.language = 'unknown',
  });
  
  @override
  List<Object?> get props => [
        text,
        boundingBox,
        lines,
        confidence,
        language,
      ];
}

class Rect extends Equatable {
  final double left;
  final double top;
  final double right;
  final double bottom;
  
  const Rect({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });
  
  double get width => right - left;
  double get height => bottom - top;
  
  @override
  List<Object?> get props => [left, top, right, bottom];
}