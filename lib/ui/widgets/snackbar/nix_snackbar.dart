import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:provider/provider.dart';
import 'package:nix/providers/current_music_provider.dart';

enum NixSnackBarType { success, error, info, warning }

class NixSnackBar extends StatelessWidget {
  final String message;
  final NixSnackBarType type;
  final Widget? trailing;
  final VoidCallback? onTrailingPressed;

  const NixSnackBar({
    super.key,
    required this.message,
    this.type = NixSnackBarType.info,
    this.trailing,
    this.onTrailingPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Color backgroundColor;
    IconData icon;
    Color iconColor;

    switch (type) {
      case NixSnackBarType.success:
        backgroundColor = colorScheme.primaryContainer;
        icon = FlutterRemix.checkbox_circle_fill;
        iconColor = colorScheme.primary;
        break;
      case NixSnackBarType.error:
        backgroundColor = colorScheme.errorContainer;
        icon = FlutterRemix.error_warning_fill;
        iconColor = colorScheme.error;
        break;
      case NixSnackBarType.warning:
        backgroundColor = Colors.yellowAccent.withValues(
          alpha: 0.2,
        ); // Custom warm color
        icon = FlutterRemix.alert_fill;
        iconColor = Colors.yellowAccent;
        break;
      case NixSnackBarType.info:
      default:
        backgroundColor = colorScheme.secondaryContainer;
        icon = FlutterRemix.information_fill;
        iconColor = colorScheme.secondary;
        break;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate the available width for text
        // padding(16*2) + icon(24) + spacing(12) + optional trailing
        double availableWidth = constraints.maxWidth - 32 - 24 - 12;
        if (trailing != null) {
          availableWidth -= 16; // rough estimate for trailing
        }

        final textStyle = textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        );

        final textPainter = TextPainter(
          text: TextSpan(text: message, style: textStyle),
          maxLines: 3,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: availableWidth);

        // Get actual line count
        final lines = textPainter.computeLineMetrics().length;

        // Dynamic radius: Pill for 1 line, reduced for more
        double radius;
        if (lines <= 1) {
          radius = 100; // Pill
        } else if (lines == 2) {
          radius = 28;
        } else {
          radius = 20;
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(radius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: textStyle,
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 8), trailing!],
            ],
          ),
        );
      },
    );
  }

  /// Shows a [NixSnackBar] using the provided [context].
  /// [position] determines if it's shown at the top or bottom.
  static void show(
    BuildContext context, {
    required String message,
    NixSnackBarType type = NixSnackBarType.info,
    Widget? trailing,
    Duration duration = const Duration(seconds: 3),
    bool isTop = false,
    bool isDismissible = true,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _NixSnackBarOverlay(
        message: message,
        type: type,
        trailing: trailing,
        duration: duration,
        isTop: isTop,
        isDismissible: isDismissible,
        onDismiss: () {
          if (overlayEntry.mounted) {
            overlayEntry.remove();
          }
        },
      ),
    );

    overlay.insert(overlayEntry);
  }
}

class _NixSnackBarOverlay extends StatefulWidget {
  final String message;
  final NixSnackBarType type;
  final Widget? trailing;
  final Duration duration;
  final bool isTop;
  final bool isDismissible;
  final VoidCallback onDismiss;

  const _NixSnackBarOverlay({
    required this.message,
    required this.type,
    this.trailing,
    required this.duration,
    required this.isTop,
    required this.isDismissible,
    required this.onDismiss,
  });

  @override
  State<_NixSnackBarOverlay> createState() => _NixSnackBarOverlayState();
}

class _NixSnackBarOverlayState extends State<_NixSnackBarOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  bool _isDismissed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: widget.isTop ? const Offset(0, -1.5) : const Offset(0, 1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();

    Future.delayed(widget.duration, () {
      if (mounted && !_isDismissed) {
        _controller.reverse().then((_) {
          if (mounted && !_isDismissed) {
            _isDismissed = true;
            widget.onDismiss();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDismiss() {
    if (!_isDismissed) {
      _isDismissed = true;
      widget.onDismiss();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CurrentMusicProvider>(
      builder: (context, music, child) {
        final bool showMiniPlayer = music.showMiniPlayer;

        // Dynamic bottom offset
        // If top: padding top + 20
        // If bottom: padding bottom + 100 (if miniplayer) or 32 (if no miniplayer)
        final double? top = widget.isTop
            ? MediaQuery.of(context).padding.top + 20
            : null;
        final double? bottom = widget.isTop
            ? null
            : MediaQuery.of(context).padding.bottom +
                  (showMiniPlayer ? 100 : 32);

        Widget content = Material(
          color: Colors.transparent,
          child: NixSnackBar(
            message: widget.message,
            type: widget.type,
            trailing: widget.trailing,
          ),
        );

        if (widget.isDismissible) {
          content = Dismissible(
            key: UniqueKey(),
            direction: widget.isTop
                ? DismissDirection.up
                : DismissDirection.down,
            onDismissed: (_) => _handleDismiss(),
            child: content,
          );
        }

        return Positioned(
          top: top,
          bottom: bottom,
          left: 16,
          right: 16,
          child: SlideTransition(position: _offsetAnimation, child: content),
        );
      },
    );
  }
}
