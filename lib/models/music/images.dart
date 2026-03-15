class Images {
  final Map<String, String> sources;

  Images({required this.sources});

  String? get defaultImage => sources['default'];
}
