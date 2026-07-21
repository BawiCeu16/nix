import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:nix/providers/settings_provider.dart';
import 'package:nix/models/settings/artwork_quality.dart';
import 'package:nix/ui/widgets/dialogs/nix_dialog.dart';
import 'package:nix/ui/widgets/tiles/card_list_tile.dart';

class AppearanceSettingsController extends ChangeNotifier {
  void showShapeDialog(BuildContext context, SettingsProvider settings) {
    NixDialog.show(
      context: context,
      title: 'Artwork Shape',
      children: [
        RadioGroup<ArtworkShape>(
          groupValue: settings.artworkShape,
          onChanged: (shape) {
            if (shape != null) {
              settings.setArtworkShape(shape);
              Navigator.of(context, rootNavigator: true).pop();
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: ArtworkShape.values.map((shape) {
              final index = ArtworkShape.values.indexOf(shape);
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == ArtworkShape.values.length - 1 ? 0.0 : 2.5,
                ),
                child: CardListTile(
                  title: shape.name.toUpperCase(),
                  onTap: () {
                    settings.setArtworkShape(shape);
                    Navigator.of(context, rootNavigator: true).pop();
                  },
                  trailing: IgnorePointer(
                    child: Radio<ArtworkShape>(value: shape),
                  ),
                  isFirst: index == 0,
                  isLast: index == ArtworkShape.values.length - 1,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  void showQualityDialog(BuildContext context, SettingsProvider settings) {
    final qualities = NixArtworkQuality.values.reversed.toList();
    NixDialog.show(
      context: context,
      title: 'Artwork Quality',
      children: [
        RadioGroup<NixArtworkQuality>(
          groupValue: settings.artworkQuality,
          onChanged: (quality) {
            if (quality != null) {
              settings.setArtworkQuality(quality);
              Navigator.of(context, rootNavigator: true).pop();
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: qualities.map((quality) {
              final index = qualities.indexOf(quality);
              String description = '';
              switch (quality) {
                case NixArtworkQuality.high:
                  description = 'Full-high quality - Best visuals';
                  break;
                case NixArtworkQuality.medium:
                  description = 'Balanced quality';
                  break;
                case NixArtworkQuality.low:
                  description = 'Standard quality - Saves memory';
                  break;
              }

              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == qualities.length - 1 ? 0.0 : 2.5,
                ),
                child: CardListTile(
                  title: quality.name.toUpperCase(),
                  subtitle: description,
                  onTap: () {
                    settings.setArtworkQuality(quality);
                    Navigator.of(context, rootNavigator: true).pop();
                  },
                  trailing: IgnorePointer(
                    child: Radio<NixArtworkQuality>(value: quality),
                  ),
                  isFirst: index == 0,
                  isLast: index == qualities.length - 1,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  void showAccentModeDialog(BuildContext context, SettingsProvider settings) {
    NixDialog.show(
      context: context,
      title: ' Accent Color Mode',
      children: [
        RadioGroup<AccentColorMode>(
          groupValue: settings.accentColorMode,
          onChanged: (mode) {
            if (mode != null) {
              settings.setAccentColorMode(mode);
              Navigator.of(context, rootNavigator: true).pop();
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: AccentColorMode.values.map((mode) {
              final index = AccentColorMode.values.indexOf(mode);
              String label = mode.name.toUpperCase();
              if (mode == AccentColorMode.dynamic) {
                label = "DYNAMIC (ALBUM ART)";
              }

              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == AccentColorMode.values.length - 1
                      ? 0.0
                      : 2.5,
                ),
                child: CardListTile(
                  title: label,
                  onTap: () {
                    settings.setAccentColorMode(mode);
                    Navigator.of(context, rootNavigator: true).pop();
                  },
                  trailing: IgnorePointer(
                    child: Radio<AccentColorMode>(value: mode),
                  ),
                  isFirst: index == 0,
                  isLast: index == AccentColorMode.values.length - 1,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  void showResetCdSpeedDialog(BuildContext context, SettingsProvider settings) {
    NixDialog.show(
      context: context,
      title: 'Reset Speed',
      subtitle: 'Reset CD rotation speed to default 20%?',
      children: [
        CardListTile(
          title: 'Reset',
          icon: FlutterRemix.check_line,
          isFirst: true,
          isLast: true,
          onTap: () {
            settings.setCdRotationSpeed(20.0);
            Navigator.of(context, rootNavigator: true).pop();
          },
        ),
      ],
    );
  }
}
