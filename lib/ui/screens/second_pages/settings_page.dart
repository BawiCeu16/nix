import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:nix/ui/widgets/buttons/expressive_button.dart';
import 'package:nix/ui/widgets/dialogs/nix_dialog.dart';
import 'package:nix/ui/widgets/list_item/card_list_tile.dart';
import 'package:provider/provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers/user_provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsParams = context.watch<SettingsProvider>();
    final user = context.watch<UserProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainer,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: colorScheme.surfaceContainer,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        physics: const BouncingScrollPhysics(),
        children: [
          _SectionHeader(title: 'Profile'),
          CardListTile(
            title: 'Nickname',
            subtitle: user.userName,
            icon: FlutterRemix.user_3_line,
            isFirst: true,
            onTap: () => _editNickname(context, user),
          ),
          const SizedBox(height: 2.5),
          CardListTile(
            title: 'Avatar',
            subtitle: 'Change your profile icon',
            icon: FlutterRemix.user_smile_line,
            isLast: true,
            onTap: () => _showAvatarPicker(context, user),
          ),

          _SectionHeader(title: 'Appearance'),

          CardListTile(
            title: 'Theme Mode',
            subtitle: settingsParams.themeMode.name.toUpperCase(),
            icon: FlutterRemix.contrast_2_line,
            isFirst: true,
            onTap: () => _showThemeModeDialog(context, settingsParams),
          ),
          const SizedBox(height: 2.5),
          CardListTile(
            title: 'Accent Color',
            subtitle: settingsParams.accentColorMode.name.toUpperCase(),
            icon: FlutterRemix.palette_line,
            isLast: settingsParams.accentColorMode != AccentColorMode.custom,
            onTap: () => _showAccentModeDialog(context, settingsParams),
          ),

          if (settingsParams.accentColorMode == AccentColorMode.custom) ...[
            const SizedBox(height: 2.5),
            _CustomColorPicker(settings: settingsParams),
          ],

          _SectionHeader(title: 'Playback'),
          CardListTile(
            title: 'Auto Play',
            subtitle: 'Start next song automatically',
            icon: FlutterRemix.play_circle_line,
            trailing: Switch(
              value: settingsParams.autoPlay,
              onChanged: (val) => settingsParams.autoPlay = val,
            ),
            isFirst: true,
            isLast: true,
            onTap: () => settingsParams.autoPlay = !settingsParams.autoPlay,
          ),

          _SectionHeader(title: 'About'),
          CardListTile(
            title: 'Nix Music',
            subtitle: 'Version 1.0.0',
            icon: FlutterRemix.information_line,
            isFirst: true,
            isLast: true,
            onTap: () {},
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

  void _editNickname(BuildContext context, UserProvider user) {
    final controller = TextEditingController(text: user.userName);
    NixDialog.show(
      context: context,
      title: 'Edit Nickname',
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
          child: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Enter nickname...',
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onSubmitted: (val) {
              if (val.trim().isNotEmpty) {
                user.setUserName(val.trim());
                Navigator.of(context, rootNavigator: true).pop();
              }
            },
          ),
        ),
        const SizedBox(height: 12),
        ExpressiveButton(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                FlutterRemix.check_line,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
              const SizedBox(width: 8),
              Text('SAVE'),
            ],
          ),
          onPressed: () {
            if (controller.text.trim().isNotEmpty) {
              user.setUserName(controller.text.trim());
              Navigator.of(context, rootNavigator: true).pop();
            }
          },
        ),
      ],
    );
  }

  void _showAvatarPicker(BuildContext context, UserProvider user) {
    NixDialog.show(
      context: context,
      title: 'Select Avatar',
      children: List.generate(UserProvider.avatarIcons.length, (index) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: index == UserProvider.avatarIcons.length - 1 ? 0.0 : 2.5,
          ),
          child: CardListTile(
            title: 'Avatar ${index + 1}',
            icon: UserProvider.avatarIcons[index],
            trailing: user.avatarIndex == index
                ? Icon(
                    FlutterRemix.check_line,
                    color: Theme.of(context).colorScheme.primary,
                  )
                : null,
            isFirst: index == 0,
            isLast: index == UserProvider.avatarIcons.length - 1,
            onTap: () {
              user.setAvatarIndex(index);
              Navigator.of(context, rootNavigator: true).pop();
            },
          ),
        );
      }),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 20, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
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
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(5),
          bottom: Radius.circular(12),
        ),
      ),
      color: Theme.of(context).colorScheme.surface,
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
                              ? Border.all(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 3,
                                )
                              : null,
                        ),
                        child: isSelected
                            ? Icon(
                                FlutterRemix.check_line,
                                color: Theme.of(context).colorScheme.surface,
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
