import 'package:hive/hive.dart';
import 'package:nix/core/hive_keys.dart';

/// Manages User profile metadata persistence in Hive.
class UserRepository {
  Box get _box => Hive.box(HiveKeys.settingsBox);

  /// User nickname
  String get userName => _box.get(HiveKeys.username, defaultValue: 'Nix User');
  Future<void> setUserName(String name) => _box.put(HiveKeys.username, name);
}
