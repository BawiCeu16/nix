import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:nix/providers/music_provider.dart';
import 'package:provider/provider.dart';

class LyricsPage extends StatefulWidget {
  const LyricsPage({super.key});

  @override
  State<LyricsPage> createState() => _LyricsPageState();
}

class _LyricsPageState extends State<LyricsPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MusicProvider>();
    final song = provider.currentSong;

    if (song == null) {
      return const Scaffold(body: Center(child: Text('No song playing')));
    }

    final lyrics = provider.lyrics;

    return Scaffold(
      appBar: AppBar(title: Text(song.title)),
      body: lyrics.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Lyrics not found'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => provider.fetchLyricsFromLrcLib(
                      song.title,
                      song.artist ?? '',
                    ),
                    child: const Text('Retry fetch'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Lyrics List
                Expanded(
                  child: _LyricsList(scrollController: _scrollController),
                ),

                // Media Player Controls with Blur
                _PlayerControls(),
              ],
            ),
    );
  }
}

class _LyricsList extends StatelessWidget {
  final ScrollController scrollController;

  const _LyricsList({required this.scrollController});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MusicProvider>();
    final lyrics = provider.lyrics;
    final int? currentLine = provider.currentLine; // may be null

    // Auto-scroll to current line (safe null check)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients &&
          currentLine != null &&
          currentLine >= 0) {
        final targetOffset = currentLine * 60.0;
        // Avoid jitter by checking distance threshold
        if ((scrollController.offset - targetOffset).abs() > 8.0) {
          scrollController.animateTo(
            targetOffset,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
        }
      }
    });

    final inactiveColor =
        Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7) ??
        Theme.of(context).colorScheme.onSurface.withOpacity(0.7);

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      controller: scrollController,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      itemCount: lyrics.length,
      itemBuilder: (context, index) {
        final entry = lyrics[index];
        final lineText = entry['line'] as String? ?? '';
        final timeMs = entry['time'] as int? ?? 0;
        final isActive = (currentLine != null) && (index == currentLine);

        return GestureDetector(
          onTap: timeMs > 0
              ? () => provider.seek(Duration(milliseconds: timeMs))
              : null,
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            style: TextStyle(
              fontSize: isActive ? 22 : 16,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w400,
              color: isActive
                  ? Theme.of(context).colorScheme.primary
                  : inactiveColor,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Center(
                child: Text(
                  lineText.isEmpty ? '♪' : lineText,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PlayerControls extends StatelessWidget {
  const _PlayerControls({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MusicProvider>();

    return ClipRRect(
      // Clip for blur effect
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 0.2, sigmaY: 0.2),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              // Slider
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: StreamBuilder<Duration>(
                  stream: provider.throttledPositionStream,
                  builder: (context, snapshot) {
                    final current = snapshot.data ?? Duration.zero;
                    final total =
                        provider.audioPlayer.duration ?? Duration.zero;

                    // Guard against zero-duration (so slider max != 0)
                    final maxSeconds = total.inSeconds > 0
                        ? total.inSeconds.toDouble()
                        : 1.0;
                    final sliderValue = current.inSeconds.toDouble().clamp(
                      0.0,
                      maxSeconds,
                    );

                    return Column(
                      children: [
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            trackHeight: 5.0,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 0,
                              elevation: 0,
                            ),
                            overlayShape: SliderComponentShape.noOverlay,
                            thumbColor: Colors.transparent,
                          ),
                          child: TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 250),
                            tween: Tween<double>(
                              begin: sliderValue,
                              end: sliderValue,
                            ),
                            builder: (context, animatedValue, child) {
                              // ensure safe bounds
                              final safeValue = (animatedValue ?? 0.0).clamp(
                                0.0,
                                maxSeconds,
                              );
                              return Slider(
                                value: safeValue,
                                max: maxSeconds,
                                onChanged: (v) =>
                                    provider.seek(Duration(seconds: v.toInt())),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 5.0),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_formatTime(current)),
                              Text(_formatTime(total)),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              // Controls row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const SizedBox(width: 20),
                  IconButton(
                    onPressed: provider.playPrevious,
                    icon: const Icon(FlutterRemix.skip_back_fill),
                  ),
                  // Play/Pause as a circular filled button
                  FilledButton(
                    onPressed: () {
                      if (provider.isPlaying) {
                        provider.pause();
                      } else {
                        provider.resume();
                      }
                    },
                    style: FilledButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(8),
                      minimumSize: const Size(56, 56),
                    ),
                    child: Icon(
                      provider.isPlaying
                          ? FlutterRemix.pause_fill
                          : FlutterRemix.play_fill,
                      size: 30,
                    ),
                  ),
                  IconButton(
                    onPressed: provider.playNext,
                    icon: const Icon(FlutterRemix.skip_forward_fill),
                  ),
                  const SizedBox(width: 20),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }
}
