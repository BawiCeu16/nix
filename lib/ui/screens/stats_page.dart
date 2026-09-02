import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';
import 'package:provider/provider.dart';
import 'package:expressive_refresh/expressive_refresh.dart';

import 'package:nix/providers/current_music_provider.dart';
import 'package:nix/providers/music_provider.dart';
import 'package:nix/ui/screens/controllers/stats_controller.dart';
import 'package:nix/ui/widgets/common/nix_artwork.dart';
import 'package:nix/ui/widgets/common/nix_bottom_spacer.dart';
import 'package:nix/ui/widgets/common/nix_empty_state.dart';
import 'package:nix/ui/widgets/common/nix_section_header.dart';
import 'package:nix/ui/widgets/tiles/nix_choice_chip.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  late final StatsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = StatsController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final music = context.read<MusicProvider>();
        final currentMusic = context.read<CurrentMusicProvider>();
        _controller.init(music, currentMusic);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final topSongStat = _controller.topSong;

        return Scaffold(
          backgroundColor: colorScheme.surfaceContainer,
          appBar: AppBar(
            title: const Text(
              'Listening Stats',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            centerTitle: true,
            scrolledUnderElevation: 0,
            backgroundColor: colorScheme.surfaceContainer,
            elevation: 0,
          ),
          body: ExpressiveRefreshIndicator(
            onRefresh: () async {
              final music = context.read<MusicProvider>();
              _controller.calculateStats(music);
            },
            child: ListView(
              scrollCacheExtent: const .pixels(600.0),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              children: [
                // ── Overview Section ──
                const NixSectionHeader(title: 'Overview', topPadding: 4),

                // ── Hero Highlight Card (Top Song) ──
                if (topSongStat != null) ...[
                  _buildHeroHighlightCard(context, topSongStat),
                  const SizedBox(height: 10),
                ],

                // ── Bento Metrics Grid ──
                Row(
                  children: [
                    Expanded(
                      child: _buildBentoCard(
                        context,
                        title: 'Listen Time',
                        value: StatsController.formatDuration(
                          _controller.totalListeningTime,
                        ),
                        icon: FlutterRemix.time_fill,
                        accentColor: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildBentoCard(
                        context,
                        title: 'Total Plays',
                        value: '${_controller.totalPlayCount}',
                        icon: FlutterRemix.play_circle_fill,
                        accentColor: colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildBentoCard(
                        context,
                        title: 'Artists',
                        value: '${_controller.uniqueArtistsCount}',
                        icon: FlutterRemix.user_star_fill,
                        accentColor: colorScheme.tertiary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Insights Section ──
                const NixSectionHeader(title: 'Insights', topPadding: 0),

                // ── Nix Choice Chips Tab Selector ──
                Row(
                  children: [
                    Expanded(
                      child: NixChoiceChip<int>(
                        label: 'Top Songs',
                        value: 0,
                        groupValue: _controller.selectedTabIndex,
                        isFirst: true,
                        onChanged: _controller.setTabIndex,
                      ),
                    ),
                    const SizedBox(width: 2.5),
                    Expanded(
                      child: NixChoiceChip<int>(
                        label: 'Top Artists',
                        value: 1,
                        groupValue: _controller.selectedTabIndex,
                        onChanged: _controller.setTabIndex,
                      ),
                    ),
                    const SizedBox(width: 2.5),
                    Expanded(
                      child: NixChoiceChip<int>(
                        label: 'History',
                        value: 2,
                        groupValue: _controller.selectedTabIndex,
                        isLast: true,
                        onChanged: _controller.setTabIndex,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // ── Tab Content Lists ──
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: _controller.selectedTabIndex == 0
                      ? _buildTopSongsList(context)
                      : _controller.selectedTabIndex == 1
                      ? _buildTopArtistsList(context)
                      : _buildHistoryList(context),
                ),

                const NixBottomSpacer(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeroHighlightCard(BuildContext context, TrackStat stat) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            _controller.playTrack(
              context,
              stat.track,
              _controller.sortedTopSongs.map((s) => s.track).toList(),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    NixArtwork(
                      id: stat.track.id,
                      type: ArtworkType.AUDIO,
                      width: 68,
                      height: 68,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    Container(
                      padding: const EdgeInsets.all(3.5),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFD700), // Gold
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        FlutterRemix.vip_crown_fill,
                        size: 11,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              '#1 MOST PLAYED',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: colorScheme.onPrimaryContainer,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${stat.playCount} plays',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        stat.track.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        stat.track.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  icon: const Icon(FlutterRemix.play_fill),
                  onPressed: () {
                    _controller.playTrack(
                      context,
                      stat.track,
                      _controller.sortedTopSongs.map((s) => s.track).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBentoCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color accentColor,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: accentColor),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSongsList(BuildContext context) {
    final songs = _controller.sortedTopSongs;
    final colorScheme = Theme.of(context).colorScheme;
    final maxPlays = _controller.topSongs.isNotEmpty
        ? _controller.topSongs.first.playCount
        : 1;

    if (songs.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: NixEmptyState(
          icon: FlutterRemix.music_2_line,
          title: 'No song plays recorded yet',
          subtitle: 'Start listening to discover your top songs!',
        ),
      );
    }

    return Column(
      key: const ValueKey('top_songs'),
      children: List.generate(songs.length, (index) {
        final stat = songs[index];
        final rank = index + 1;
        final ratio = (stat.playCount / maxPlays).clamp(0.04, 1.0);
        final isFirst = index == 0;
        final isLast = index == songs.length - 1;

        return Padding(
          padding: const EdgeInsets.only(bottom: 2.5),
          child: _StatsGroupedTile(
            isFirst: isFirst,
            isLast: isLast,
            onTap: () {
              _controller.playTrack(
                context,
                stat.track,
                songs.map((s) => s.track).toList(),
              );
            },
            bottomAccentRatio: ratio,
            bottomAccentColor: _getRankColor(rank, colorScheme),
            child: Row(
              children: [
                _buildRankBadge(context, rank),
                const SizedBox(width: 10),
                NixArtwork(
                  id: stat.track.id,
                  type: ArtworkType.AUDIO,
                  width: 44,
                  height: 44,
                  borderRadius: BorderRadius.circular(8),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stat.track.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        stat.track.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    '${stat.playCount} ${stat.playCount == 1 ? 'play' : 'plays'}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTopArtistsList(BuildContext context) {
    final artists = _controller.sortedTopArtists;
    final colorScheme = Theme.of(context).colorScheme;
    final maxPlays = _controller.topArtists.isNotEmpty
        ? _controller.topArtists.first.totalPlayCount
        : 1;

    if (artists.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: NixEmptyState(
          icon: FlutterRemix.user_4_line,
          title: 'No artist stats recorded yet',
          subtitle: 'Listen to songs to discover your top artists!',
        ),
      );
    }

    return Column(
      key: const ValueKey('top_artists'),
      children: List.generate(artists.length, (index) {
        final artist = artists[index];
        final rank = index + 1;
        final ratio = (artist.totalPlayCount / maxPlays).clamp(0.04, 1.0);
        final isFirst = index == 0;
        final isLast = index == artists.length - 1;
        final firstTrackId = _controller.getFirstTrackIdForArtist(
          artist.artistName,
        );

        return Padding(
          padding: const EdgeInsets.only(bottom: 2.5),
          child: _StatsGroupedTile(
            isFirst: isFirst,
            isLast: isLast,
            onTap: () {
              _controller.openArtistDetails(context, artist.artistName);
            },
            bottomAccentRatio: ratio,
            bottomAccentColor: _getRankColor(rank, colorScheme),
            child: Row(
              children: [
                _buildRankBadge(context, rank),
                const SizedBox(width: 10),
                if (firstTrackId != null)
                  NixArtwork(
                    id: firstTrackId,
                    type: ArtworkType.AUDIO,
                    width: 44,
                    height: 44,
                    borderRadius: BorderRadius.circular(100),
                  )
                else
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: colorScheme.secondaryContainer,
                    child: Icon(
                      FlutterRemix.user_3_fill,
                      color: colorScheme.onSecondaryContainer,
                      size: 18,
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        artist.artistName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${artist.trackCount} ${artist.trackCount == 1 ? 'track' : 'tracks'} played',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    '${artist.totalPlayCount} ${artist.totalPlayCount == 1 ? 'play' : 'plays'}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  FlutterRemix.arrow_right_s_line,
                  size: 18,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildHistoryList(BuildContext context) {
    final history = _controller.sortedPlaybackHistory;
    final colorScheme = Theme.of(context).colorScheme;

    if (history.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: NixEmptyState(
          icon: FlutterRemix.history_line,
          title: 'No playback history recorded yet',
          subtitle: 'Played songs will appear here.',
        ),
      );
    }

    return Column(
      key: const ValueKey('history'),
      children: List.generate(history.length, (index) {
        final item = history[index];
        final isFirst = index == 0;
        final isLast = index == history.length - 1;
        final relativeTime = StatsController.formatRelativeTime(
          item.lastPlayed,
        );

        return Padding(
          padding: const EdgeInsets.only(bottom: 2.5),
          child: _StatsGroupedTile(
            isFirst: isFirst,
            isLast: isLast,
            onTap: () {
              _controller.playTrack(
                context,
                item.track,
                history.map((h) => h.track).toList(),
              );
            },
            child: Row(
              children: [
                NixArtwork(
                  id: item.track.id,
                  type: ArtworkType.AUDIO,
                  width: 44,
                  height: 44,
                  borderRadius: BorderRadius.circular(8),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.track.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.track.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    relativeTime,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildRankBadge(BuildContext context, int rank) {
    final colorScheme = Theme.of(context).colorScheme;

    if (rank == 1) {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: _getRankColor(rank, colorScheme),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            '1',
            style: TextStyle(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ),
      );
    } else if (rank == 2) {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: _getRankColor(rank, colorScheme),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            '2',
            style: TextStyle(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ),
      );
    } else if (rank == 3) {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: _getRankColor(rank, colorScheme),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            '3',
            style: TextStyle(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: 24,
      child: Text(
        '#$rank',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Color _getRankColor(int rank, ColorScheme colorScheme) {
    switch (rank) {
      case 1:
        return colorScheme.primary;
      case 2:
        return colorScheme.primary.withValues(alpha: 0.7);
      case 3:
        return colorScheme.primary.withValues(alpha: 0.5);
      default:
        return colorScheme.primary.withValues(alpha: 0.15);
    }
  }
}

/// Nix-styled interactive grouped tile container with continuous corner radii and micro-scaling
class _StatsGroupedTile extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final bool isFirst;
  final bool isLast;
  final double? bottomAccentRatio;
  final Color? bottomAccentColor;

  const _StatsGroupedTile({
    required this.child,
    required this.onTap,
    this.isFirst = false,
    this.isLast = false,
    this.bottomAccentRatio,
    this.bottomAccentColor,
  });

  @override
  State<_StatsGroupedTile> createState() => _StatsGroupedTileState();
}

class _StatsGroupedTileState extends State<_StatsGroupedTile> {
  bool _isPressed = false;

  void _setPressed(bool pressed) {
    if (_isPressed != pressed && mounted) {
      setState(() => _isPressed = pressed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultRadius = BorderRadius.only(
      topLeft: Radius.circular(widget.isFirst ? 16 : 5),
      topRight: Radius.circular(widget.isFirst ? 16 : 5),
      bottomLeft: Radius.circular(widget.isLast ? 16 : 5),
      bottomRight: Radius.circular(widget.isLast ? 16 : 5),
    );

    final targetRadius = _isPressed
        ? BorderRadius.circular(100.0)
        : defaultRadius;
    final targetScale = _isPressed ? 0.98 : 1.0;

    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: AnimatedScale(
        scale: targetScale,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutQuad,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOutQuad,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: targetRadius,
          ),
          clipBehavior: Clip.antiAlias,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              child: Stack(
                children: [
                  if (widget.bottomAccentRatio != null &&
                      widget.bottomAccentColor != null)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: widget.bottomAccentRatio!,
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            color: widget.bottomAccentColor!.withValues(
                              alpha: 0.75,
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: widget.child,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
