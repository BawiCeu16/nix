import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:provider/provider.dart';
import '../../../providers/settings_provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsParams = context.watch<SettingsProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainer,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: colorScheme.surfaceContainer,
        elevation: 0,
      ),
      body: ListView(
        children: [
          _SectionHeader(title: 'Appearance'),
          
          ListTile(
            title: const Text('Theme Mode'),
            subtitle: Text(settingsParams.themeMode.name.toUpperCase()),
            leading: const Icon(FlutterRemix.contrast_2_line),
            onTap: () => _showThemeModeDialog(context, settingsParams),
          ),

          ListTile(
            title: const Text('Accent Color'),
            subtitle: Text(settingsParams.accentColorMode.name.toUpperCase()),
            leading: Icon(
              FlutterRemix.palette_line,
              color: colorScheme.primary,
            ),
            onTap: () => _showAccentModeDialog(context, settingsParams),
          ),

          if (settingsParams.accentColorMode == AccentColorMode.custom)
            _CustomColorPicker(settings: settingsParams),

          const Divider(indent: 20, endIndent: 20),

          _SectionHeader(title: 'Playback'),
          SwitchListTile(
            title: const Text('Auto Play'),
            subtitle: const Text('Start next song automatically'),
            secondary: const Icon(FlutterRemix.play_circle_line),
            value: settingsParams.autoPlay,
            onChanged: (val) => settingsParams.autoPlay = val,
          ),

          const Divider(indent: 20, endIndent: 20),

          _SectionHeader(title: 'About'),
          const ListTile(
            title: Text('Nix Music'),
            subtitle: Text('Version 1.0.0'),
            leading: Icon(FlutterRemix.information_line),
          ),
        ],
      ),
    );
  }

  void _showThemeModeDialog(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Theme Mode'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ThemeMode.values.map((mode) {
            return RadioListTile<ThemeMode>(
              title: Text(mode.name.toUpperCase()),
              value: mode,
              groupValue: settings.themeMode,
              onChanged: (val) {
                if (val != null) settings.setThemeMode(val);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showAccentModeDialog(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accent Color Mode'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AccentColorMode.values.map((mode) {
            String label = mode.name.toUpperCase();
            if (mode == AccentColorMode.dynamic) label = "DYNAMIC (ALBUM ART)";
            
            return RadioListTile<AccentColorMode>(
              title: Text(label),
              value: mode,
              groupValue: settings.accentColorMode,
              onChanged: (val) {
                if (val != null) settings.setAccentColorMode(val);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, top: 20, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 20, bottom: 8),
            child: Text('Pick Accent Color'),
          ),
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _colors.length,
              itemBuilder: (context, index) {
                final color = _colors[index];
                final isSelected = settings.customAccentColor.value == color.value;
                
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
                        border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
                        boxShadow: isSelected ? [
                          BoxShadow(color: Colors.black26, blurRadius: 4, spreadRadius: 1)
                        ] : null,
                      ),
                      child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
