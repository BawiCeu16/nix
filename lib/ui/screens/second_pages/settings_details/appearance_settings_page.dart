import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:nix/ui/widgets/dialogs/nix_dialog.dart';
import 'package:nix/ui/widgets/list_item/card_list_tile.dart';
import 'package:provider/provider.dart';
import '../../../../providers/settings_provider.dart';
import '../../../widgets/list_item/nix_choice_chip.dart';
import '../../../widgets/common/nix_section_header.dart';

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
          const NixSectionHeader(title: 'Theme', topPadding: 16),
          Card(
            elevation: 0,
            margin: EdgeInsets.zero,
            color: colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              child: Row(
                children: ThemeMode.values.map((mode) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: NixChoiceChip<ThemeMode>(
                        label: mode.name.toUpperCase(),
                        value: mode,
                        groupValue: settingsParams.themeMode,
                        onChanged: (v) => settingsParams.setThemeMode(v),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const NixSectionHeader(title: 'Colors', topPadding: 24),
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
        ],
      ),
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
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(16),
          top: Radius.circular(5),
        ),
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
                physics: const BouncingScrollPhysics(),
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
