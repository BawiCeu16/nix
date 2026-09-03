import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';

class CardListTile extends StatefulWidget {
  const CardListTile({
    super.key,
    required this.title,
    this.icon,
    this.leading,
    required this.onTap,
    this.onLongPress,
    this.subtitle,
    this.trailing,
    this.isFirst = false,
    this.isLast = false,
    this.isSelected = false,
    this.contentPadding,
  });

  final String title;
  final IconData? icon;
  final Widget? leading;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final String? subtitle;
  final Widget? trailing;
  final bool isFirst;
  final bool isLast;
  final bool isSelected;
  final EdgeInsetsGeometry? contentPadding;

  @override
  State<CardListTile> createState() => _CardListTileState();
}

class _CardListTileState extends State<CardListTile> {
  bool _isPressed = false;

  void _setPressed(bool pressed) {
    if (_isPressed != pressed) {
      if (mounted) setState(() => _isPressed = pressed);
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

    final targetRadius = (_isPressed || widget.isSelected)
        ? BorderRadius.circular(100.0)
        : defaultRadius;
    final targetScale = _isPressed ? 0.98 : 1.0;

    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor = widget.isSelected
        ? colorScheme.primaryContainer
        : colorScheme.surface;
    final onPrimaryContainer = colorScheme.onPrimaryContainer;
    final onSurface = colorScheme.onSurface;
    final onSurfaceVariant = colorScheme.onSurfaceVariant;

    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: AnimatedScale(
        scale: targetScale,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: targetRadius,
          ),
          clipBehavior: Clip.antiAlias,
          child: Material(
            color: Colors.transparent,
            child: ListTile(
              contentPadding: widget.contentPadding,
              leading:
                  widget.leading ??
                  (widget.icon != null
                      ? AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOutCubic,
                          child: Icon(
                            widget.icon,
                            color: widget.isSelected
                                ? onPrimaryContainer
                                : null,
                          ),
                        )
                      : null),
              title: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: widget.isSelected
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: widget.isSelected ? onPrimaryContainer : onSurface,
                ),
                child: Text(widget.title),
              ),
              subtitle: widget.subtitle != null
                  ? AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      style: TextStyle(
                        fontSize: 14,
                        color: widget.isSelected
                            ? onPrimaryContainer.withValues(alpha: 0.8)
                            : onSurfaceVariant,
                      ),
                      child: Text(widget.subtitle!, maxLines: 4),
                    )
                  : null,
              trailing: widget.trailing,
              onTap: widget.onTap,
              onLongPress: widget.onLongPress,
            ),
          ),
        ),
      ),
    );
  }
}

class NixCardExpansionTile extends StatefulWidget {
  const NixCardExpansionTile({
    super.key,
    required this.title,
    this.icon,
    this.leading,
    this.trailing,
    required this.children,
    this.subtitle,
    this.isFirst = false,
    this.isLast = false,
    this.initiallyExpanded = false,
    this.showExpansionIcon = true,
  });

  final String title;
  final IconData? icon;
  final Widget? leading;
  final Widget? trailing;
  final List<Widget> children;
  final String? subtitle;
  final bool isFirst;
  final bool isLast;
  final bool initiallyExpanded;
  final bool showExpansionIcon;

  @override
  State<NixCardExpansionTile> createState() => _NixCardExpansionTileState();
}

