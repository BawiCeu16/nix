import 'package:flutter/material.dart';

/// A utility controller for calculating dynamic padding across UI lists and carousels.
/// Can be used anywhere in the app to apply consistent spacing rules based on item indices.
class PaddingController {
  /// Calculates dynamic horizontal padding for items in a horizontal list.
  ///
  /// - First item (`index == 0`) gets [outer] left padding and [inner] right padding.
  /// - Last item (`index == length - 1`) gets 0.0 left padding and [outer] right padding.
  /// - Items in between get 0.0 left padding and [inner] right padding so total spacing between items is [inner].
  static EdgeInsets getHorizontalListPadding({
    required int index,
    required int length,
    double outer = 12.0,
    double inner = 8.0,
  }) {
    final double left = (index == 0) ? outer : 0.0;
    final double right = (index == length - 1) ? outer : inner;
    return EdgeInsets.only(left: left, right: right);
  }

  /// Alias for [getHorizontalListPadding].
  static EdgeInsets horizontal({
    required int index,
    required int length,
    double outer = 12.0,
    double inner = 8.0,
  }) => getHorizontalListPadding(
    index: index,
    length: length,
    outer: outer,
    inner: inner,
  );

  /// Calculates dynamic vertical padding for items in a vertical list.
  ///
  /// - First item (`index == 0`) gets [outer] top padding and [inner] bottom padding.
  /// - Last item (`index == length - 1`) gets 0.0 top padding and [outer] bottom padding.
  /// - Items in between get 0.0 top padding and [inner] bottom padding so total spacing between items is [inner].
  static EdgeInsets getVerticalListPadding({
    required int index,
    required int length,
    double outer = 12.0,
    double inner = 8.0,
  }) {
    final double top = (index == 0) ? outer : 0.0;
    final double bottom = (index == length - 1) ? outer : inner;
    return EdgeInsets.only(top: top, bottom: bottom);
  }

  /// Alias for [getVerticalListPadding].
  static EdgeInsets vertical({
    required int index,
    required int length,
    double outer = 12.0,
    double inner = 8.0,
  }) => getVerticalListPadding(
    index: index,
    length: length,
    outer: outer,
    inner: inner,
  );

  /// Calculates dynamic padding for items in a list along a given [axis].
  static EdgeInsets getListPadding({
    required int index,
    required int length,
    Axis axis = Axis.horizontal,
    double outer = 12.0,
    double inner = 8.0,
  }) {
    if (axis == Axis.vertical) {
      return getVerticalListPadding(
        index: index,
        length: length,
        outer: outer,
        inner: inner,
      );
    }
    return getHorizontalListPadding(
      index: index,
      length: length,
      outer: outer,
      inner: inner,
    );
  }

  /// Alias for [getListPadding].
  static EdgeInsets listPadding({
    required int index,
    required int length,
    Axis axis = Axis.horizontal,
    double outer = 12.0,
    double inner = 8.0,
  }) => getListPadding(
    index: index,
    length: length,
    axis: axis,
    outer: outer,
    inner: inner,
  );

  /// Returns the leading padding math double (left for horizontal, top for vertical).
  static double getLeadingPadding({required int index, double outer = 12.0}) {
    return (index == 0) ? outer : 0.0;
  }

  /// Returns the trailing padding math double (right for horizontal, bottom for vertical).
  static double getTrailingPadding({
    required int index,
    required int length,
    double outer = 12.0,
    double inner = 8.0,
  }) {
    return (index == length - 1) ? outer : inner;
  }
}
