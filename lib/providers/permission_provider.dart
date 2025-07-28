import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class PermissionProvider with ChangeNotifier {
  bool storageGranted = false;
  bool bluetoothGranted = false;
  bool isLoading = true;

  PermissionProvider() {
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    storageGranted = await _hasStoragePermission();
    bluetoothGranted = await Permission.bluetooth.isGranted;
    isLoading = false;
    notifyListeners();
  }

  Future<bool> _hasStoragePermission() async {
    if (Platform.isAndroid) {
      if (await Permission.audio.isGranted) return true; // Android 13+
      if (await Permission.storage.isGranted) return true; // Older
    }
    return false;
  }

  Future<void> requestStorage() async {
    if (Platform.isAndroid) {
      final status = await Permission.audio.request();
      if (status.isGranted) {
        storageGranted = true;
      } else {
        final fallback = await Permission.storage.request();
        storageGranted = fallback.isGranted;
      }
    }
    notifyListeners();
  }

  Future<void> requestBluetooth() async {
    final status = await Permission.bluetooth.request();
    bluetoothGranted = status.isGranted;
    notifyListeners();
  }

  bool get allGranted => storageGranted && bluetoothGranted;

  Future<void> savePermissionsCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('permissionsGranted', true);
  }

  static Future<bool> isPermissionsCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('permissionsGranted') ?? false;
  }
}
