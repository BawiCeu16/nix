import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:hive/hive.dart';

class UserProvider with ChangeNotifier {
  Box get _box => Hive.box('settings');

  // Nickname
  String get userName => _box.get('username', defaultValue: 'Nix User');
  void setUserName(String name) {
    _box.put('username', name);
    notifyListeners();
  }

  // Avatar Index
  int get avatarIndex => _box.get('avatarIndex', defaultValue: 0);
  void setAvatarIndex(int index) {
    _box.put('avatarIndex', index);
    notifyListeners();
  }

  // Shared Avatar Data for Consistency
  static const List<Color> avatarColors = [
    Colors.blue,
    Colors.pink,
    Colors.orange,
    Colors.green,
    Colors.purple,
    Colors.red,
  ];

  static const List<IconData> avatarIcons = [
    FlutterRemix.user_3_line,
    FlutterRemix.user_5_line,
    FlutterRemix.user_6_line,
    FlutterRemix.user_smile_line,
    FlutterRemix.ghost_line,
    FlutterRemix.robot_line,
  ];
}
