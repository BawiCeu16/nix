# nix

A fast, minimal music player for Android built with Flutter.

## Features

- **Native media scanning** via `on_audio_query` — reads directly from MediaStore, no filesystem parsing
- **High-quality artwork** — `QueryArtworkWidget` with resolution-matched requests and `FilterQuality.high` across all surfaces
- **Gesture-driven player** — physics-based miniplayer with velocity tracking, parallax artwork, and snap animations
- **Dynamic color** — Material You theming from album art via `dynamic_color`
- **Audio service** — background playback, media session, and notification controls via `audio_service` + `just_audio`
- **Sleep timer** — configurable auto-stop with fade-out
- **Playlists** — create, edit, and reorder user playlists persisted with Hive
- **Favorites** — one-tap heart toggle, persisted across sessions
- **Queue** — play next / add to queue with swipe-to-remove
- **Sort & filter** — per-page sorting for songs, albums, artists, and playlists
- **Search** — real-time search across songs, albums, and artists
- **Onboarding** — first-launch permission flow
- **Settings** — appearance (theme seed, AMOLED), playback (skip silence, volume normalization), profile

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3.x (Dart 3) |
| State management | `provider` |
| Audio engine | `just_audio` + `audio_service` |
| Media query | `on_audio_query` |
| Persistence | `hive` + `hive_flutter` |
| Theming | `dynamic_color` (Material You) |
| UI extras | `expressive_refresh`, `flutter_m3shapes_extended` |

## Current Status: Production-Ready
The UI/UX and design system are currently complete. The recent major refactor modernized the folder structure, centralized the styling tokens to the `NixTheme` class, decoupled all storage keys into a `HiveKeys` constant file, cleaned up completely unused logic strings, and documented public methods. The application is production-stable and scalable.

## Getting Started

```bash
flutter pub get
flutter run
```

> Requires Android device or emulator with API 21+. Storage / media permission is requested on first launch via the onboarding flow.

## Project Layout

See [`STRUCTURE.md`](STRUCTURE.md) for the full directory breakdown and architecture notes.
