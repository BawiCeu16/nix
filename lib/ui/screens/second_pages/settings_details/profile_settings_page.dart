import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:provider/provider.dart';
import '../../../../providers/user_provider.dart';
import '../../../widgets/list_item/card_list_tile.dart';
import '../../../widgets/buttons/expressive_tone_button.dart';
import '../../../widgets/dialogs/nix_dialog.dart';

class ProfileSettingsPage extends StatelessWidget {
  const ProfileSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainer,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: colorScheme.surfaceContainer,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        physics: const BouncingScrollPhysics(),
        children: [
          // Large Avatar Preview
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 24),
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: UserProvider.avatarColors[user.avatarIndex]
                    .withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                UserProvider.avatarIcons[user.avatarIndex],
                color: UserProvider.avatarColors[user.avatarIndex],
                size: 60,
              ),
            ),
          ),

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

          const Padding(
            padding: EdgeInsets.only(left: 8, top: 24, bottom: 8),
            child: Text(
              'INFORMATION',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1.2,
              ),
            ),
          ),
          CardListTile(
            title: 'About You',
            subtitle: 'Update your profile information to personalize your Nix experience.',
            icon: FlutterRemix.information_line,
            isFirst: true,
            isLast: true,
            onTap: () {},
          ),
        ],
      ),
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
        ExpressiveToneButton(
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(FlutterRemix.check_line),
              SizedBox(width: 8),
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
