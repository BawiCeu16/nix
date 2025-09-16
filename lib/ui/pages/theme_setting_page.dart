// lib/ui/pages/theme_settings_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:nix/ui/pages/monochrome_palette_page.dart';
import 'package:provider/provider.dart';

import 'package:nix/providers/theme_provider.dart';

class ThemeSettingsPage extends StatelessWidget {
  const ThemeSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.onPrimary,
        title: InkWell(
          onLongPress: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => MonochromePalettePage()),
          ),
          child: const Text('Appearance'),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Reset to defaults',
            icon: const Icon(FlutterRemix.refresh_line),
            onPressed: () => _showResetDialog(context, themeProvider),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          physics: BouncingScrollPhysics(),
          children: [
            // Card: Mode
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mode',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10.0),

                    // Mode options: Light / Dark / System
                    Row(
                      children: [
                        _modeChoice(
                          context,
                          themeProvider,
                          ThemeMode.light,
                          'Light',
                        ),
                        const SizedBox(width: 10.0),
                        _modeChoice(
                          context,
                          themeProvider,
                          ThemeMode.dark,
                          'Dark',
                        ),
                        const SizedBox(width: 10.0),
                        _modeChoice(
                          context,
                          themeProvider,
                          ThemeMode.system,
                          'System',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 5),

            // Card: Appearance / Monochrome switch
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 15.0,
                  vertical: 5,
                ),
                title: const Text(
                  'Monochrome (color blind mode)',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text(
                  'Use only greys — remove all colors from UI',
                ),
                value: themeProvider.isMonochrome,
                onChanged: (v) => themeProvider.setMonochromeEnabled(v),
                dense: false,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 5),

            // Card: Color accent (disabled when monochrome on)
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 5.0,
                  vertical: 0,
                ),
                leading: Container(
                  margin: EdgeInsets.only(left: 10),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: themeProvider.seedColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(width: 0.8, color: Colors.black26),
                  ),
                ),
                title: const Text(
                  'Accent color',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: themeProvider.isMonochrome
                    ? const Text('Disabled while Monochrome is active')
                    : const Text('Tap to choose a color accent'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(FlutterRemix.information_line),
                      tooltip: 'Accent color info',
                      onPressed: themeProvider.isMonochrome
                          ? null
                          : () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Accent color affects app accents and controls.',
                                  ),
                                ),
                              );
                            },
                    ),
                    IconButton(
                      icon: const Icon(FlutterRemix.paint_line),
                      tooltip: 'Choose accent',
                      onPressed: themeProvider.isMonochrome
                          ? null
                          : () => _showColorPicker(context, themeProvider),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 5),
            Card(
              elevation: 0,

              child: Consumer<ThemeProvider>(
                builder: (context, themeProvider, _) {
                  return SwitchListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),

                    title: Text("Dynamic Album Color"),
                    value: themeProvider.dynamicColorEnabled,
                    onChanged: themeProvider.isMonochrome
                        ? null // disable toggle when monochrome is ON
                        : (v) => themeProvider.setDynamicColorEnabled(v),
                    subtitle: themeProvider.isMonochrome
                        ? Text("Disabled in Monochrome mode")
                        : Text("Dynamic app theme adapts to album colors."),
                  );
                },
              ),
            ),

            const SizedBox(height: 5),

            // Small live preview card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10.0,
                  vertical: 10.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Preview',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10.0),
                    Row(
                      children: [
                        _previewTile(
                          'Primary',
                          Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 5.0),
                        _previewTile(
                          'Surface',
                          Theme.of(context).colorScheme.surface,
                        ),
                        const SizedBox(width: 5.0),
                        _previewTile(
                          'Background',
                          Theme.of(context).colorScheme.background,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10.0),

                    // simple sample controls to preview
                    Row(
                      children: [
                        FilledButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.check),
                          label: const Text('Button'),
                        ),
                        const SizedBox(width: 5.0),
                        OutlinedButton(
                          onPressed: () {},
                          child: const Text('Outline'),
                        ),
                        const SizedBox(width: 5.0),
                        IconButton(
                          onPressed: () {},
                          icon: Icon(Icons.star, size: 20),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10.0),

            // Footer: small help text
            Center(
              child: Text(
                'Minimal theme keeps UI focused and readable.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 10.0),
          ],
        ),
      ),
    );
  }

  // Small helper to build a compact mode choice button
  Widget _modeChoice(
    BuildContext context,
    ThemeProvider provider,
    ThemeMode mode,
    String label,
  ) {
    final isSelected = provider.themeMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => provider.setThemeMode(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primaryContainer
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(100.0),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
              width: isSelected ? 1.2 : 0.6,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Preview tile
  Widget _previewTile(String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(
            height: 48.0,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(width: 0.6, color: Colors.black12),
            ),
          ),
          const SizedBox(height: 5.0),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  // Color picker dialog
  void _showColorPicker(BuildContext context, ThemeProvider themeProvider) {
    Color pickerColor = themeProvider.seedColor;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Choose color'),
          content: SingleChildScrollView(
            child: BlockPicker(
              pickerColor: pickerColor,
              onColorChanged: (color) {
                pickerColor = color;
              },
            ),
          ),
          actions: [
            FilledButton.tonal(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                themeProvider.setSeedColor(pickerColor);
                Navigator.pop(context);
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
  }

  // Confirm reset dialog
  void _showResetDialog(BuildContext context, ThemeProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Reset theme'),
          content: const Text('Restore default theme and color?'),
          actions: [
            FilledButton.tonal(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                provider.setThemeMode(ThemeMode.system);
                provider.setSeedColor(Colors.blue);
                provider.setMonochromeEnabled(false);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Theme reset to defaults')),
                );
              },
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );
  }
}
