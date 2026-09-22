/// Remembers each page's aspect so a loading page reserves its real height.
class PageAspectCache {
  PageAspectCache._();

  static final instance = PageAspectCache._();

  static const _limit = 4000;
  static const _recentCount = 24;
  static const _firstGuess = 2.0;

  final _aspects = <String, double>{};
  final _recent = <double>[];

  /// Height divided by width, or null when the page has not been seen yet.
  double? of(String imageUrl) => _aspects[imageUrl];

  /// The height to expect from an unseen page: the middle of the latest seen.
  double get guess {
    if (_recent.isEmpty) return _firstGuess;
    final sorted = [..._recent]..sort();
    return sorted[sorted.length ~/ 2];
  }

  /// [of] when known, otherwise [guess].
  double aspectOrGuess(String? imageUrl) =>
      (imageUrl == null ? null : _aspects[imageUrl]) ?? guess;

  /// Stores what was measured and says whether it was new or different.
  bool record(String imageUrl, double aspect) {
    if (!aspect.isFinite || aspect <= 0) return false;
    final known = _aspects.remove(imageUrl);
    _aspects[imageUrl] = aspect;
    if (_aspects.length > _limit) _aspects.remove(_aspects.keys.first);
    if (known == null) {
      _recent.add(aspect);
      if (_recent.length > _recentCount) _recent.removeAt(0);
    }
    return known == null || (known - aspect).abs() > 0.001;
  }
}
