import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/pdf_document.dart';
import '../providers/documents_provider.dart';

/// Griglia documenti ottimizzata con animazioni fluide e gestione stati efficiente
/// Utilizza ConsumerWidget per rebuild mirati e performance ottimali
class DocumentGrid extends ConsumerWidget {
  const DocumentGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch del provider - rebuild solo quando lo stato dei documenti cambia
    final documentsState = ref.watch(documentsProvider);
    final documents = documentsState.documents;

    // Stati di loading con indicator ottimizzato
    if (documentsState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Gestione errori con UI informativa e opzione retry
    if (documentsState.error != null) {
      return _buildErrorState(context, ref, documentsState.error!);
    }

    // Stato vuoto con call-to-action chiara
    if (documents.isEmpty) {
      return _buildEmptyState(context);
    }

    // Griglia principale con animazioni ottimizzate
    return _buildDocumentGrid(documents);
  }

  /// Costruisce l'interfaccia di errore con pulsante retry
  Widget _buildErrorState(BuildContext context, WidgetRef ref, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Errore nel caricamento dei documenti',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // Usa read invece di watch per evitare rebuild non necessari
              ref.read(documentsProvider.notifier).refreshDocuments();
            },
            child: const Text('Riprova'),
          ),
        ],
      ),
    );
  }

  /// Costruisce l'interfaccia vuota con guida per l'utente
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open,
            size: 120,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 24),
          Text(
            'Nessun documento',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tocca il pulsante + per aggiungere il tuo primo PDF',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  /// Costruisce la griglia documenti con animazioni ottimizzate
  Widget _buildDocumentGrid(List documents) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: AnimationLimiter(
        child: GridView.builder(
          // Delegate ottimizzato per griglia 2 colonne responsive
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.7,
          ),
          itemCount: documents.length,
          // Builder ottimizzato con animazioni staggered
          itemBuilder: (context, index) {
            return AnimationConfiguration.staggeredGrid(
              position: index,
              duration: const Duration(milliseconds: 375),
              columnCount: 2,
              child: ScaleAnimation(
                child: FadeInAnimation(
                  child: DocumentCard(document: documents[index]),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class DocumentCard extends StatelessWidget {
  final PdfDocument document;
  
  const DocumentCard({
    super.key,
    required this.document,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          context.push('/pdf_viewer', extra: document);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // PDF thumbnail or placeholder
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                        Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                      ],
                  ),
                ),
                child: document.thumbnailPath != null
                    ? Image.asset(
                        document.thumbnailPath!,
                        fit: BoxFit.cover,
                      )
                    : Icon(
                        Icons.picture_as_pdf,
                        size: 48,
                        color: Theme.of(context).colorScheme.primary,
                      ),
              ),
            ),
            
            // Document info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Title
                    Expanded(
                      child: Text(
                        document.name,
                        style: Theme.of(context).textTheme.titleSmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Metadata
                    Row(
                      children: [
                        if (document.isPasswordProtected)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Icon(
                              Icons.lock,
                              size: 16,
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        
                        if (!document.hasSearchableText)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Icon(
                              Icons.image,
                              size: 16,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        
                        Text(
                          '${document.pageCount} pag',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        
                        const Spacer(),
                        
                        Text(
                          _formatFileSize(document.fileSize),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}