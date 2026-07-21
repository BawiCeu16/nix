import 'package:flutter/material.dart';
import 'package:flywheel_carousel/flywheel_carousel.dart';
import 'package:provider/provider.dart';
import 'package:nix/providers/user_provider.dart';
import 'package:nix/providers/current_music_provider.dart';
import 'package:nix/models/music/track.dart';
import 'package:nix/models/music/playlist.dart';
import 'package:nix/ui/widgets/dialogs/nix_dialog.dart';

class ProfilePageController extends ChangeNotifier {
  bool isEditing = false;
  final TextEditingController nameController = TextEditingController();
  int tempAvatarIndex = 0;

  void init(UserProvider user) {
    nameController.text = user.userName;
    tempAvatarIndex = user.avatarIndex;
  }

  void startEditing(UserProvider user) {
    isEditing = true;
    nameController.text = user.userName;
    tempAvatarIndex = user.avatarIndex;
    notifyListeners();
  }

  void cancelEditing() {
    isEditing = false;
    notifyListeners();
  }

  void saveEditing(BuildContext context) {
    final text = nameController.text.trim();
    if (text.isNotEmpty) {
      final user = context.read<UserProvider>();
      user.setUserName(text);
      user.setAvatarIndex(tempAvatarIndex);
    }
    isEditing = false;
    notifyListeners();
  }

  void setTempAvatar(int index) {
    tempAvatarIndex = index;
    notifyListeners();
  }

  void showAvatarPickerDialog(BuildContext context, UserProvider user) {
    int selected = isEditing ? tempAvatarIndex : user.avatarIndex;
    final colorScheme = Theme.of(context).colorScheme;

    NixDialog.show(
      context: context,
      title: 'Choose Avatar',
      subtitle: 'Spin to select your avatar',
      children: [
        StatefulBuilder(
          builder: (context, setState) {
            return SizedBox(
              height: 140,
              child: FlywheelCarousel<int>(
                height: 120,
                cardHeight: 90,
                viewportFraction: 0.35,
                loop: false,
                items: List.generate(UserProvider.avatarIcons.length, (i) => i),
                initialIndex: selected,
                onIndexChanged: (index) {
                  setState(() => selected = index);
                  setTempAvatar(index);
                  if (!isEditing) {
                    user.setAvatarIndex(index);
                  }
                },
                itemBuilder: (context, index, isSelected) {
                  final color = UserProvider.avatarColors[index];
                  return Center(
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      scale: isSelected ? 1.15 : 0.85,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? colorScheme.primary
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 30,
                          backgroundColor: color.withValues(alpha: 0.2),
                          child: Icon(
                            UserProvider.avatarIcons[index],
                            color: color,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  void playTopTrack(
    BuildContext context,
    Track track,
    List<Track> topTracks,
  ) {
    final currentMusic = context.read<CurrentMusicProvider>();
    final pl = Playlist(
      id: 'top_played',
      name: 'Top Listened',
      tracks: topTracks,
      createdAt: DateTime.now(),
    );
    currentMusic.playTrack(track, playlist: pl);
  }

  void disposeController() {
    nameController.dispose();
  }
}
