# Nix — Architecture & Structure

## Overview

Nix is a gesture-driven, minimal music player. Its architecture is built around three principles:

1. **Native-first media access** — `on_audio_query` reads directly from Android's MediaStore. No filesystem scanning, no manual metadata parsing.
2. **Physics-based UI** — The miniplayer uses raw `PointerEvent` + `VelocityTracker` to derive squish, bounce, and snap behaviors rather than high-level gesture detectors.
3. **Scoped state** — Global providers handle data and playback. Frame-by-frame animation state is always local to the widget that owns it.

---

## Directory Tree

```
lib/
├── main.dart                          # Entry point, MultiProvider setup, AudioService init
│
├── core/
│   ├── constants.dart                 # Application-wide constants
│   ├── format.dart                    # Extension methods: duration, bytes formatting
│   ├── haptic_utils.dart              # Haptic feedback helpers
│   ├── hive_keys.dart                 # Centralized constants for all persistent storage keys
│   ├── math_utils.dart                # Pure math helpers: rangeProgress, norm, inverseAboveOne
│   └── nix_icons.dart                 # Custom Nix icon definitions
│
├── models/
│   ├── music/
│   │   ├── album.dart                 # Album model
│   │   ├── artist.dart                # Artist model
│   │   ├── playlist.dart              # Playlist model
│   │   └── track.dart                 # Track model
│   └── settings/
│       ├── artwork_quality.dart       # Artwork quality enum
│       └── timer_gesture.dart         # Sleep timer gesture enum
│
├── providers/
│   ├── artwork_provider.dart          # Artwork extraction & caching
│   ├── current_music_provider.dart    # BaseAudioHandler: playback, queue, shuffle, seek
│   ├── lyrics_provider.dart           # Lyrics fetching & sync
│   ├── music_provider.dart            # MediaStore scan, songs/albums/artists/playlists state
│   ├── settings_provider.dart         # Appearance & playback settings (Hive-backed)
│   ├── sleep_timer_provider.dart      # Sleep timer countdown & auto-stop logic
│   ├── user_provider.dart             # User profile (name, avatar)
│   └── will_pop_provider.dart         # Back-button interception bridge
│
├── services/
│   └── snackbar_service.dart          # Global snackbar service
│
└── ui/
    ├── theme/
    │   └── nix_theme.dart             # Material 3 dynamic color theme builder
    ├── miniplayer/
    │   ├── models/
    │   │   └── animation_data.dart    # PlayerAnimationData: computed progress values bundle
    │   ├── now_playing.dart           # Physics engine & orchestrator (PointerEvent + VelocityTracker)
    │   └── widgets/
    │       ├── lyrics_section.dart    # Lyrics section widget
    │       ├── player_controls.dart   # Play/pause, seek slider, skip, shuffle buttons
    │       ├── queue_view.dart        # "Up Next" queue list (slides in on over-drag)
    │       ├── top_bar.dart           # "Now Playing" label + dismiss chevron
    │       ├── track_image.dart       # Artwork: animated size, border-radius, parallax
    │       └── track_info.dart        # Title + artist with AnimatedSwitcher on track change
    │
    └── screens/
        ├── navigation_screen.dart     # Root scaffold: bottom nav, miniplayer stack, scale-down bg
        ├── onboarding_page.dart       # First-launch storage permission flow
        ├── profile_page.dart          # User stats and profile page
        │
        ├── main/
        │   ├── home_page.dart         # Recently listened, albums carousel, all songs preview
        │   ├── library_page.dart      # Tab host: Songs / Albums / Artists / Playlists
        │   └── search_page.dart       # Real-time search across songs, albums, artists
        │
        ├── music/
        │   ├── albums_page.dart       # Albums grid
        │   ├── artists_page.dart      # Artists grid
        │   ├── playlist_view_page.dart# Playlist detail with reorderable track list
        │   ├── playlists_page.dart    # Playlists list + create / delete
        │   └── tracks_page.dart       # Generic reusable songs list (sort, shuffle, play all)
        │
        └── settings/
            ├── settings_page.dart     # Settings entry with navigation to sub-pages
            ├── about_page.dart                 # App version, links
            ├── appearance_settings_page.dart   # Theme seed color, AMOLED toggle
            ├── gestures_settings_page.dart     # Gestures settings
            ├── library_settings_page.dart      # Library settings
            └── playback_settings_page.dart     # Skip silence, volume normalization
```

