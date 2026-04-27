import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:nix/ui/widgets/list_item/track_tile.dart';
import 'package:nix/models/music/track.dart';
import 'package:nix/ui/widgets/common/nix_empty_state.dart';
import 'package:provider/provider.dart';
import 'package:nix/providers/music_provider.dart';
import 'package:nix/ui/widgets/common/nix_refreshable_list.dart';
import 'package:nix/ui/widgets/common/nix_bottom_spacer.dart';
import 'package:nix/ui/widgets/common/nix_scrollbar.dart';

enum _TrackSort { defaultOrder, aToZ, zToA, duration }

class TracksPage extends StatefulWidget {
  final String title;
  final List<Track> Function() tracksSource;

  const TracksPage({super.key, required this.title, required this.tracksSource});

  @override
  State<TracksPage> createState() => _TracksPageState();
}

class _TracksPageState extends State<TracksPage> {
  _TrackSort _sort = _TrackSort.defaultOrder;

  @override
  Widget build(BuildContext context) {
    // Dynamically fetch the current state of tracks whenever it builds
    List<Track> tracksList = widget.tracksSource();

    // Basic sorting stub
    if (_sort == _TrackSort.aToZ) {
      tracksList.sort((a, b) => a.title.compareTo(b.title));
    } else if (_sort == _TrackSort.zToA) {
      tracksList.sort((a, b) => b.title.compareTo(a.title));
    } else if (_sort == _TrackSort.duration) {
      tracksList.sort((a, b) => a.duration.compareTo(b.duration));
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        scrolledUnderElevation: 0,
        actions: [
          PopupMenuButton<_TrackSort>(
            icon: const Icon(FlutterRemix.sort_desc),
            tooltip: 'Sort',
            initialValue: _sort,
            onSelected: (v) => setState(() => _sort = v),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: _TrackSort.defaultOrder,
                child: Text('Default'),
              ),
              PopupMenuItem(value: _TrackSort.aToZ, child: Text('A → Z')),
              PopupMenuItem(value: _TrackSort.zToA, child: Text('Z → A')),
              PopupMenuItem(value: _TrackSort.duration, child: Text('Duration')),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: NixRefreshableList(
          isEmpty: tracksList.isEmpty,
          onRefresh: () async =>
              await context.read<MusicProvider>().scanDevice(),
          emptyState: const NixEmptyState(
            icon: FlutterRemix.music_2_line,
            title: "No tracks available",
          ),
          child: NixScrollbar(
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.only(top: 8),
              itemCount: tracksList.length + 1,
              itemBuilder: (context, index) {
                if (index == tracksList.length) {
                  return const NixBottomSpacer();
                }
                final track = tracksList[index];
                return TrackTile(
                  track: track,
                  playlistContext: tracksList,
                  isFirst: index == 0,
                  isLast: index == tracksList.length - 1,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
