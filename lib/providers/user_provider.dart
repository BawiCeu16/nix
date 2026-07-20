import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:nix/services/user_repository.dart';

/// Manages User metadata state and delegates persistence to [UserRepository].
class UserProvider with ChangeNotifier {
  final UserRepository _repo = UserRepository();

  // Nickname
  String get userName => _repo.userName;
  void setUserName(String name) {
    _repo.setUserName(name).then((_) => notifyListeners());
  }

  // Avatar Index
  int get avatarIndex => _repo.avatarIndex;
  void setAvatarIndex(int index) {
    _repo.setAvatarIndex(index).then((_) => notifyListeners());
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