---

## Providers

| Provider | Extends | Responsibility |
|---|---|---|
| `CurrentMusicProvider` | `BaseAudioHandler` + `ChangeNotifier` | Playback engine: play, pause, seek, skip, queue, shuffle, repeat. Integrates with `audio_service` for background + notification controls. |
| `MusicProvider` | `ChangeNotifier` | MediaStore scan via `on_audio_query`. Exposes `songs`, `albums`, `artists`, `playlists`, `recentlyPlayed`, and favorite toggling. Persists playlists and favorites via Hive. |
| `SettingsProvider` | `ChangeNotifier` | Reads/writes appearance and playback settings from the `settings` Hive box. |
| `SleepTimerProvider` | `ChangeNotifier` | Countdown timer that stops playback after a configured duration. |
| `UserProvider` | `ChangeNotifier` | User's display name and avatar index, persisted in Hive. |
| `WillPopProvider` | — | Holds a nullable `bool Function()?` callback. Lets the miniplayer inject its own back-button logic without Navigator routes. |

---

## Miniplayer Architecture

`NowPlaying` is the core physics engine. It tracks raw pointer events and computes several normalized progress values passed down as a `PlayerAnimationData` bundle:

| Value | Range | Meaning |
|---|---|---|
| `bounceProgress` | `0.0 → 1.0+` | Player open progress, can exceed 1.0 on over-drag |
| `bounceClampedProgress` | `0.0 → 1.0` | Clamped version used for safe interpolation |
| `queueProgress` | `0.0 → 1.0` | How far the user has dragged past fully open (shows queue) |
| `bottomOffset` | px | Vertical translation for the artwork bounce effect |

Each child widget (`TrackImage`, `TrackInfo`, `PlayerControls`, `QueueView`) receives this bundle and independently computes its own layout, opacity, and transform — no `setState` cascade.

---

## Key Widget Conventions

- **`QueryArtworkWidget`** — used at every artwork site with resolution-matched `artworkWidth`/`artworkHeight` and `FilterQuality.high`:
  - List tiles (48 dp) → `200 × 200`
  - Cards / grid items (130–180 dp) → `400 × 400`
  - Page headers / full-screen (300 dp+) → `800 × 800`

- **`TrackTile`** — supports swipe-to-queue-next (start → end), long-press song info, and a context menu for playlist, artist, and album navigation.

- **`NixDialog`** — bottom-anchored action sheet with song artwork header, used for all track context menus.

- **`NixPageHeader`** — reusable album/artist/playlist hero header (300 × 300 dp artwork + title + action row).

---

## State Flow

```
main.dart
  └── MultiProvider
        ├── MusicProvider          → scans MediaStore on launch & pull-to-refresh
        ├── CurrentMusicProvider   → registered as AudioService handler
        ├── SettingsProvider       → reads Hive on init
        ├── SleepTimerProvider
        ├── UserProvider
        └── WillPopProvider
              └── NavigationScreen
                    ├── Bottom navigation (Home / Library / Search / Profile)
                    └── NowPlaying (stacked above everything)
                          ├── registers snapToMini() into WillPopProvider
                          ├── PlayerControls   (consumes CurrentMusicProvider)
                          ├── TrackImage       (consumes CurrentMusicProvider)
                          ├── TrackInfo        (consumes CurrentMusicProvider)
                          ├── QueueView        (consumes CurrentMusicProvider)
                          └── TopBar
```
