/// Centralized motion architecture for Nix powered by `motor`.
///
/// Exports all Nix motion tokens, duration constants, physics curves, spring specifications,
/// and re-exports the complete `motor` package API for effortless application-wide motion management.
library;

export 'package:motor/motor.dart';
export 'nix_curves.dart';
export 'nix_durations.dart';
export 'nix_motion_physics.dart';
export 'nix_springs.dart';
