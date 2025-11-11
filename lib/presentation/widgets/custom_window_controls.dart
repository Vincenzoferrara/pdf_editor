import 'package:flutter/material.dart';

class CustomWindowControls extends StatelessWidget {
  const CustomWindowControls({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
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