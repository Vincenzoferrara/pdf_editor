import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import '../../data/services/pdf_service.dart';
import '../providers/documents_provider.dart';

class CustomFloatingActionButton extends ConsumerWidget {
  const CustomFloatingActionButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FloatingActionButton(
      onPressed: () => _showFilePicker(context, ref),
      child: const Icon(Icons.add),
    );
  }

  Future<void> _showFilePicker(BuildContext context, WidgetRef ref) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        
        // Show loading indicator
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Caricamento PDF...'),
              duration: Duration(seconds: 1),
            ),
          );
        }

        try {
          // Load PDF document
          final pdfDocument = await PdfService.loadPdfDocument(filePath);
          
          // Add to documents list
          ref.read(documentsProvider.notifier).addDocument(pdfDocument);
          
          // Navigate to PDF viewer
          if (context.mounted) {
            context.push('/pdf_viewer', extra: pdfDocument);
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Errore nel caricamento del PDF: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}