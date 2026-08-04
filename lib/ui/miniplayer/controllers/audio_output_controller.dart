import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:output_route_selector/output_route_selector.dart';

class AudioOutputController extends ChangeNotifier {
  AudioModel? activeDevice;
  StreamSubscription<AudioModel?>? _routeSubscription;

  void init() {
    _initAudioDetection();
  }

  void _initAudioDetection() {
    try {
      _routeSubscription = OutputRouteSelector.instance.onAudioRouteChanged
          .listen((device) {
            activeDevice = device;
            notifyListeners();
          });
    } catch (e) {
      debugPrint('[AudioOutputController] Detection init error: $e');
    }
  }

  bool isBluetooth(AudioDeviceType? type) {
    if (type == null) return false;
    return type == AudioDeviceType.bluetooth || type == AudioDeviceType.airpods;
  }

  IconData getIconForDevice() {
    if (activeDevice != null) {
      if (isBluetooth(activeDevice!.deviceType)) {
        return FlutterRemix.bluetooth_line;
      }
      if (activeDevice!.deviceType == AudioDeviceType.wiredHeadset) {
        return FlutterRemix.headphone_line;
      }
    }
    return FlutterRemix.volume_up_line;
  }

  String getDisplayName() {
    if (activeDevice == null) return 'System Speaker';
    if (activeDevice!.deviceType == AudioDeviceType.speaker ||
        activeDevice!.deviceType == AudioDeviceType.receiver) {
      return 'System Speaker';
    }
    final name = activeDevice!.outputName.trim();
    if (name.isEmpty || name.toLowerCase() == 'unknown') {
      return 'System Speaker';
    }
    return name;
  }

  @override
  void dispose() {
    _routeSubscription?.cancel();
    super.dispose();
  }
}
