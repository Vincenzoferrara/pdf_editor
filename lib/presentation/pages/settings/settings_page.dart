import 'package:flutter/material.dart' hide ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/theme_provider.dart';

/// Pagina impostazioni completa
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Impostazioni'),
        centerTitle: false,
      ),
      body: ListView(
        children: [
          // Sezione Tema
          _buildSectionHeader(context, 'Tema'),
          _buildThemeModeSection(context, ref, themeState),

          const Divider(height: 32),

          // Sezione Colore Primario
          _buildSectionHeader(context, 'Colore Primario'),
          _buildPrimaryColorSection(context, ref, themeState),

          const Divider(height: 32),

          // Placeholder per future impostazioni
          _buildSectionHeader(context, 'Futureimpostazioni'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Altre impostazioni verranno aggiunte qui'),
            subtitle: Text('Placeholder per espansioni future'),
            enabled: false,
          ),
        ],
      ),
    );
  }

  /// Header sezione
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  /// Sezione selezione modalità tema
  Widget _buildThemeModeSection(
    BuildContext context,
    WidgetRef ref,
    ThemeState themeState,
  ) {
    return Column(
      children: [
        RadioListTile<ThemeMode>(
          title: const Text('Chiaro'),
          subtitle: const Text('Tema sempre chiaro'),
          value: ThemeMode.light,
          groupValue: themeState.themeMode,
          onChanged: (value) {
            if (value != null) {
              ref.read(themeProvider.notifier).setThemeMode(value);
            }
          },
          secondary: Icon(
            Icons.light_mode,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        RadioListTile<ThemeMode>(
          title: const Text('Scuro'),
          subtitle: const Text('Tema sempre scuro'),
          value: ThemeMode.dark,
          groupValue: themeState.themeMode,
          onChanged: (value) {
            if (value != null) {
              ref.read(themeProvider.notifier).setThemeMode(value);
            }
          },
          secondary: Icon(
            Icons.dark_mode,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        RadioListTile<ThemeMode>(
          title: const Text('Sistema'),
          subtitle: const Text('Segue le impostazioni del sistema'),
          value: ThemeMode.system,
          groupValue: themeState.themeMode,
          onChanged: (value) {
            if (value != null) {
              ref.read(themeProvider.notifier).setThemeMode(value);
            }
          },
          secondary: Icon(
            Icons.brightness_auto,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  /// Sezione selezione colore primario
  Widget _buildPrimaryColorSection(
    BuildContext context,
    WidgetRef ref,
    ThemeState themeState,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: AppTheme.primaryColors.entries.map((entry) {
          final colorName = entry.key;
          final color = entry.value;
          final isSelected = themeState.primaryColorName == colorName;

          return GestureDetector(
            onTap: () {
              ref.read(themeProvider.notifier).setPrimaryColor(colorName);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(
                            color: Theme.of(context).colorScheme.onSurface,
                            width: 3,
                          )
                        : null,
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: color.withOpacity(0.5),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                    ],
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          color: _getContrastColor(color),
                          size: 32,
                        )
                      : null,
                ),
                const SizedBox(height: 8),
                Text(
                  colorName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _getContrastColor(Color color) {
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}
