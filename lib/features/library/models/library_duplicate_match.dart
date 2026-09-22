// Plain data models describing a possible duplicate when adding an entry to the library.
class LibraryDuplicateCandidate {
  const LibraryDuplicateCandidate({
    required this.id,
    required this.title,
    required this.coverUrl,
    required this.sourceId,
  });

  final int id;
  final String title;
  final String? coverUrl;
  final String sourceId;
}

class LibraryMatch {
  const LibraryMatch({this.exactMatchId, this.otherSourceMatches = const []});

  final int? exactMatchId;

  final List<LibraryDuplicateCandidate> otherSourceMatches;

  bool get isExactMatch => exactMatchId != null;
  bool get hasPossibleDuplicates => otherSourceMatches.isNotEmpty;
}
