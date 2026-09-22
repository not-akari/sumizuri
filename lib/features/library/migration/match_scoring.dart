import 'dart:math' as math;

class MigrationSubject {
  const MigrationSubject({
    required this.title,
    this.author,
    this.chapterNumbers = const {},
    this.lastReadNumber,
  });

  final String title;
  final String? author;

  final Set<double> chapterNumbers;

  final double? lastReadNumber;
}

class MigrationCandidate {
  const MigrationCandidate({
    required this.title,
    this.author,
    this.chapterNumbers,
  });

  final String title;
  final String? author;

  final Set<double>? chapterNumbers;
}

class MigrationScore {
  const MigrationScore({
    required this.total,
    required this.title,
    required this.chapters,
  });

  final double total;
  final double title;

  final double? chapters;
}

enum MigrationVerdict {
  /// A clear match: safe to move without asking.
  found,

  review,

  notFound,
}

const _noise = {
  'official',
  'uncensored',
  'colored',
  'colorized',
  'raw',
  'webtoon',
  'manga',
  'novel',
  'the',
};

String normalizeTitle(String title) {
  var s = title.toLowerCase();
  s = s.replaceAll(RegExp(r'\([^)]*\)|\[[^\]]*\]|\{[^}]*\}'), ' ');
  s = _stripAccents(s);
  s = s.replaceAll(RegExp(r'[^\p{L}\p{N}\s]', unicode: true), ' ');
  final words = [
    for (final w in s.split(RegExp(r'\s+')))
      if (w.isNotEmpty && !_noise.contains(w)) w,
  ];
  return words.join(' ');
}

const _accents = {
  'à': 'a',
  'á': 'a',
  'â': 'a',
  'ã': 'a',
  'ä': 'a',
  'å': 'a',
  'ç': 'c',
  'è': 'e',
  'é': 'e',
  'ê': 'e',
  'ë': 'e',
  'ì': 'i',
  'í': 'i',
  'î': 'i',
  'ï': 'i',
  'ñ': 'n',
  'ò': 'o',
  'ó': 'o',
  'ô': 'o',
  'õ': 'o',
  'ö': 'o',
  'ø': 'o',
  'ù': 'u',
  'ú': 'u',
  'û': 'u',
  'ü': 'u',
  'ý': 'y',
  'ÿ': 'y',
  'ß': 'ss',
};

String _stripAccents(String s) =>
    s.split('').map((c) => _accents[c] ?? c).join();

double editSimilarity(String a, String b) {
  if (a.isEmpty && b.isEmpty) return 1;
  if (a.isEmpty || b.isEmpty) return 0;
  var previous = List<int>.generate(b.length + 1, (i) => i);
  for (var i = 1; i <= a.length; i++) {
    final current = List<int>.filled(b.length + 1, 0)..[0] = i;
    for (var j = 1; j <= b.length; j++) {
      final cost = a[i - 1] == b[j - 1] ? 0 : 1;
      current[j] = math.min(
        math.min(current[j - 1] + 1, previous[j] + 1),
        previous[j - 1] + cost,
      );
    }
    previous = current;
  }
  return 1 - previous[b.length] / math.max(a.length, b.length);
}

double _wordOverlap(String a, String b) {
  final x = a.split(' ').where((w) => w.isNotEmpty).toSet();
  final y = b.split(' ').where((w) => w.isNotEmpty).toSet();
  if (x.isEmpty || y.isEmpty) return 0;
  return x.intersection(y).length / x.union(y).length;
}

final _number = RegExp(r'\d+');

double titleSimilarity(String a, String b) {
  final x = normalizeTitle(a);
  final y = normalizeTitle(b);
  if (x.isEmpty || y.isEmpty) return 0;
  if (x == y) return 1;
  var score = math.max(editSimilarity(x, y), _wordOverlap(x, y));
  if (x.contains(y) || y.contains(x)) score = math.max(score, 0.8);
  final numbersX = _number.allMatches(x).map((m) => m.group(0)).toSet();
  final numbersY = _number.allMatches(y).map((m) => m.group(0)).toSet();
  if (numbersX.length != numbersY.length || !numbersX.containsAll(numbersY)) {
    score *= 0.55;
  }
  return score.clamp(0.0, 1.0);
}

double? chapterFit(MigrationSubject subject, Set<double>? candidate) {
  if (candidate == null || candidate.isEmpty) return null;
  if (subject.chapterNumbers.isEmpty) return null;
  bool has(double n) => candidate.any((c) => (c - n).abs() < 1e-6);
  final shared =
      subject.chapterNumbers.where(has).length / subject.chapterNumbers.length;
  final read = subject.lastReadNumber;
  if (read != null &&
      read > 0 &&
      !has(read) &&
      candidate.reduce(math.max) < read) {
    return shared * 0.4;
  }
  return shared;
}

MigrationScore scoreCandidate(
  MigrationSubject subject,
  MigrationCandidate candidate,
) {
  var title = titleSimilarity(subject.title, candidate.title);
  final a = subject.author?.trim().toLowerCase();
  final b = candidate.author?.trim().toLowerCase();
  // Two different named authors make a match doubtful, and agreeing authors help a little.
  if (a != null && b != null && a.isNotEmpty && b.isNotEmpty) {
    title = a == b ? math.min(1, title + 0.05) : title * 0.8;
  }
  final chapters = chapterFit(subject, candidate.chapterNumbers);
  final total = chapters == null ? title : 0.6 * title + 0.4 * chapters;
  return MigrationScore(total: total, title: title, chapters: chapters);
}

class MigrationRanking {
  const MigrationRanking({required this.verdict, required this.ranked});

  final MigrationVerdict verdict;

  final List<(MigrationCandidate, MigrationScore)> ranked;

  MigrationCandidate? get best => ranked.isEmpty ? null : ranked.first.$1;
}

const foundThreshold = 0.85;
const foundMargin = 0.08;
const reviewThreshold = 0.5;

MigrationRanking rank(
  MigrationSubject subject,
  List<MigrationCandidate> candidates, {
  int keep = 3,
}) {
  final scored = [for (final c in candidates) (c, scoreCandidate(subject, c))]
    ..sort((x, y) => y.$2.total.compareTo(x.$2.total));
  final worthShowing = scored
      .where((s) => s.$2.total >= reviewThreshold)
      .take(keep)
      .toList();
  if (worthShowing.isEmpty) {
    return const MigrationRanking(
      verdict: MigrationVerdict.notFound,
      ranked: [],
    );
  }
  final best = worthShowing.first.$2.total;
  final runnerUp = worthShowing.length > 1 ? worthShowing[1].$2.total : 0.0;
  final clear = best >= foundThreshold && best - runnerUp >= foundMargin;
  return MigrationRanking(
    verdict: clear ? MigrationVerdict.found : MigrationVerdict.review,
    ranked: worthShowing,
  );
}
