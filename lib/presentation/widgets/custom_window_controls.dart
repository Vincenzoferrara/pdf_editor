import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Barra superiore custom per desktop con controlli finestra e pulsante impostazioni
class CustomWindowControls extends StatelessWidget {
  const CustomWindowControls({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Titolo app e padding sinistro
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Text(
                'Editor PDF',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ),

          // Pulsante Impostazioni
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 20),
            onPressed: () => context.push('/settings'),
            tooltip: 'Impostazioni',
            style: IconButton.styleFrom(
              minimumSize: const Size(40, 32),
              padding: const EdgeInsets.all(4),
            ),
          ),

          // Controlli finestra
          _WindowButton(
            icon: Icons.remove,
            onPressed: () {
              // TODO: Implement minimize
            },
          ),
          _WindowButton(
            icon: Icons.crop_square,
            onPressed: () {
              // TODO: Implement maximize/restore
            },
          ),
          _WindowButton(
            icon: Icons.close,
            isCloseButton: true,
            onPressed: () {
              // TODO: Implement close
            },
          ),
        ],
      ),
    );
  }
}

class _WindowButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool isCloseButton;

  const _WindowButton({
    required this.icon,
    required this.onPressed,
    this.isCloseButton = false,
  });

  @override
  State<_WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<_WindowButton> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Container(
          width: 46,
          height: 32,
          decoration: BoxDecoration(
            color: isHovered
                ? widget.isCloseButton
                    ? Colors.red
                    : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
                : Colors.transparent,
          ),
          child: Icon(
            widget.icon,
            size: 16,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}