import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:provider/provider.dart';
import '../../../../providers/settings_provider.dart';
import '../../../widgets/list_item/card_list_tile.dart';
import '../../../widgets/dialogs/nix_dialog.dart';

class AppearanceSettingsPage extends StatelessWidget {
  const AppearanceSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsParams = context.watch<SettingsProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainer,
      appBar: AppBar(
        title: const Text('Appearance'),
        backgroundColor: colorScheme.surfaceContainer,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        physics: const BouncingScrollPhysics(),
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 8, top: 12, bottom: 8),
            child: Text(
              'THEME',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1.2,
              ),
            ),
          ),
          CardListTile(
            title: 'Theme Mode',
            subtitle: settingsParams.themeMode.name.toUpperCase(),
            icon: FlutterRemix.contrast_2_line,
            isFirst: true,
            isLast: true,
            onTap: () => _showThemeModeDialog(context, settingsParams),
          ),

          const Padding(
            padding: EdgeInsets.only(left: 8, top: 24, bottom: 8),
            child: Text(
              'COLORS',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1.2,
              ),
            ),
          ),
          CardListTile(
            title: 'Accent Color Mode',
            subtitle: settingsParams.accentColorMode.name.toUpperCase(),
            icon: FlutterRemix.palette_line,
            isFirst: true,
            isLast: settingsParams.accentColorMode != AccentColorMode.custom,
            onTap: () => _showAccentModeDialog(context, settingsParams),
          ),

          if (settingsParams.accentColorMode == AccentColorMode.custom) ...[
            const SizedBox(height: 2.5),
            _CustomColorPicker(settings: settingsParams),
          ],

          const SizedBox(height: 24),
          // Preview Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            color: colorScheme.surface,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Preview',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          height: 12,
                          decoration: BoxDecoration(
                            color: colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 12,
                    width: 140,
                    decoration: BoxDecoration(
                      color: colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showThemeModeDialog(BuildContext context, SettingsProvider settings) {
    NixDialog.show(
      context: context,
      title: ' Theme Mode',
      children: ThemeMode.values.map((mode) {
        final index = ThemeMode.values.indexOf(mode);
        return Padding(
          padding: EdgeInsets.only(
            bottom: index == ThemeMode.values.length - 1 ? 0.0 : 2.5,
          ),
          child: CardListTile(
            title: mode.name.toUpperCase(),
            onTap: () {
              settings.setThemeMode(mode);
              Navigator.of(context, rootNavigator: true).pop();
            },
            trailing: IgnorePointer(
              child: Radio<ThemeMode>(
                value: mode,
                groupValue: settings.themeMode,
                onChanged: (_) {},
              ),
            ),
            isFirst: index == 0,
            isLast: index == ThemeMode.values.length - 1,
          ),
        );
      }).toList(),
    );
  }

  void _showAccentModeDialog(BuildContext context, SettingsProvider settings) {
    NixDialog.show(
      context: context,
      title: ' Accent Color Mode',
      children: AccentColorMode.values.map((mode) {
        final index = AccentColorMode.values.indexOf(mode);
        String label = mode.name.toUpperCase();
        if (mode == AccentColorMode.dynamic) label = "DYNAMIC (ALBUM ART)";

        return Padding(
          padding: EdgeInsets.only(
            bottom: index == ThemeMode.values.length - 1 ? 0.0 : 2.5,
          ),
          child: CardListTile(
            title: label,
            onTap: () {
              settings.setAccentColorMode(mode);
              Navigator.of(context, rootNavigator: true).pop();
            },
            trailing: IgnorePointer(
              child: Radio<AccentColorMode>(
                value: mode,
                groupValue: settings.accentColorMode,
                onChanged: (_) {},
              ),
            ),
            isFirst: index == 0,
            isLast: index == AccentColorMode.values.length - 1,
          ),
        );
      }).toList(),
    );
  }
}

class _CustomColorPicker extends StatelessWidget {
  final SettingsProvider settings;
  const _CustomColorPicker({required this.settings});

  static const List<Color> _colors = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
    Colors.blueGrey,
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      color: colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 16, bottom: 12),
              child: Text(
                'Pick Accent Color',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _colors.length,
                itemBuilder: (context, index) {
                  final color = _colors[index];
                  final isSelected =
                      settings.customAccentColor.value == color.value;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () => settings.setCustomAccentColor(color),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: colorScheme.primary, width: 3)
                              : null,
                        ),
                        child: isSelected
                            ? Icon(
                                FlutterRemix.check_line,
                                color: colorScheme.onPrimary,
                              )
                            : null,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
