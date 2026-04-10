import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nix/providers/settings_provider.dart';
import 'package:nix/ui/widgets/snackbar/nix_snackbar.dart';

class SnackBarService {
  static void show(
    BuildContext context,
    String message, {
    NixSnackBarType type = NixSnackBarType.info,
    Widget? trailing,
  }) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final bool isTop = settings.snackbarPosition == SnackBarPosition.top;
    final bool isDismissible = settings.snackbarSwipeToDismiss;

    NixSnackBar.show(
      context,
      message: message,
      type: type,
      trailing: trailing,
      isTop: isTop,
      isDismissible: isDismissible,
    );
  }

  static void success(
    BuildContext context,
    String message, {
    Widget? trailing,
  }) {
    show(context, message, type: NixSnackBarType.success, trailing: trailing);
  }

  static void error(BuildContext context, String message, {Widget? trailing}) {
    show(context, message, type: NixSnackBarType.error, trailing: trailing);
  }

  static void warning(
    BuildContext context,
    String message, {
    Widget? trailing,
  }) {
    show(context, message, type: NixSnackBarType.warning, trailing: trailing);
  }

  static void info(BuildContext context, String message, {Widget? trailing}) {
    show(context, message, type: NixSnackBarType.info, trailing: trailing);
  }
}

extension SnackBarExtension on BuildContext {
  void showSnackBar(
    String message, {
    NixSnackBarType type = NixSnackBarType.info,
    Widget? trailing,
  }) {
    SnackBarService.show(this, message, type: type, trailing: trailing);
  }

  void showSuccessSnackBar(String message, {Widget? trailing}) {
    SnackBarService.success(this, message, trailing: trailing);
  }

  void showErrorSnackBar(String message, {Widget? trailing}) {
    SnackBarService.error(this, message, trailing: trailing);
  }

  void showWarningSnackBar(String message, {Widget? trailing}) {
    SnackBarService.warning(this, message, trailing: trailing);
  }

  void showInfoSnackBar(String message, {Widget? trailing}) {
    SnackBarService.info(this, message, trailing: trailing);
  }
}
