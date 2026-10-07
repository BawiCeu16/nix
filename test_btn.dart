import 'package:flutter/material.dart';
import 'package:m3e_buttons/m3e_buttons.dart';

void main() {
  M3EFilledButton.tonal(
    size: M3EButtonSize.custom(width: double.infinity),
    onPressed: () {},
    child: Text('test'),
  );
}
