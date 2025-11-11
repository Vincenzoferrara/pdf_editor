import 'dart:io';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image/image.dart' as img;
import '../models/ocr_result.dart' as model;
import '../../core/utils/file_utils.dart';

class OcrService {
  late final TextRecognizer _textRecognizer;
  
  OcrService() {
    _textRecognizer = GoogleMlKit.vision.textRecognizer();
  }
  
  Future<model.OcrResult> processImageForOcr(String imagePath) async {
    try {
      // Check if file exists
      final file = File(imagePath);
      if (!await file.exists()) {
        return const model.OcrResult(isProcessed: true);
      }
      
      // Preprocess image for better OCR
      final processedImage = await _preprocessImage(imagePath);
      
      // Create InputImage from processed image
      final inputImage = InputImage.fromFilePath(processedImage);
      
      // Process with ML Kit
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      
      // Convert to our model
      final textBlocks = _convertToTextBlocks(recognizedText);
      final extractedText = recognizedText.text;
      final hasText = extractedText.isNotEmpty;
      final confidence = _calculateAverageConfidence(recognizedText);
      
      return model.OcrResult(
        hasText: hasText,
        extractedText: extractedText,
        textBlocks: textBlocks,
        confidence: confidence,
        isProcessed: true,
      );
    } catch (e) {
      return model.OcrResult(
        isProcessed: true,
      );
    }
  }
  
  Future<model.OcrResult> processPdfPage(String pdfPath, int pageNumber) async {
    try {
      // This would require PDF to image conversion
      // For now, return a placeholder
      return const model.OcrResult(
        isProcessed: false,
      );
    } catch (e) {
      return model.OcrResult(
        isProcessed: true,
      );
    }
  }
  
  Future<bool> hasSearchableText(String pdfPath) async {
    return await FileUtils.hasSearchableText(pdfPath);
  }
  
  Future<String> _preprocessImage(String imagePath) async {
    try {
      // Read image
      final originalImage = img.decodeImage(await File(imagePath).readAsBytes());
      if (originalImage == null) return imagePath;
      
      // Resize if too large
      var processedImage = originalImage;
      if (processedImage.width > 2000 || processedImage.height > 2000) {
        processedImage = img.copyResize(
          processedImage,
          width: processedImage.width > 2000 ? 2000 : null,
          height: processedImage.height > 2000 ? 2000 : null,
          interpolation: img.Interpolation.linear,
        );
      }
      
      // Convert to grayscale for better OCR
      processedImage = img.grayscale(processedImage);
      
      // Enhance contrast
      processedImage = img.adjustColor(processedImage, contrast: 1.2);
      
      // Save processed image
      final processedPath = imagePath.replaceAll('.', '_processed.');
      final processedFile = File(processedPath);
      await processedFile.writeAsBytes(img.encodePng(processedImage));
      
      return processedPath;
    } catch (e) {
      return imagePath;
    }
  }
  
  List<model.TextBlock> _convertToTextBlocks(RecognizedText recognizedText) {
    final blocks = <model.TextBlock>[];
    
    for (final block in recognizedText.blocks) {
      final lines = block.lines.map((line) => line.text).toList();
      final boundingBox = model.Rect(
        left: block.boundingBox.left,
        top: block.boundingBox.top,
        right: block.boundingBox.right,
        bottom: block.boundingBox.bottom,
      );
      
      blocks.add(model.TextBlock(
        text: block.text,
        boundingBox: boundingBox,
        lines: lines,
        confidence: 0.0, // ML Kit TextBlock doesn't have confidence property
        language: block.recognizedLanguages.isNotEmpty 
            ? block.recognizedLanguages.first 
            : 'unknown',
      ));
    }
    
    return blocks;
  }
  
  double _calculateAverageConfidence(RecognizedText recognizedText) {
    if (recognizedText.blocks.isEmpty) return 0.0;
    
    double totalConfidence = 0.0;
    int elementCount = 0;
    
    for (final block in recognizedText.blocks) {
      totalConfidence += 0.0; // ML Kit TextBlock doesn't have confidence property
      elementCount++;
      
      for (final line in block.lines) {
        totalConfidence += line.confidence ?? 0.0;
        elementCount++;
        
        for (final element in line.elements) {
          totalConfidence += element.confidence ?? 0.0;
          elementCount++;
        }
      }
    }
    
    return elementCount > 0 ? totalConfidence / elementCount : 0.0;
  }
  
  void dispose() {
    _textRecognizer.close();
  }
}