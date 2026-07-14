import 'package:flutter/foundation.dart';

class WillPopProvider {
  bool Function()? _popper;

  /// Gets the currently registered back-button handler.
  bool Function()? get handler {
    debugPrint("WillPopProvider: Getting handler. Current is null: ${_popper == null}");
    return _popper;
  }

  void registerPopper(bool Function()? value) {
    debugPrint("WillPopProvider: Registering popper. Value is null: ${value == null}");
    _popper = value;
  }
}
