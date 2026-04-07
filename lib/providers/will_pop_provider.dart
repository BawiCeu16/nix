/// A system to register global back-button interception logic.
/// Typically used by the miniplayer to snap down before exiting the app.
class WillPopProvider {
  bool Function()? _popper;

  /// Gets the currently registered back-button handler.
  bool Function()? get handler => _popper;

  void registerPopper(bool Function() value) {
    _popper = value;
  }
}
