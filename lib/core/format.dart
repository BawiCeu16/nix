extension DurationFormat on Duration {
  String format() {
    return "${inHours > 0 ? '$inHours h ' : ''}${inMinutes % 60} mins";
  }

  String shortFormat() {
    return "${inHours > 0 ? '$inHours:' : ''}${(inMinutes % 60).toString().padLeft(inHours > 0 ? 2 : 0, '0')}:${(inSeconds % 60).toString().padLeft(2, '0')}";
  }
}

extension FileSizeFormat on num {
  String formatBytes() {
    if (this <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = 0;
    var size = toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return "${size.toStringAsFixed(1)} ${suffixes[i]}";
  }
}
