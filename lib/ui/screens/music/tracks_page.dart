import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:nix/ui/widgets/tiles/track_tile.dart';
import 'package:nix/models/music/track.dart';
import 'package:nix/ui/widgets/common/nix_empty_state.dart';
import 'package:provider/provider.dart';
import 'package:nix/providers/music_provider.dart';
import 'package:nix/ui/widgets/common/nix_refreshable_list.dart';
import 'package:nix/ui/widgets/common/nix_bottom_spacer.dart';
import 'package:nix/ui/widgets/common/nix_scrollbar.dart';
import 'package:nix/ui/screens/music/controllers/tracks_controller.dart';

class TracksPage extends StatefulWidget {
  final String title;
  final List<Track> Function() tracksSource;

  const TracksPage({
    super.key,
    required this.title,
    required this.tracksSource,
  });

  @override
  State<TracksPage> createState() => _TracksPageState();
}

class _TracksPageState extends State<TracksPage> {
  late final TracksPageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TracksPageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final rawTracks = widget.tracksSource();
        final sortedTracks = _controller.getSortedTracks(rawTracks);

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
          appBar: AppBar(
            title: Text(widget.title),
            backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
            scrolledUnderElevation: 0,
            actions: [
              PopupMenuButton<TrackSort>(
                icon: const Icon(FlutterRemix.sort_desc),
                tooltip: 'Sort',
                initialValue: _controller.sort,
                onSelected: _controller.setSort,
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: TrackSort.defaultOrder,
                    child: Text('Default'),
                  ),
                  PopupMenuItem(
                    value: TrackSort.aToZ,
                    child: Text('A → Z'),
                  ),
                  PopupMenuItem(
                    value: TrackSort.zToA,
                    child: Text('Z → A'),
                  ),
                  PopupMenuItem(
                    value: TrackSort.duration,
                    child: Text('Duration'),
                  ),
                ],
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: NixRefreshableList(
              isEmpty: sortedTracks.isEmpty,
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
                  itemCount: sortedTracks.length + 1,
                  itemBuilder: (context, index) {
                    if (index == sortedTracks.length) {
                      return const NixBottomSpacer();
                    }
                    final track = sortedTracks[index];
                    return TrackTile(
                      track: track,
                      playlistContext: sortedTracks,
                      isFirst: index == 0,
                      isLast: index == sortedTracks.length - 1,
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
