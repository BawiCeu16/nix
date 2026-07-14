import 'package:flutter/foundation.dart';

class WillPopProvider with ChangeNotifier {
  bool Function()? _popper;

  /// Gets the currently registered back-button handler.
  bool Function()? get handler {
    debugPrint(
      "WillPopProvider: Getting handler. Current is null: ${_popper == null}",
    );
    return _popper;
  }

  void registerPopper(bool Function()? value) {
    debugPrint(
      "WillPopProvider: Registering popper. Value is null: ${value == null}",
    );
    if (_popper != value) {
      _popper = value;
      notifyListeners();
    }
  }
}
