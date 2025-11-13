import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import '../../data/services/pdf_service.dart';
import '../providers/documents_provider.dart';
import '../providers/pdf_creation_provider.dart';

class CustomFloatingActionButton extends ConsumerWidget {
  const CustomFloatingActionButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FloatingActionButton(
      onPressed: () => _showFilePicker(context, ref),
      child: const Icon(Icons.add),
    );
  }

  Future<void> _showActionMenu(BuildContext context, WidgetRef ref) async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.file_open),
                title: const Text('Apri PDF esistente'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showFilePicker(context, ref);
                },
              ),
              ListTile(
                leading: const Icon(Icons.create_new_folder),
                title: const Text('Crea nuovo PDF'),
                onTap: () {
                  Navigator.of(context).pop();
                  _createNewPdf(context, ref);
                },
              ),
            ],
          ),
        );
      },
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

  Future<void> _createNewPdf(BuildContext context, WidgetRef ref) async {
    try {
      final creationService = ref.read(pdfCreationProvider);
      final choice = await creationService.showCreationDialog(context);
      
      if (choice != null) {
        // Show loading indicator
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Creazione PDF...'),
              duration: Duration(seconds: 2),
            ),
          );
        }

        final filePath = await creationService.handleCreationChoice(context, choice);
        
        if (filePath != null) {
          // Load the newly created PDF
          final pdfDocument = await PdfService.loadPdfDocument(filePath);
          
          // Add to documents list
          ref.read(documentsProvider.notifier).addDocument(pdfDocument);

          // Navigate to PDF viewer
          if (context.mounted) {
            context.push('/pdf_viewer', extra: pdfDocument);
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore nella creazione del PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}