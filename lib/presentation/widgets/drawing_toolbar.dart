import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/drawing_provider.dart';
import '../providers/editing_objects_provider.dart';

/// Toolbar ottimizzata per strumenti di disegno e testo
class DrawingToolbar extends ConsumerWidget {
  const DrawingToolbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTool = ref.watch(selectedToolProvider);
    final selectedColor = ref.watch(selectedColorProvider);
    final strokeWidth = ref.watch(strokeWidthProvider);
    final textFontSize = ref.watch(textFontSizeProvider);
    final textFontFamily = ref.watch(textFontFamilyProvider);
    final editingObjects = ref.watch(editingObjectsProvider);

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
          // Selettore strumenti (senza gomma)
          _buildToolSelector(context, ref, selectedTool),

          const VerticalDivider(width: 1),

          // Controlli specifici per strumento
          if (selectedTool == DrawingTool.text)
            Expanded(
              child: _buildTextControls(
                context,
                ref,
                selectedColor,
                textFontSize,
                textFontFamily,
              ),
            )
          else
            Expanded(
              child: _buildDrawingControls(
                context,
                ref,
                selectedColor,
                strokeWidth,
              ),
            ),

          const VerticalDivider(width: 1),

          // Pulsanti azione
          _buildActionButtons(context, ref, editingObjects),
        ],
      ),
    );
  }

  /// Selettore strumenti (pen, highlighter, text)
  Widget _buildToolSelector(
    BuildContext context,
    WidgetRef ref,
    DrawingTool selectedTool,
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

  /// Controlli per disegno (pen/highlighter)
  Widget _buildDrawingControls(
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
          // Palette colori
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

          // Spessore tratto
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

  /// Controlli per testo (colore, font size, font family)
  Widget _buildTextControls(
    BuildContext context,
    WidgetRef ref,
    Color selectedColor,
    double fontSize,
    String fontFamily,
  ) {
    final colors = [
      Colors.black,
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
    ];

    final fonts = [
      'Roboto',
      'Arial',
      'Times New Roman',
      'Courier New',
      'Georgia',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          // Palette colori (più compatta per testo)
          ...colors.map((color) {
            final isSelected =
                selectedColor.withValues(alpha: 1) == color.withValues(alpha: 1);

            return GestureDetector(
              onTap: () {
                ref.read(selectedColorProvider.notifier).state = color;
              },
              child: Container(
                width: 28,
                height: 28,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        )
                      : Border.all(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                ),
              ),
            );
          }),

          const SizedBox(width: 16),

          // Font size
          Icon(
            Icons.format_size,
            size: 20,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 120,
            child: Slider(
              value: fontSize,
              min: 8.0,
              max: 48.0,
              divisions: 40,
              onChanged: (value) {
                ref.read(textFontSizeProvider.notifier).state = value;
              },
            ),
          ),
          SizedBox(
            width: 32,
            child: Text(
              fontSize.toInt().toString(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(width: 16),

          // Font family dropdown
          Icon(
            Icons.font_download,
            size: 20,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: fontFamily,
            items: fonts.map((font) {
              return DropdownMenuItem<String>(
                value: font,
                child: Text(
                  font,
                  style: TextStyle(fontFamily: font, fontSize: 14),
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                ref.read(textFontFamilyProvider.notifier).state = value;
              }
            },
            underline: const SizedBox(),
          ),
        ],
      ),
    );
  }

  Color _getContrastColor(Color color) {
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  Widget _buildActionButtons(
    BuildContext context,
    WidgetRef ref,
    List<dynamic> objects,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Undo - rimuove ultimo oggetto aggiunto
          Tooltip(
            message: 'Annulla',
            child: IconButton(
              onPressed: objects.isEmpty
                  ? null
                  : () {
                      final currentObjects = ref.read(editingObjectsProvider);
                      if (currentObjects.isEmpty) return;

                      ref.read(editingObjectsProvider.notifier).state =
                          currentObjects.sublist(0, currentObjects.length - 1);
                    },
              icon: const Icon(Icons.undo),
              style: IconButton.styleFrom(
                minimumSize: const Size(40, 40),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Clear all - cancella tutti gli oggetti
          Tooltip(
            message: 'Cancella tutto',
            child: IconButton(
              onPressed: objects.isEmpty
                  ? null
                  : () {
                      showDialog(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: const Text('Cancella tutto'),
                          content: const Text(
                            'Cancellare tutti gli oggetti?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(dialogContext).pop(),
                              child: const Text('Annulla'),
                            ),
                            TextButton(
                              onPressed: () {
                                ref.read(editingObjectsProvider.notifier).state = [];
                                ref.read(selectedObjectIdProvider.notifier).state = null;
                                Navigator.of(dialogContext).pop();
                              },
                              style: TextButton.styleFrom(
                                foregroundColor:
                                    Theme.of(context).colorScheme.error,
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
