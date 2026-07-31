import 'package:flutter_test/flutter_test.dart';
import 'package:nix/ui/controllers/padding_controller.dart';

void main() {
  group('PaddingController', () {
    test('calculates correct horizontal list padding for first item (index 0)', () {
      final padding = PaddingController.getHorizontalListPadding(
        index: 0,
        length: 5,
      );

      expect(padding.left, 12.0);
      expect(padding.right, 8.0);
    });

    test('calculates correct horizontal list padding for middle items', () {
      final padding = PaddingController.getHorizontalListPadding(
        index: 2,
        length: 5,
      );

      expect(padding.left, 0.0);
      expect(padding.right, 8.0);
    });

    test('calculates correct horizontal list padding for last item', () {
      final padding = PaddingController.getHorizontalListPadding(
        index: 4,
        length: 5,
      );

      expect(padding.left, 0.0);
      expect(padding.right, 12.0);
    });

    test('calculates correct horizontal list padding when length is 1 (first and last)', () {
      final padding = PaddingController.getHorizontalListPadding(
        index: 0,
        length: 1,
      );

      expect(padding.left, 12.0);
      expect(padding.right, 12.0);
    });

    test('supports custom outer and inner padding values', () {
      final padding = PaddingController.getHorizontalListPadding(
        index: 0,
        length: 3,
        outer: 16.0,
        inner: 8.0,
      );

      expect(padding.left, 16.0);
      expect(padding.right, 8.0);
    });
  });
}
