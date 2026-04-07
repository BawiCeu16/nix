/// Maps a progress value `c` (0.0 to 1.0) intuitively between `a` and `b`.
double rangeProgress({
  required double a,
  required double b,
  required double c,
}) {
  return a + (b - a) * c;
}

/// Normalizes a value `x` between range `y` and `z` into a 0.0 to 1.0 fraction.
double progressValue({
  required double min,
  required double max,
  required double value,
}) {
  return (value - min) / (max - min);
}

/// Normalizes numbers down, typically used for scaling text or bounds natively.
double norm(
  double val,
  double minVal,
  double maxVal,
  double newMin,
  double newMax,
) {
  return newMin + (val - minVal) * (newMax - newMin) / (maxVal - minVal);
}

/// Clamps and mirrors a progress value around 1.0 to create a bounce effect.
double inverseAboveOne(double n) {
  if (n > 1) return (1 - (1 - n) * -1);
  return n;
}
