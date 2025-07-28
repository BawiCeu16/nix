import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProvider with ChangeNotifier {
  String? _username;
  bool _isLoading = true;

  String? get username => _username;
  bool get isLoading => _isLoading;

  UserProvider() {
    _init();
  }

  Future<void> _init() async {
    await _loadUsername();
  }

  Future<void> _loadUsername() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _username = prefs.getString('username');
    } catch (e) {
      debugPrint("Error loading username: $e");
    } finally {
      _isLoading = false;
      notifyListeners(); // ✅ Make sure UI updates
    }
  }

  Future<void> saveUsername(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', name);
    _username = name;
    notifyListeners();
  }
}
