import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final drawingModeProvider = StateProvider<bool>((ref) => false);
final selectedToolProvider = StateProvider<DrawingTool>((ref) => DrawingTool.pen);
final selectedColorProvider = StateProvider<Color>((ref) => Colors.black);
final strokeWidthProvider = StateProvider<double>((ref) => 2.0);

enum DrawingTool {
  pen,
  highlighter,
  eraser,
  text,
  signature,
  shape,
}

class DrawingToolbar extends ConsumerWidget {
  const DrawingToolbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTool = ref.watch(selectedToolProvider);
    final selectedColor = ref.watch(selectedColorProvider);
    final strokeWidth = ref.watch(strokeWidthProvider);
    
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drawing tools
          _buildToolSelector(context, ref, selectedTool),
          
          const Divider(height: 1),
          
          // Color picker and stroke width
          if (selectedTool == DrawingTool.pen || 
              selectedTool == DrawingTool.highlighter ||
              selectedTool == DrawingTool.text ||
              selectedTool == DrawingTool.signature)
            _buildColorAndStrokeControls(context, ref, selectedColor, strokeWidth),
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
          _buildToolButton(
            context: context,
            ref: ref,
            tool: DrawingTool.signature,
            icon: Icons.draw,
            isSelected: selectedTool == DrawingTool.signature,
            tooltip: 'Firma',
          ),
          _buildToolButton(
            context: context,
            ref: ref,
            tool: DrawingTool.shape,
            icon: Icons.shape_line,
            isSelected: selectedTool == DrawingTool.shape,
            tooltip: 'Forme',
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
      Colors.white,
      Colors.red,
      Colors.green,
      Colors.blue,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
      Colors.brown,
      Colors.grey,
    ];
    
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          // Color palette
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: colors.length,
              itemBuilder: (context, index) {
                final color = colors[index];
                final isSelected = selectedColor.withValues(alpha: 1) == color.withValues(alpha: 1);
                
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
                          : null,
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
              },
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Stroke width slider
          Row(
            children: [
              Icon(
                Icons.brush,
                size: 20,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
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
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
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
}