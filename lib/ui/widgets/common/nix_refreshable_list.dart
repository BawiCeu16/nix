import 'package:flutter/material.dart';
import 'package:expressive_refresh/expressive_refresh.dart';

class NixRefreshableList extends StatelessWidget {
  /// Function called when the user pulls to refresh.
  final Future<void> Function() onRefresh;

  /// The scrollable widget (e.g., ListView, GridView, or CustomScrollView).
  /// This widget MUST have `AlwaysScrollableScrollPhysics` (with BouncingScrollPhysics preferred).
  final Widget child;

  /// Optional empty state widget to show when [isEmpty] is true.
  final Widget? emptyState;

  /// Whether the data for this list is currently empty.
  final bool isEmpty;

  const NixRefreshableList({
    super.key,
    required this.onRefresh,
    required this.child,
    this.emptyState,
    this.isEmpty = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isEmpty && emptyState != null) {
      return ExpressiveRefreshIndicator(
        onRefresh: onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - 150,
            ),
            child: Center(child: emptyState!),
          ),
        ),
      );
    }

    return ExpressiveRefreshIndicator(onRefresh: onRefresh, child: child);
  }
}
