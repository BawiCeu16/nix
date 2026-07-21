import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:provider/provider.dart';
import 'package:nix/models/music/playlist.dart';
import 'package:nix/models/music/track.dart';
import 'package:nix/providers/music_provider.dart';
import 'package:nix/providers/current_music_provider.dart';
import 'package:nix/ui/widgets/dialogs/nix_dialog.dart';
import 'package:nix/ui/widgets/tiles/card_list_tile.dart';
import 'package:nix/ui/widgets/dialogs/playlist_dialogs.dart';
import 'package:nix/ui/widgets/common/nix_playlist_cover.dart';
import 'package:nix/ui/screens/music/playlist_view_page.dart';
import 'package:nix/services/snackbar_service.dart';

class PlaylistsPageController extends ChangeNotifier {
  void openPlaylistView(BuildContext context, Playlist playlist) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlaylistViewPage(
          playlistName: playlist.name,
          playlistId: playlist.id,
        ),
      ),
    );
  }

  void createNewPlaylist(BuildContext context) {
    PlaylistDialogs.showPlaylistActionDialog(context);
  }

  void editPlaylist(BuildContext context, Playlist playlist) {
    PlaylistDialogs.showPlaylistActionDialog(
      context,
      initialName: playlist.name,
      playlistId: playlist.id,
    );
  }

  void deletePlaylist(BuildContext context, Playlist playlist) {
    PlaylistDialogs.showDeleteConfirmation(
      context,
      playlist.id,
      playlist.name,
    );
  }

  void shufflePlaylist(BuildContext context, Playlist playlist) {
    if (playlist.tracks.isEmpty) return;
    final audio = context.read<CurrentMusicProvider>();
    final shuffled = List<Track>.from(playlist.tracks)..shuffle();
    if (!audio.isShuffleEnabled) audio.toggleShuffle();
    audio.playTrack(shuffled.first, playlist: playlist);
  }

  void playPlaylist(BuildContext context, Playlist playlist) {
    if (playlist.tracks.isEmpty) return;
    final audio = context.read<CurrentMusicProvider>();
    audio.playTrack(playlist.tracks.first, playlist: playlist);
  }

  void showPlaylistMenu(BuildContext context, Playlist playlist) {
    NixDialog.show(
      context: context,
      children: [
        Column(
          children: [
            const SizedBox(height: 8),
            NixPlaylistCover(playlist: playlist, size: 120, radius: 16),
            const SizedBox(height: 16),
            Text(
              playlist.name,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              "${playlist.tracks.length} Tracks",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            CardListTile(
              title: "Edit",
              icon: FlutterRemix.edit_line,
              isFirst: true,
              isLast: false,
              onTap: () {
                Navigator.of(context, rootNavigator: true).pop();
                editPlaylist(context, playlist);
              },
            ),
            const SizedBox(height: 2),
            CardListTile(
              title: "Delete",
              icon: FlutterRemix.delete_bin_line,
              isFirst: false,
              isLast: true,
              onTap: () {
                Navigator.of(context, rootNavigator: true).pop();
                deletePlaylist(context, playlist);
              },
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: CardListTile(
                    title: "Shuffle",
                    icon: FlutterRemix.shuffle_line,
                    isFirst: true,
                    isLast: true,
                    onTap: () {
                      Navigator.of(context, rootNavigator: true).pop();
                      shufflePlaylist(context, playlist);
                    },
                  ),
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: CardListTile(
                    title: "Play",
                    icon: FlutterRemix.play_fill,
                    isFirst: true,
                    isLast: true,
                    onTap: () {
                      Navigator.of(context, rootNavigator: true).pop();
                      playPlaylist(context, playlist);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  void reorderPlaylistTracks({
    required BuildContext context,
    required String playlistId,
    required int oldIndex,
    required int newIndex,
    required int totalTracksCount,
  }) {
    if (oldIndex < 1 || oldIndex > totalTracksCount) return;

    int adjustedOld = oldIndex - 1;
    int adjustedNew = newIndex - 1;

    if (adjustedNew < 0) adjustedNew = 0;
    if (adjustedNew >= totalTracksCount) adjustedNew = totalTracksCount - 1;

    context.read<MusicProvider>().reorderPlaylistTracks(
          playlistId,
          adjustedOld,
          adjustedNew,
        );
  }

  void removeTrackFromPlaylist({
    required BuildContext context,
    required String playlistId,
    required Track track,
  }) {
    context.read<MusicProvider>().removeTrackFromPlaylist(playlistId, track);
    context.showSuccessSnackBar('Removed "${track.title}"');
  }
}
