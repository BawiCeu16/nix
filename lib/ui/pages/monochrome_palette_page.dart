import 'package:flutter/material.dart';

class MonochromePalettePage extends StatelessWidget {
  const MonochromePalettePage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // Extract all scheme colors into a list
    final colors = <String, Color>{
      'primary': scheme.primary,
      'onPrimary': scheme.onPrimary,
      'secondary': scheme.secondary,
      'onSecondary': scheme.onSecondary,
      'error': scheme.error,
      'onError': scheme.onError,
      'background': scheme.background,
      'onBackground': scheme.onBackground,
      'surface': scheme.surface,
      'onSurface': scheme.onSurface,
      'primaryContainer': scheme.primaryContainer,
      'onPrimaryContainer': scheme.onPrimaryContainer,
      'secondaryContainer': scheme.secondaryContainer,
      'onSecondaryContainer': scheme.onSecondaryContainer,
      'surfaceVariant': scheme.surfaceVariant,
      'outline': scheme.outline,
      'shadow': scheme.shadow,
      'inverseSurface': scheme.inverseSurface,
      'onInverseSurface': scheme.onInverseSurface,
      'inversePrimary': scheme.inversePrimary,
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text("Monochrome Palette"),
        centerTitle: true,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // 2 cards per row
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2, // square-ish cards
        ),
        itemCount: colors.length,
        itemBuilder: (context, index) {
          final name = colors.keys.elementAt(index);
          final color = colors.values.elementAt(index);

          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0), // 100% rounded feel
            ),
            elevation: 0.0,
            color: color,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  name,
                  style: TextStyle(
                    color: _textColorForBackground(color),
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Decide text color automatically (black or white) based on background brightness
  Color _textColorForBackground(Color bg) {
    return bg.computeLuminance() > 0.5 ? Colors.black : Colors.white;
  }
}
