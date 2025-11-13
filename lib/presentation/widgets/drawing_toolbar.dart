import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'drawing_canvas.dart';
import '../providers/drawing_provider.dart';

class DrawingToolbar extends ConsumerWidget {
  const DrawingToolbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTool = ref.watch(selectedToolProvider);
    final selectedColor = ref.watch(selectedColorProvider);
    final strokeWidth = ref.watch(strokeWidthProvider);
    final strokes = ref.watch(drawingStrokesProvider);

    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Drawing tools
          _buildToolSelector(context, ref, selectedTool),

          const VerticalDivider(width: 1),

          // Color picker and stroke width
          if (selectedTool == DrawingTool.pen ||
              selectedTool == DrawingTool.highlighter)
            Expanded(
              child: _buildColorAndStrokeControls(
                  context, ref, selectedColor, strokeWidth),
            ),

          const VerticalDivider(width: 1),

          // Undo and Clear All buttons
          _buildActionButtons(context, ref, strokes),
        ],
      ),
    );
  }

  Widget _buildToolSelector(
    BuildContext context, 
    WidgetRef ref, 
    DrawingTool selectedTool
  ) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildToolButton(
            context: context,
            ref: ref,
            tool: DrawingTool.pen,
            icon: Icons.edit,
            isSelected: selectedTool == DrawingTool.pen,
            tooltip: 'Pennarello',
          ),
          _buildToolButton(
            context: context,
            ref: ref,
            tool: DrawingTool.highlighter,
            icon: Icons.highlight,
            isSelected: selectedTool == DrawingTool.highlighter,
            tooltip: 'Evidenziatore',
          ),
          _buildToolButton(
            context: context,
            ref: ref,
            tool: DrawingTool.eraser,
            icon: Icons.cleaning_services,
            isSelected: selectedTool == DrawingTool.eraser,
            tooltip: 'Gomma',
          ),
          _buildToolButton(
            context: context,
            ref: ref,
            tool: DrawingTool.text,
            icon: Icons.text_fields,
            isSelected: selectedTool == DrawingTool.text,
            tooltip: 'Testo',
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton({
    required BuildContext context,
    required WidgetRef ref,
    required DrawingTool tool,
    required IconData icon,
    required bool isSelected,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: () {
          ref.read(selectedToolProvider.notifier).state = tool;
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected 
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: isSelected 
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSurface,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildColorAndStrokeControls(
    BuildContext context,
    WidgetRef ref,
    Color selectedColor,
    double strokeWidth,
  ) {
    final colors = [
      Colors.black,
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.orange,
      Colors.purple,
      Colors.pink,
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          // Color palette orizzontale
          ...colors.map((color) {
            final isSelected =
                selectedColor.withValues(alpha: 1) == color.withValues(alpha: 1);

            return GestureDetector(
              onTap: () {
                ref.read(selectedColorProvider.notifier).state = color;
              },
              child: Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(
                          color: Theme.of(context).colorScheme.primary,
                          width: 3,
                        )
                      : Border.all(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                ),
                child: isSelected
                    ? Icon(
                        Icons.check,
                        color: _getContrastColor(color),
                        size: 16,
                      )
                    : null,
              ),
            );
          }),

          const SizedBox(width: 16),

          // Stroke width slider compatto
          Icon(
            Icons.line_weight,
            size: 20,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 150,
            child: Slider(
              value: strokeWidth,
              min: 0.5,
              max: 20.0,
              divisions: 39,
              onChanged: (value) {
                ref.read(strokeWidthProvider.notifier).state = value;
              },
            ),
          ),
          SizedBox(
            width: 32,
            child: Text(
              strokeWidth.toStringAsFixed(1),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Color _getContrastColor(Color color) {
    // Calculate luminance to determine if we should use black or white text
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  Widget _buildActionButtons(
    BuildContext context,
    WidgetRef ref,
    List<DrawingStroke> strokes,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Undo button
          Tooltip(
            message: 'Annulla ultimo tratto',
            child: IconButton(
              onPressed: strokes.isEmpty
                  ? null
                  : () {
                      final currentStrokes = ref.read(drawingStrokesProvider);
                      if (currentStrokes.isEmpty) return;

                      // Rimuovi l'ultimo tratto
                      ref.read(drawingStrokesProvider.notifier).state =
                          currentStrokes.sublist(0, currentStrokes.length - 1);
                    },
              icon: const Icon(Icons.undo),
              style: IconButton.styleFrom(
                minimumSize: const Size(40, 40),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Clear all button
          Tooltip(
            message: 'Cancella tutto',
            child: IconButton(
              onPressed: strokes.isEmpty
                  ? null
                  : () {
                      // Mostra dialogo di conferma
                      showDialog(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: const Text('Cancella tutto'),
                          content: const Text(
                            'Sei sicuro di voler cancellare tutte le annotazioni?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(dialogContext).pop(),
                              child: const Text('Annulla'),
                            ),
                            TextButton(
                              onPressed: () {
                                ref.read(drawingStrokesProvider.notifier).state = [];
                                Navigator.of(dialogContext).pop();
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: Theme.of(context).colorScheme.error,
                              ),
                              child: const Text('Cancella'),
                            ),
                          ],
                        ),
                      );
                    },
              icon: const Icon(Icons.delete_outline),
              style: IconButton.styleFrom(
                minimumSize: const Size(40, 40),
              ),
            ),
          ),
        ],
      ),
    );
  }
}