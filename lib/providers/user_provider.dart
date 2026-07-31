import 'package:flutter/material.dart';
import 'package:nix/services/user_repository.dart';

/// Manages User metadata state and delegates persistence to [UserRepository].
class UserProvider with ChangeNotifier {
  final UserRepository _repo = UserRepository();

  // Nickname
  String get userName => _repo.userName;
  void setUserName(String name) {
    _repo.setUserName(name).then((_) => notifyListeners());
  }
}
