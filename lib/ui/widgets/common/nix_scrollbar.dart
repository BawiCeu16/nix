import 'package:flutter/material.dart';

/// A premium, themed scrollbar widget for Nix.
///
/// Wraps any scrollable child with a sleek, auto-fading scrollbar that
/// matches the app's Material 3 color scheme. Manages its own
/// [ScrollController] by default, or accepts an external one.
///
/// Usage:
/// ```dart
/// NixScrollbar(
///   child: ListView.builder(...),
/// )
/// ```
class NixScrollbar extends StatefulWidget {
  /// The scrollable child widget.
  final Widget child;

  /// Optional external scroll controller. When provided, the widget
  /// will NOT create or dispose its own controller — the caller owns it.
  final ScrollController? controller;

  /// Thickness of the scrollbar track when idle.
  final double thickness;

  /// Thickness of the scrollbar track when being interacted with.
  final double thicknessWhileDragging;

  /// Radius of the scrollbar thumb corners.
  final Radius radius;

  /// Whether the scrollbar thumb is always visible (no auto-fade).
  final bool thumbAlwaysVisible;

  /// Minimum length of the scrollbar thumb.
  final double? minThumbLength;

  /// Whether to enable interactive scrollbar dragging.
  final bool interactive;

  const NixScrollbar({
    super.key,
    required this.child,
    this.controller,
    this.thickness = 3.0,
    this.thicknessWhileDragging = 6.0,
    this.radius = const Radius.circular(100),
    this.thumbAlwaysVisible = false,
    this.minThumbLength,
    this.interactive = true,
  });

  @override
  State<NixScrollbar> createState() => _NixScrollbarState();
}

class _NixScrollbarState extends State<NixScrollbar> {
  ScrollController? _ownController;

  ScrollController get _effectiveController =>
      widget.controller ?? (_ownController ??= ScrollController());

  @override
  void dispose() {
    _ownController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ScrollbarTheme(
      data: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.dragged)) {
            return colorScheme.primary.withValues(alpha: 0.7);
          }
          if (states.contains(WidgetState.hovered)) {
            return colorScheme.primary.withValues(alpha: 0.5);
          }
          return colorScheme.onSurface.withValues(alpha: 0.2);
        }),
        trackColor: WidgetStateProperty.all(Colors.transparent),
        trackBorderColor: WidgetStateProperty.all(Colors.transparent),
        thickness: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.dragged) ||
              states.contains(WidgetState.hovered)) {
            return widget.thicknessWhileDragging;
          }
          return widget.thickness;
        }),
        radius: widget.radius,
        minThumbLength: widget.minThumbLength ?? 48.0,
        crossAxisMargin: 4.0,
        mainAxisMargin: 4.0,
      ),
      child: Scrollbar(
        controller: _effectiveController,
        thumbVisibility: widget.thumbAlwaysVisible,
        interactive: widget.interactive,
        child: _applyController(widget.child),
      ),
    );
  }

  /// Injects the effective ScrollController into the child if it's a
  /// known scrollable type that needs one. For generic children the
  /// controller is already bound to the [Scrollbar] via
  /// [PrimaryScrollController].
  Widget _applyController(Widget child) {
    // If the caller already provided their own controller we assume
    // the child is already wired up.
    if (widget.controller != null) return child;

    // Use PrimaryScrollController to propagate the controller to the child.
    return PrimaryScrollController(
      controller: _effectiveController,
      child: child,
    );
  }
}
