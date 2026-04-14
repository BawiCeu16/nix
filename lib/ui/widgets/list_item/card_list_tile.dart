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
      topLeft: Radius.circular(widget.isFirst ? 12 : 5),
      topRight: Radius.circular(widget.isFirst ? 12 : 5),
      bottomLeft: Radius.circular(widget.isLast ? 12 : 5),
      bottomRight: Radius.circular(widget.isLast ? 12 : 5),
    );

    final targetRadius = _isPressed
        ? BorderRadius.circular(100.0)
        : defaultRadius;
    final targetScale = _isPressed ? 0.98 : 1.0;

    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
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
              contentPadding: widget.contentPadding,
              leading:
                  widget.leading ??
                  (widget.icon != null ? Icon(widget.icon) : null),
              title: Text(widget.title),
              subtitle: widget.subtitle != null
                  ? Text(
                      widget.subtitle!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 4,
                    )
                  : null,
              trailing: widget.trailing,
              // const Icon(FlutterRemix.arrow_right_s_line),
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
        duration: const Duration(milliseconds: 200), vsync: this);
    _iconTurns = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

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
      topLeft: Radius.circular(widget.isFirst ? 12 : 5),
      topRight: Radius.circular(widget.isFirst ? 12 : 5),
      bottomLeft: Radius.circular(widget.isLast && !_isExpanded ? 12 : 5),
      bottomRight: Radius.circular(widget.isLast && !_isExpanded ? 12 : 5),
    );

    final targetRadius =
        _isPressed ? BorderRadius.circular(100.0) : defaultRadius;
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
                  leading: widget.leading ??
                      (widget.icon != null ? Icon(widget.icon) : null),
                  title: Text(
                    widget.title,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: widget.subtitle != null
                      ? Text(
                          widget.subtitle!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
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
