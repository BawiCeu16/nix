import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';
import 'package:provider/provider.dart';

import 'package:nix/providers/current_music_provider.dart';
import 'package:nix/providers/music_provider.dart';
import 'package:nix/ui/screens/controllers/stats_controller.dart';
import 'package:nix/ui/widgets/common/nix_artwork.dart';
import 'package:nix/ui/widgets/common/nix_bottom_spacer.dart';

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
              'Listening Insights',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
            scrolledUnderElevation: 0,
            backgroundColor: colorScheme.surfaceContainer,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(FlutterRemix.refresh_line),
                tooltip: 'Refresh Stats',
                onPressed: () {
                  final music = context.read<MusicProvider>();
                  _controller.calculateStats(music);
                },
              ),
            ],
          ),
          body: RefreshIndicator(
            color: colorScheme.primary,
            backgroundColor: colorScheme.surface,
            onRefresh: () async {
              final music = context.read<MusicProvider>();
              _controller.calculateStats(music);
            },
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              children: [
                // ── Hero Highlight Card (Top Song) ──
                if (topSongStat != null) ...[
                  _buildHeroHighlightCard(context, topSongStat),
                  const SizedBox(height: 16),
                ],

                // ── Summary Cards Grid ──
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        context,
                        title: 'Total Plays',
                        value: '${_controller.totalPlayCount}',
                        icon: FlutterRemix.play_circle_fill,
                        accentColor: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildSummaryCard(
                        context,
                        title: 'Listen Time',
                        value: StatsController.formatDuration(
                          _controller.totalListeningTime,
                        ),
                        icon: FlutterRemix.time_fill,
                        accentColor: colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildSummaryCard(
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

                // ── Tab Navigation Selector ──
                Container(
                  height: 48,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      _buildTabButton(
                        context,
                        index: 0,
                        label: 'Top Songs',
                        icon: FlutterRemix.music_2_fill,
                      ),
                      _buildTabButton(
                        context,
                        index: 1,
                        label: 'Top Artists',
                        icon: FlutterRemix.user_4_fill,
                      ),
                      _buildTabButton(
                        context,
                        index: 2,
                        label: 'History',
                        icon: FlutterRemix.history_fill,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Tab Content Lists ──
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
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
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer.withValues(alpha: 0.8),
            colorScheme.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: NixArtwork(
                    id: stat.track.id,
                    type: ArtworkType.AUDIO,
                    width: 72,
                    height: 72,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700), // Gold
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                      )
                    ],
                  ),
                  child: const Icon(
                    FlutterRemix.vip_crown_fill,
                    size: 12,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
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
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '#1 TOP SONG',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: colorScheme.onPrimary,
                            letterSpacing: 0.5,
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
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    stat.track.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            IconButton.filledTonal(
              icon: const Icon(FlutterRemix.play_fill),
              onPressed: () {
                final player = context.read<CurrentMusicProvider>();
                player.playTrack(stat.track);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
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
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
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
            child: Icon(icon, size: 18, color: accentColor),
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

  Widget _buildTabButton(
    BuildContext context, {
    required int index,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _controller.selectedTabIndex == index;
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: GestureDetector(
        onTap: () => _controller.setTabIndex(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    )
                  ]
                : [],
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 15,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? colorScheme.onSurface
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopSongsList(BuildContext context) {
    final songs = _controller.topSongs;
    final colorScheme = Theme.of(context).colorScheme;
    final maxPlays = songs.isNotEmpty ? songs.first.playCount : 1;

    if (songs.isEmpty) {
      return _buildEmptyState(
        context,
        icon: FlutterRemix.music_2_line,
        message: 'No song plays recorded yet.\nStart listening to see your top songs!',
      );
    }

    return Column(
      key: const ValueKey('top_songs'),
      children: List.generate(songs.length, (index) {
        final stat = songs[index];
        final rank = index + 1;
        final ratio = (stat.playCount / maxPlays).clamp(0.05, 1.0);

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                final player = context.read<CurrentMusicProvider>();
                player.playTrack(stat.track);
              },
              child: Stack(
                children: [
                  // Relative popularity bar accent at bottom
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: ratio,
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: _getRankColor(rank, colorScheme).withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        _buildRankBadge(context, rank),
                        const SizedBox(width: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: NixArtwork(
                            id: stat.track.id,
                            type: ArtworkType.AUDIO,
                            width: 46,
                            height: 46,
                          ),
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
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${stat.playCount} ${stat.playCount == 1 ? 'play' : 'plays'}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTopArtistsList(BuildContext context) {
    final artists = _controller.topArtists;
    final colorScheme = Theme.of(context).colorScheme;
    final maxPlays = artists.isNotEmpty ? artists.first.totalPlayCount : 1;

    if (artists.isEmpty) {
      return _buildEmptyState(
        context,
        icon: FlutterRemix.user_4_line,
        message: 'No artist stats recorded yet.\nListen to songs to discover your top artists!',
      );
    }

    return Column(
      key: const ValueKey('top_artists'),
      children: List.generate(artists.length, (index) {
        final artist = artists[index];
        final rank = index + 1;
        final ratio = (artist.totalPlayCount / maxPlays).clamp(0.05, 1.0);

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                // Relative popularity bar accent
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: ratio,
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        color: _getRankColor(rank, colorScheme).withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(
                    children: [
                      _buildRankBadge(context, rank),
                      const SizedBox(width: 10),
                      CircleAvatar(
                        radius: 21,
                        backgroundColor:
                            colorScheme.secondaryContainer.withValues(alpha: 0.8),
                        child: Icon(
                          FlutterRemix.user_3_fill,
                          color: colorScheme.onSecondaryContainer,
                          size: 20,
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
                              '${artist.trackCount} ${artist.trackCount == 1 ? 'track played' : 'tracks played'}',
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
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.secondaryContainer.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${artist.totalPlayCount} ${artist.totalPlayCount == 1 ? 'play' : 'plays'}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildHistoryList(BuildContext context) {
    final history = _controller.playbackHistory;
    final colorScheme = Theme.of(context).colorScheme;

    if (history.isEmpty) {
      return _buildEmptyState(
        context,
        icon: FlutterRemix.history_line,
        message: 'No playback history recorded yet.\nPlayed songs will appear here.',
      );
    }

    return Column(
      key: const ValueKey('history'),
      children: List.generate(history.length, (index) {
        final item = history[index];
        final relativeTime = StatsController.formatRelativeTime(item.lastPlayed);

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: NixArtwork(
                  id: item.track.id,
                  type: ArtworkType.AUDIO,
                  width: 46,
                  height: 46,
                ),
              ),
              title: Text(
                item.track.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              subtitle: Text(
                item.track.artist,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
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
              onTap: () {
                final player = context.read<CurrentMusicProvider>();
                player.playTrack(item.track);
              },
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
        width: 26,
        height: 26,
        decoration: const BoxDecoration(
          color: Color(0xFFFFD700), // Gold
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Text(
            '1',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
        ),
      );
    } else if (rank == 2) {
      return Container(
        width: 26,
        height: 26,
        decoration: const BoxDecoration(
          color: Color(0xFFC0C0C0), // Silver
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Text(
            '2',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
        ),
      );
    } else if (rank == 3) {
      return Container(
        width: 26,
        height: 26,
        decoration: const BoxDecoration(
          color: Color(0xFFCD7F32), // Bronze
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Text(
            '3',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: 26,
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
        return const Color(0xFFFFD700);
      case 2:
        return const Color(0xFFC0C0C0);
      case 3:
        return const Color(0xFFCD7F32);
      default:
        return colorScheme.primary;
    }
  }

  Widget _buildEmptyState(
    BuildContext context, {
    required IconData icon,
    required String message,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 48, color: colorScheme.outline.withValues(alpha: 0.7)),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