class _NixCardExpansionTileState extends State<NixCardExpansionTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _iconTurns;

  bool _isExpanded = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _iconTurns = Tween<double>(
      begin: 0.0,
      end: 0.5,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _isExpanded = widget.initiallyExpanded;
    if (_isExpanded) _controller.value = 1.0;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setPressed(bool pressed) {
    if (_isPressed != pressed && mounted) {
      setState(() => _isPressed = pressed);
    }
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final defaultRadius = BorderRadius.only(
      topLeft: Radius.circular(widget.isFirst ? 16 : 5),
      topRight: Radius.circular(widget.isFirst ? 16 : 5),
      bottomLeft: Radius.circular(widget.isLast && !_isExpanded ? 16 : 5),
      bottomRight: Radius.circular(widget.isLast && !_isExpanded ? 16 : 5),
    );

    final targetRadius = _isPressed
        ? BorderRadius.circular(100.0)
        : defaultRadius;
    final targetScale = _isPressed ? 0.98 : 1.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTapDown: (_) => _setPressed(true),
          onTapUp: (_) => _setPressed(false),
          onTapCancel: () => _setPressed(false),
          onTap: _toggleExpansion,
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
                child: ListTile(
                  leading:
                      widget.leading ??
                      (widget.icon != null ? Icon(widget.icon) : null),
                  title: Text(
                    widget.title,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: widget.subtitle != null
                      ? Text(
                          widget.subtitle!,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        )
                      : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.trailing != null) ...[
                        widget.trailing!,
                        const SizedBox(width: 8),
                      ],
                      if (widget.showExpansionIcon) ...[
                        RotationTransition(
                          turns: _iconTurns,
                          child: const Icon(FlutterRemix.arrow_down_s_line),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        SizeTransition(
          sizeFactor: _controller,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: widget.children,
          ),
        ),
      ],
    );
  }
}

class CardListTileWithChild extends StatefulWidget {
  const CardListTileWithChild({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.leading,
    this.topRightChild,
    this.child,
    this.onTap,
    this.onLongPress,
    this.isFirst = false,
    this.isLast = false,
    this.isSelected = false,
    this.contentPadding,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? leading;
  final Widget? topRightChild;
  final Widget? child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isFirst;
  final bool isLast;
  final bool isSelected;
  final EdgeInsetsGeometry? contentPadding;

  @override
  State<CardListTileWithChild> createState() => _CardListTileWithChildState();
}

class _CardListTileWithChildState extends State<CardListTileWithChild> {
  bool _isPressed = false;

  void _setPressed(bool pressed) {
    if (_isPressed != pressed && widget.onTap != null) {
      if (mounted) setState(() => _isPressed = pressed);
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

    final targetRadius = (_isPressed || widget.isSelected)
        ? BorderRadius.circular(100.0)
        : defaultRadius;
    final targetScale = _isPressed ? 0.98 : 1.0;

    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor = widget.isSelected
        ? colorScheme.primaryContainer
        : colorScheme.surface;
    final onPrimaryContainer = colorScheme.onPrimaryContainer;
    final onSurface = colorScheme.onSurface;
    final onSurfaceVariant = colorScheme.onSurfaceVariant;

    return GestureDetector(
      onTapDown: widget.onTap != null ? (_) => _setPressed(true) : null,
      onTapUp: widget.onTap != null ? (_) => _setPressed(false) : null,
      onTapCancel: widget.onTap != null ? () => _setPressed(false) : null,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedScale(
        scale: targetScale,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: targetRadius,
          ),
          clipBehavior: Clip.antiAlias,
          child: Material(
            color: Colors.transparent,
            child: Padding(
              padding: widget.contentPadding ??
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (widget.leading != null) ...[
                        widget.leading!,
                        const SizedBox(width: 12),
                      ] else if (widget.icon != null) ...[
                        Icon(
                          widget.icon,
                          color: widget.isSelected ? onPrimaryContainer : null,
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: widget.isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: widget.isSelected
                                    ? onPrimaryContainer
                                    : onSurface,
                              ),
                            ),
                            if (widget.subtitle != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                widget.subtitle!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: widget.isSelected
                                      ? onPrimaryContainer.withValues(alpha: 0.8)
                                      : onSurfaceVariant,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (widget.topRightChild != null) ...[
                        const SizedBox(width: 8),
                        widget.topRightChild!,
                      ],
                    ],
                  ),
                  if (widget.child != null) ...[
                    const SizedBox(height: 12),
                    widget.child!,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
