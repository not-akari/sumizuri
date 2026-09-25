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
  const MigrationRanking({
    required this.verdict,
    required this.ranked,
    this.excluded = 0,
  });

  final MigrationVerdict verdict;

  /// How many candidates the chapter rule ruled out before scoring.
  final int excluded;

  final List<(MigrationCandidate, MigrationScore)> ranked;

  MigrationCandidate? get best => ranked.isEmpty ? null : ranked.first.$1;
}

const foundThreshold = 0.85;
const foundMargin = 0.08;
const reviewThreshold = 0.5;

/// What a candidate's chapter list must look like to be worth migrating to.
enum ChapterRule {
  /// No requirement.
  any,

  /// It lists at least as many chapters as the title has now.
  atLeastAsMany,

  /// Its newest chapter is the same as, or later than, the one the title has.
  atLeastAsNew,

  /// It has the chapter the reader is up to (or beyond it).
  coversProgress,
}

/// How close a title has to be to count as the same one.
enum MatchStrictness { strict, balanced, loose }

/// The user's choices for how a migration search picks and accepts matches.
class MigrationRules {
  const MigrationRules({
    this.chapterRule = ChapterRule.any,
    this.strictness = MatchStrictness.balanced,
    this.autoAccept = true,
    this.preferMoreChapters = false,
  });

  final ChapterRule chapterRule;
  final MatchStrictness strictness;

  /// Whether a clear match is chosen for the user. Off sends every match to review.
  final bool autoAccept;

  /// When several results match about equally well, favour the longest one.
  final bool preferMoreChapters;

  /// The score a match needs to be picked without asking.
  double get foundAt => switch (strictness) {
    MatchStrictness.strict => 0.93,
    MatchStrictness.balanced => foundThreshold,
    MatchStrictness.loose => 0.75,
  };

  /// The score below which a result is not shown at all.
  double get reviewAt => switch (strictness) {
    MatchStrictness.strict => 0.65,
    MatchStrictness.balanced => reviewThreshold,
    MatchStrictness.loose => 0.4,
  };

  MigrationRules copyWith({
    ChapterRule? chapterRule,
    MatchStrictness? strictness,
    bool? autoAccept,
    bool? preferMoreChapters,
  }) => MigrationRules(
    chapterRule: chapterRule ?? this.chapterRule,
    strictness: strictness ?? this.strictness,
    autoAccept: autoAccept ?? this.autoAccept,
    preferMoreChapters: preferMoreChapters ?? this.preferMoreChapters,
  );
}

/// Whether a candidate with the chapter numbers [candidate] satisfies [rule]
/// for [subject]. A candidate whose chapters could not be read cannot show it
/// meets a rule, so it fails any rule but [ChapterRule.any].
bool meetsChapterRule(
  MigrationSubject subject,
  Set<double>? candidate,
  ChapterRule rule,
) {
  if (rule == ChapterRule.any) return true;
  final mine = subject.chapterNumbers;
  if (mine.isEmpty) return true;
  if (candidate == null || candidate.isEmpty) return false;
  switch (rule) {
    case ChapterRule.any:
      return true;
    case ChapterRule.atLeastAsMany:
      return candidate.length >= mine.length;
    case ChapterRule.atLeastAsNew:
      return candidate.reduce(math.max) >= mine.reduce(math.max) - 1e-6;
    case ChapterRule.coversProgress:
      final read = subject.lastReadNumber;
      if (read == null || read <= 0) return true;
      return candidate.reduce(math.max) >= read - 1e-6;
  }
}

MigrationRanking rank(
  MigrationSubject subject,
  List<MigrationCandidate> candidates, {
  int keep = 3,
  MigrationRules rules = const MigrationRules(),
}) {
  final allowed = [
    for (final c in candidates)
      if (meetsChapterRule(subject, c.chapterNumbers, rules.chapterRule)) c,
  ];
  final excluded = candidates.length - allowed.length;
  final scored = [for (final c in allowed) (c, scoreCandidate(subject, c))]
    ..sort((x, y) => y.$2.total.compareTo(x.$2.total));
  final worthShowing = scored
      .where((s) => s.$2.total >= rules.reviewAt)
      .take(keep)
      .toList();
  if (worthShowing.isEmpty) {
    return MigrationRanking(
      verdict: MigrationVerdict.notFound,
      ranked: const [],
      excluded: excluded,
    );
  }
  final best = worthShowing.first.$2.total;
  var ordered = worthShowing;
  bool clear;
  if (rules.preferMoreChapters) {
    // The results that match about as well as the best one are told apart by
    // length, longest first; their small score gaps no longer count against
    // being sure.
    bool nearBest((MigrationCandidate, MigrationScore) s) =>
        s.$2.total >= best - foundMargin;
    final group =
        [
          for (final (i, s) in worthShowing.indexed)
            if (nearBest(s)) (i, s),
        ]..sort((a, b) {
          final byLength = (b.$2.$1.chapterNumbers?.length ?? 0).compareTo(
            a.$2.$1.chapterNumbers?.length ?? 0,
          );
          return byLength != 0 ? byLength : a.$1.compareTo(b.$1);
        });
    ordered = [
      for (final g in group) g.$2,
      for (final s in worthShowing)
        if (!nearBest(s)) s,
    ];
    clear = ordered.first.$2.total >= rules.foundAt;
  } else {
    final runnerUp = worthShowing.length > 1 ? worthShowing[1].$2.total : 0.0;
    clear = best >= rules.foundAt && best - runnerUp >= foundMargin;
  }
  return MigrationRanking(
    verdict: clear && rules.autoAccept
        ? MigrationVerdict.found
        : MigrationVerdict.review,
    ranked: ordered,
    excluded: excluded,
  );
}
