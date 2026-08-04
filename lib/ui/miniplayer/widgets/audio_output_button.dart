import 'package:flutter/material.dart';
import 'package:nix/ui/miniplayer/controllers/audio_output_controller.dart';
import 'package:output_route_selector/output_route_selector.dart';

class AudioOutputButton extends StatefulWidget {
  final Color onSecondary;

  const AudioOutputButton({super.key, required this.onSecondary});

  @override
  State<AudioOutputButton> createState() => _AudioOutputButtonState();
}

class _AudioOutputButtonState extends State<AudioOutputButton> {
  late final AudioOutputController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AudioOutputController()..init();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final label = _controller.getDisplayName();
        final icon = _controller.getIconForDevice();

        return AudioOutputSelector(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10.0,
              vertical: 8.0,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18.0, color: widget.onSecondary),
                const SizedBox(width: 6.0),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13.0,
                    fontWeight: FontWeight.w500,
                    color: widget.onSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
