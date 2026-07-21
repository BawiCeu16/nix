import 'package:flutter/material.dart';
import 'package:nix/providers/settings_provider.dart';
import 'package:nix/models/settings/timer_gesture.dart';
import 'package:nix/ui/widgets/dialogs/nix_dialog.dart';
import 'package:nix/ui/widgets/tiles/card_list_tile.dart';

class GesturesSettingsController extends ChangeNotifier {
  void showTrackSwipeActionDialog(
    BuildContext context,
    SettingsProvider settings,
  ) {
    NixDialog.show(
      context: context,
      title: 'Track Swipe Action',
      children: [
        RadioGroup<TrackSwipeAction>(
          groupValue: settings.trackSwipeAction,
          onChanged: (action) {
            if (action != null) {
              settings.setTrackSwipeAction(action);
              Navigator.of(context, rootNavigator: true).pop();
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: TrackSwipeAction.values.map((action) {
              final index = TrackSwipeAction.values.indexOf(action);
              String description = '';
              switch (action) {
                case TrackSwipeAction.none:
                  description = 'Disable swipe actions on library tracks';
                  break;
                case TrackSwipeAction.playPlayback:
                  description = 'Swipe to Play (Idle) or Play Next (Playing)';
                  break;
              }

              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == TrackSwipeAction.values.length - 1
                      ? 0.0
                      : 2.5,
                ),
                child: CardListTile(
                  title: action == TrackSwipeAction.none
                      ? 'NONE'
                      : 'PLAY / PLAY NEXT',
                  subtitle: description,
                  onTap: () {
                    settings.setTrackSwipeAction(action);
                    Navigator.of(context, rootNavigator: true).pop();
                  },
                  trailing: IgnorePointer(
                    child: Radio<TrackSwipeAction>(value: action),
                  ),
                  isFirst: index == 0,
                  isLast: index == TrackSwipeAction.values.length - 1,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  void showSnackBarPositionDialog(
    BuildContext context,
    SettingsProvider settings,
  ) {
    NixDialog.show(
      context: context,
      title: 'SnackBar Position',
      children: [
        RadioGroup<SnackBarPosition>(
          groupValue: settings.snackbarPosition,
          onChanged: (position) {
            if (position != null) {
              settings.setSnackbarPosition(position);
              Navigator.of(context, rootNavigator: true).pop();
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: SnackBarPosition.values.map((position) {
              final index = SnackBarPosition.values.indexOf(position);
              String description = '';
              switch (position) {
                case SnackBarPosition.top:
                  description = 'Show alerts at the top of the screen';
                  break;
                case SnackBarPosition.bottom:
                  description = 'Show alerts at the bottom of the screen';
                  break;
              }

              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == SnackBarPosition.values.length - 1
                      ? 0.0
                      : 2.5,
                ),
                child: CardListTile(
                  title: position.name.toUpperCase(),
                  subtitle: description,
                  onTap: () {
                    settings.setSnackbarPosition(position);
                    Navigator.of(context, rootNavigator: true).pop();
                  },
                  trailing: IgnorePointer(
                    child: Radio<SnackBarPosition>(value: position),
                  ),
                  isFirst: index == 0,
                  isLast: index == SnackBarPosition.values.length - 1,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  void showTimerGestureDialog(
    BuildContext context,
    SettingsProvider settings,
  ) {
    NixDialog.show(
      context: context,
      title: 'Timer Interaction',
      children: [
        RadioGroup<TimerGesture>(
          groupValue: settings.timerGesture,
          onChanged: (gesture) {
            if (gesture != null) {
              settings.setTimerGesture(gesture);
              Navigator.of(context, rootNavigator: true).pop();
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: TimerGesture.values.map((gesture) {
              final index = TimerGesture.values.indexOf(gesture);
              String description = '';
              switch (gesture) {
                case TimerGesture.tap:
                  description = 'Single tap to open timer';
                  break;
                case TimerGesture.longPress:
                  description = 'Long press to avoid accidental touches';
                  break;
              }

              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == TimerGesture.values.length - 1
                      ? 0.0
                      : 2.5,
                ),
                child: CardListTile(
                  title: gesture.name.toUpperCase(),
                  subtitle: description,
                  onTap: () {
                    settings.setTimerGesture(gesture);
                    Navigator.of(context, rootNavigator: true).pop();
                  },
                  trailing: IgnorePointer(
                    child: Radio<TimerGesture>(value: gesture),
                  ),
                  isFirst: index == 0,
                  isLast: index == TimerGesture.values.length - 1,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
