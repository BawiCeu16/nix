# Flutter Project Structure & Architecture

## 1. Project Overview

This app is a highly dynamic, gesture-driven music player emphasizing fluid UI morphing and complex micro-animations. The core architectural approach relies on localized state management fused with custom physics engines built entirely around Flutter's `AnimationController` and raw pointer event tracking.

**Core Patterns:**
- **State Management:** Uses the `provider` package primarily for dependency injection and exposing simple callback hooks (like back-button interception) across disparate layers of the widget tree.
- **Custom Physics Engine:** Instead of high-level gesture detectors, the main player relies heavily on tracking user finger velocity via `PointerEvent` and `VelocityTracker` to manually derive squish, bounce, and snap behaviors.
- **Modular Micro-Widgets:** The heavily animated miniplayer is broken down into discrete UI components (controls, image, info) that each ingest fine-grained progress values (`0.0` to `1.0` constraints) to calculate their own interpolation frames independently.

---

## 2. Folder Directory Tree

```
lib/
├── core/
│   └── math_utils.dart
├── main.dart
├── providers/
│   └── will_pop_provider.dart
└── ui/
    ├── miniplayer/
    │   ├── now_playing.dart
    │   └── widgets/
    │       ├── player_controls.dart
    │       ├── queue_view.dart
    │       ├── top_bar.dart
    │       ├── track_image.dart
    │       └── track_info.dart
    └── screens/
        └── navigation_screen.dart
```

---

## 3. Detailed Directory & File Breakdown

### Root Files
* **`lib/main.dart`**
  * **Role:** The entry point of the Flutter application. 
  * **Details:** Wraps the entire application in a `MultiProvider` to initialize global shared states. Configures the overarching `MaterialApp` including dark theme bindings, and sets the home screen to `NavigationScreen`.
  * **State Interactions:** Instantiates and provides the `WillPopProvider`.

### `Core/`
* **`lib/core/math_utils.dart`**
  * **Role:** A collection of pure mathematical utility functions.
  * **Details:** Contains helpers like `rangeProgress`, `progressValue`, and `norm` for mapping ranges and `inverseAboveOne` for generating mirrored bouncing values. Does not contain any UI widgets.
  * **Dependencies/Roles:** Actively referenced by almost every widget in the `miniplayer` to calculate precise layout dimensions, opacities, and offsets based on the user's drag progress.

### `Providers/`
* **`lib/providers/will_pop_provider.dart`**
  * **Role:** App-wide back navigation intercepter.
  * **Details:** A simple, non-notifier class housing a nullable callback `bool Function()? _popper;`. It allows deeply nested widgets to register their own cleanup or dismissal logic whenever the Android back button (or swipe back) is triggered.

### `UI/Screens/`
* **`lib/ui/screens/navigation_screen.dart`**
  * **Role:** The main scaffold and root graphical container.
  * **Details:** Holds the default lower navigation bar and handles a scale-down background animation sequence when the miniplayer expands. Stacks the `NowPlaying` widget fully on top of everything else.
  * **State Interactions:** Uses a `WillPopScope` mapped to a `Consumer<WillPopProvider>` to defensively ask if it should close the app or simply delegate the 'back' event to collapse the active music player.

### `UI/Miniplayer/`
* **`lib/ui/miniplayer/now_playing.dart`**
  * **Role:** The physics engine and orchestrator of the dynamic player panel.
  * **Details:** Managing an expansive list of offset tracking variables and `VelocityTracker` scopes. It translates raw vertical/horizontal panning into distinct phases: deeply collapsed (miniplayer), fully expanded (active track), and over-dragged (showing next queue). It calculates several derived progress multipliers (e.g., `bounceClampedProgressValue`) and distributes them down to modular child widgets.
  * **State Interactions:** Consumes `WillPopProvider` upon layout completion to inject its own `snapToMini()` internal animation controller logic into the app's global back-button stack. Internal widget toggles (like play/pause) rest here inside local `setState()`.

### `UI/Miniplayer/Widgets/`
* **`lib/ui/miniplayer/widgets/player_controls.dart`**
  * **Role:** Renders and animates playback interaction buttons.
  * **Details:** Contains the Play/Pause floating action button, timeline slider, skip, and shuffle buttons. Shifts horizontally and scales down to cram into the miniplayer format, then dramatically fans out when the panel expands.

* **`lib/ui/miniplayer/widgets/queue_view.dart`**
  * **Role:** Renders the "Up Next" scrolling tracks list.
  * **Details:** Normally rendered off-screen. It slides up visually into the viewport via the `queueProgressValue` logic when the user forcefully drags up past the normal bounds of the expanded player.

* **`lib/ui/miniplayer/widgets/top_bar.dart`**
  * **Role:** Header text for the expanded track.
  * **Details:** Fades in "Playing from Mini World" alongside a chevron to natively dismiss the player, entirely opaque only when the panel is fully deployed.

* **`lib/ui/miniplayer/widgets/track_image.dart`**
  * **Role:** Deeply animated album artwork graphic.
  * **Details:** Interpolates bounds significantly based on `rangeProgress()` helpers. Listens to the horizontal `sAnim` controller from `NowPlaying` to apply a parallax displacement effect that visually glides the image left or right faster than the user's thumb during a track skip.

* **`lib/ui/miniplayer/widgets/track_info.dart`**
  * **Role:** Song metadata text display.
  * **Details:** Renders the track name (e.g., "Dernière Danse") and artist alongside a 'Heart' icon. Similarly leverages deep horizontal offsets for swipe inertia parallax matching the `TrackImage`.

---

## 4. State Management Flow

1. **Global Provisioning:** `MultiProvider` sets up `WillPopProvider` in `main.dart`.
2. **System Fallback Injection:** Inside the deeply nested `NowPlaying` widget, a `Consumer<WillPopProvider>` accesses the active instance. During the `addPostFrameCallback`, it registers a closure via `willPop.registerPopper(...)` that inspects the current `offset` of the player. 
    - If `offset > maxOffset / 2` (Player is large), the closure triggers a `snapToMini()` animation and tells the system *not* to exit (`return false`).
    - Otherwise, it allows standard system termination (`return true`).
3. **Execution:** When the user hits back, `NavigationScreen`'s surrounding `WillPopScope` fires. It queries the `WillPopProvider`. Since the player injected its logic there earlier, `NavigationScreen` respects the return value, efficiently collapsing an on-screen modal without using standard Navigator routes.
4. **Local Transient State:** Frame-by-frame UI morphing is kept out of global state. `NowPlaying` manages input via `Listener` and `GestureDetector`, updating local tracking variables (e.g., `offset`, `sOffset`), and imperatively manipulating `AnimationController`s. Surrounding layers rely entirely on `AnimatedBuilder` blocks and derived math constants to redraw their immediate geometric layouts concurrently without triggering full widget-tree rebuilds.
