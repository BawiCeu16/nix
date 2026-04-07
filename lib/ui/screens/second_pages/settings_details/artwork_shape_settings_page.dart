import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_m3shapes_extended/flutter_m3shapes_extended.dart';
import 'package:provider/provider.dart';
import '../../../../providers/settings_provider.dart';
import '../../../widgets/list_item/card_list_tile.dart';

class ArtworkShapeSettingsPage extends StatelessWidget {
  const ArtworkShapeSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsParams = context.watch<SettingsProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainer,
      appBar: AppBar(
        title: const Text('Artwork Shapes'),
        backgroundColor: colorScheme.surfaceContainer,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        physics: const BouncingScrollPhysics(),
        itemCount: ArtworkShape.values.length,
        itemBuilder: (context, index) {
          final shape = ArtworkShape.values[index];
          String label = shape.name.toUpperCase();
          if (shape == ArtworkShape.verySunny) label = "VERY SUNNY";
          if (shape == ArtworkShape.pixelCircle) label = "PIXEL CIRCLE";
          if (shape == ArtworkShape.cookie4) label = "4 SIDED COOKIE";
          if (shape == ArtworkShape.cookie6) label = "6 SIDED COOKIE";
          if (shape == ArtworkShape.cookie9) label = "9 SIDED COOKIE";
          if (shape == ArtworkShape.cookie12) label = "12 SIDED COOKIE";

          final isFirst = index == 0;
          final isLast = index == ArtworkShape.values.length - 1;

          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0.0 : 2.5),
            child: CardListTile(
              title: label,
              leading: _ShapePreview(shape: shape),
              onTap: () => settingsParams.setArtworkShape(shape),
              trailing: IgnorePointer(
                child: Radio<ArtworkShape>(
                  value: shape,
                  groupValue: settingsParams.artworkShape,
                  onChanged: (_) {},
                ),
              ),
              isFirst: isFirst,
              isLast: isLast,
            ),
          );
        },
      ),
    );
  }
}

class _ShapePreview extends StatelessWidget {
  final ArtworkShape shape;
  const _ShapePreview({required this.shape});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
      ),
      child: _getPreviewShape(context),
    );
  }

  Widget _getPreviewShape(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final icon = Icon(
      FlutterRemix.image_2_line,
      size: 16,
      color: colorScheme.onSecondaryContainer.withValues(alpha: 0.5),
    );

    switch (shape) {
      case ArtworkShape.arch:
        return M3EContainer.arch(
          width: 32,
          height: 32,
          color: colorScheme.secondaryContainer,
          clipBehavior: Clip.antiAlias,
          child: icon,
        );
      case ArtworkShape.oval:
        return M3EContainer.oval(
          width: 32,
          height: 32,
          color: colorScheme.secondaryContainer,
          clipBehavior: Clip.antiAlias,
          child: icon,
        );
      case ArtworkShape.pill:
        return M3EContainer.pill(
          width: 32,
          height: 32,
          color: colorScheme.secondaryContainer,
          clipBehavior: Clip.antiAlias,
          child: icon,
        );
      case ArtworkShape.diamond:
        return M3EContainer.diamond(
          width: 32,
          height: 32,
          color: colorScheme.secondaryContainer,
          clipBehavior: Clip.antiAlias,
          child: icon,
        );
      case ArtworkShape.gem:
        return M3EContainer.gem(
          width: 32,
          height: 32,
          color: colorScheme.secondaryContainer,
          clipBehavior: Clip.antiAlias,
          child: icon,
        );
      case ArtworkShape.verySunny:
        return M3EContainer.verySunny(
          width: 32,
          height: 32,
          color: colorScheme.secondaryContainer,
          clipBehavior: Clip.antiAlias,
          child: icon,
        );
      case ArtworkShape.sunny:
        return M3EContainer.sunny(
          width: 32,
          height: 32,
          color: colorScheme.secondaryContainer,
          clipBehavior: Clip.antiAlias,
          child: icon,
        );
      case ArtworkShape.cookie4:
        return M3EContainer.c4SidedCookie(
          width: 32,
          height: 32,
          color: colorScheme.secondaryContainer,
          clipBehavior: Clip.antiAlias,
          child: icon,
        );
      case ArtworkShape.cookie6:
        return M3EContainer.c6SidedCookie(
          width: 32,
          height: 32,
          color: colorScheme.secondaryContainer,
          clipBehavior: Clip.antiAlias,
          child: icon,
        );
      case ArtworkShape.cookie9:
        return M3EContainer.c9SidedCookie(
          width: 32,
          height: 32,
          color: colorScheme.secondaryContainer,
          clipBehavior: Clip.antiAlias,
          child: icon,
        );
      case ArtworkShape.cookie12:
        return M3EContainer.c12SidedCookie(
          width: 32,
          height: 32,
          color: colorScheme.secondaryContainer,
          clipBehavior: Clip.antiAlias,
          child: icon,
        );
      case ArtworkShape.pixelCircle:
        return M3EContainer.pixelCircle(
          width: 32,
          height: 32,
          color: colorScheme.secondaryContainer,
          clipBehavior: Clip.antiAlias,
          child: icon,
        );
      case ArtworkShape.bun:
        return M3EContainer.bun(
          width: 32,
          height: 32,
          color: colorScheme.secondaryContainer,
          clipBehavior: Clip.antiAlias,
          child: icon,
        );
      case ArtworkShape.circle:
        return ClipOval(child: icon);
      default:
        return ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: icon,
        );
    }
  }
}
