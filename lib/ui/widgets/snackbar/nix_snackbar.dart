import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';

enum NixSnackbarPosition { top, bottom }

class NixSnackbar {
  static VoidCallback? _activeDismiss;

  /// Manually dismisses the currently visible NixSnackbar from anywhere.
  static void dismiss() {
    _activeDismiss?.call();
  }

  static void show(
    BuildContext context, {
    Widget? leading,
    required Widget title,
    Widget? subtitle,
    Widget? trailing,
    Widget Function(VoidCallback dismiss)? trailingBuilder,
    NixSnackbarPosition position = NixSnackbarPosition.bottom,
    Duration displayDuration = const Duration(seconds: 3),
    Duration animationDuration = const Duration(milliseconds: 500),
    Curve animationCurve = Curves.easeOutCubic,
    bool isFrosted = false,
    double blurSigmaX = 15.0,
    double blurSigmaY = 15.0,
    Color? backgroundColor, // Keep nullable so it can react dynamically
    double? width,
    EdgeInsetsGeometry margin = const EdgeInsets.all(16.0),
    EdgeInsetsGeometry padding = const EdgeInsets.all(12),
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(16)),
    BoxBorder? border,
    bool enableShadow = false,
    List<BoxShadow>? customShadows,
  }) {
    assert(
      trailing == null || trailingBuilder == null,
      'Cannot provide both trailing and trailingBuilder. Use trailing for normal widgets, or trailingBuilder if you need the local dismiss callback.',
    );

    // Dismiss any currently displayed snackbar before showing a new one
    _activeDismiss?.call();

    final overlayState = Overlay.of(context, rootOverlay: true);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _NixSnackbarOverlay(
        leading: leading,
        title: title,
        subtitle: subtitle,
        trailing: trailing,
        trailingBuilder: trailingBuilder,
        position: position,
        displayDuration: displayDuration,
        animationDuration: animationDuration,
        animationCurve: animationCurve,
        isFrosted: isFrosted,
        blurSigmaX: blurSigmaX,
        blurSigmaY: blurSigmaY,
        backgroundColor: backgroundColor,
        width: width,
        margin: margin,
        padding: padding,
        borderRadius: borderRadius,
        border: border,
        enableShadow: enableShadow,
        customShadows: customShadows,
        onRegisterDismiss: (dismissFn) {
          _activeDismiss = dismissFn;
        },
        onDismissed: () {
          if (_activeDismiss != null) {
            _activeDismiss = null;
          }
          if (overlayEntry.mounted) {
            overlayEntry.remove();
          }
        },
      ),
    );

    overlayState.insert(overlayEntry);
  }
}

class _NixSnackbarOverlay extends StatefulWidget {
  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final Widget Function(VoidCallback dismiss)? trailingBuilder;
  final NixSnackbarPosition position;
  final Duration displayDuration;
  final Duration animationDuration;
  final Curve animationCurve;
  final bool isFrosted;
  final double blurSigmaX;
  final double blurSigmaY;
  final Color? backgroundColor;
  final double? width;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final BoxBorder? border;
  final bool enableShadow;
  final List<BoxShadow>? customShadows;
  final ValueChanged<VoidCallback> onRegisterDismiss;
  final VoidCallback onDismissed;

  const _NixSnackbarOverlay({
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.trailingBuilder,
    required this.position,
    required this.displayDuration,
    required this.animationDuration,
    required this.animationCurve,
    required this.isFrosted,
    required this.blurSigmaX,
    required this.blurSigmaY,
    this.backgroundColor,
    this.width,
    required this.margin,
    required this.padding,
    required this.borderRadius,
    this.border,
    required this.enableShadow,
    this.customShadows,
    required this.onRegisterDismiss,
    required this.onDismissed,
  });

  @override
  State<_NixSnackbarOverlay> createState() => _NixSnackbarOverlayState();
}

class _NixSnackbarOverlayState extends State<_NixSnackbarOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offsetAnimation;
  Timer? _dismissTimer;
  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();
    widget.onRegisterDismiss(dismiss);

    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    final isTop = widget.position == NixSnackbarPosition.top;
    _offsetAnimation =
        Tween<Offset>(
          begin: Offset(0, isTop ? -1.2 : 1.2),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _controller,
            curve: widget.animationCurve,
            reverseCurve: Curves.easeInCubic,
          ),
        );

    _controller.forward();
    _startDismissTimer();
  }

  void _startDismissTimer() {
    _dismissTimer = Timer(widget.displayDuration, dismiss);
  }

  Future<void> dismiss() async {
    if (_isDismissing) return;
    _isDismissing = true;
    _dismissTimer?.cancel();
    await _controller.reverse();
    widget.onDismissed();
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 💡 Fetching the theme directly inside build() means it rebuilds
    // immediately when the app theme toggles.
    final theme = Theme.of(context);
    final isTop = widget.position == NixSnackbarPosition.top;

    // Dynamic background color resolves on rebuild
    final effectiveBgColor =
        widget.backgroundColor ??
        theme.colorScheme.surfaceContainerHighest.withAlpha(255);

    return SafeArea(
      child: Align(
        alignment: isTop ? Alignment.topCenter : Alignment.bottomCenter,
        child: SlideTransition(
          position: _offsetAnimation,
          child: Dismissible(
            key: UniqueKey(),
            direction: isTop ? DismissDirection.up : DismissDirection.down,
            onDismissed: (_) {
              _dismissTimer?.cancel();
              widget.onDismissed();
            },
            child: Container(
              width: widget.width,
              margin: widget.margin,
              decoration: BoxDecoration(
                borderRadius: widget.borderRadius,
                boxShadow: widget.enableShadow
                    ? (widget.customShadows ??
                          [
                            BoxShadow(
                              color: theme.shadowColor.withAlpha(35),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ])
                    : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: widget.isFrosted
                    ? ClipRRect(
                        borderRadius: widget.borderRadius,
                        child: BackdropFilter(
                          filter: ImageFilter.blur(
                            sigmaX: widget.blurSigmaX,
                            sigmaY: widget.blurSigmaY,
                          ),
                          child: _buildContent(theme, effectiveBgColor),
                        ),
                      )
                    : _buildContent(theme, effectiveBgColor),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme, Color bgColor) {
    Widget? actualTrailing;
    if (widget.trailingBuilder != null) {
      actualTrailing = widget.trailingBuilder!(dismiss);
    } else if (widget.trailing != null) {
      actualTrailing = widget.trailing;
    }

    Widget innerContent = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (widget.leading != null) ...[
          IconTheme(
            data: IconThemeData(color: theme.colorScheme.primary, size: 24),
            child: widget.leading!,
          ),
          const SizedBox(width: 16),
        ],
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DefaultTextStyle(
                style: theme.textTheme.titleSmall!.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
                child: widget.title,
              ),
              if (widget.subtitle != null) ...[
                const SizedBox(height: 2),
                DefaultTextStyle(
                  style: theme.textTheme.bodyMedium!.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  child: widget.subtitle!,
                ),
              ],
            ],
          ),
        ),
        if (actualTrailing != null) ...[
          const SizedBox(width: 16),
          actualTrailing,
        ],
      ],
    );

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: widget.borderRadius,
        border: widget.border,
      ),
      padding: widget.padding,
      child: widget.width == null
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [Flexible(child: innerContent)],
            )
          : innerContent,
    );
  }
}
