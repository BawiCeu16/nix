import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';

class NixSortMenuItem<T> {
  final T value;
  final String label;

  const NixSortMenuItem({required this.value, required this.label});
}

class NixSortWidget<T> extends StatelessWidget {
  final T currentSort;
  final List<NixSortMenuItem<T>> items;
  final void Function(T) onSortSelected;
  final bool isAscending;
  final VoidCallback onToggleOrder;

  const NixSortWidget({
    super.key,
    required this.currentSort,
    required this.items,
    required this.onSortSelected,
    required this.isAscending,
    required this.onToggleOrder,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(
            isAscending ? FlutterRemix.sort_asc : FlutterRemix.sort_desc,
          ),
          tooltip: isAscending ? 'Ascending' : 'Descending',
          onPressed: onToggleOrder,
        ),
        PopupMenuButton<T>(
          icon: const Icon(FlutterRemix.filter_3_line),
          tooltip: 'Sort by',
          initialValue: currentSort,
          onSelected: onSortSelected,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: colorScheme.surfaceContainerHigh,
          elevation: 0,
          clipBehavior: Clip.antiAlias,
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
          menuPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
          itemBuilder: (context) {
            return items.map((item) {
              final isSelected = item.value == currentSort;
              return PopupMenuItem<T>(
                value: item.value,
                child: Text(
                  item.label,
                  style: TextStyle(
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurface,
                  ),
                ),
              );
            }).toList();
          },
        ),
      ],
    );
  }
}
