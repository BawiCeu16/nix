import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';

class CardListTile extends StatefulWidget {
  const CardListTile({
    super.key,
    required this.title,
    this.icon,
    this.leading,
    required this.onTap,
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
                    )
                  : null,
              trailing:
                  widget.trailing ??
                  const Icon(FlutterRemix.arrow_right_s_line),
              onTap: widget.onTap,
            ),
          ),
        ),
      ),
    );
  }
}

class CardExpansionTile extends StatelessWidget {
  const CardExpansionTile({
    super.key,
    required this.title,
    this.icon,
    this.leading,
    required this.children,
    this.subtitle,
    this.isFirst = false,
    this.isLast = false,
    this.initiallyExpanded = false,
  });

  final String title;
  final IconData? icon;
  final Widget? leading;
  final List<Widget> children;
  final String? subtitle;
  final bool isFirst;
  final bool isLast;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.only(
      topLeft: Radius.circular(isFirst ? 12 : 5),
      topRight: Radius.circular(isFirst ? 12 : 5),
      bottomLeft: Radius.circular(isLast ? 12 : 5),
      bottomRight: Radius.circular(isLast ? 12 : 5),
    );

    return Card(
      elevation: 0,
      margin: EdgeInsetsGeometry.zero,
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
      color: Theme.of(context).colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          shape: const RoundedRectangleBorder(side: BorderSide.none),
          collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
          leading: leading ?? (icon != null ? Icon(icon) : null),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          initiallyExpanded: initiallyExpanded,
          subtitle: subtitle != null
              ? Text(
                  subtitle!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                )
              : null,
          expandedAlignment: Alignment.topCenter,
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          children: children,
        ),
      ),
    );
  }
}
