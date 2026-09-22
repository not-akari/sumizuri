class DownloadedChapterRef {
  const DownloadedChapterRef({
    required this.chapterUrl,
    required this.localPath,
  });

  final String chapterUrl;
  final String localPath;
}

class DownloadedEntry {
  const DownloadedEntry({
    required this.entryId,
    required this.title,
    required this.coverUrl,
    required this.customCoverPath,
    required this.chapters,
  });

  final int entryId;
  final String title;
  final String? coverUrl;
  final String? customCoverPath;
  final List<DownloadedChapterRef> chapters;

  /// Whether both lists hold the same entries and chapter counts, in the same order.
  static bool sameLists(List<DownloadedEntry> a, List<DownloadedEntry> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].entryId != b[i].entryId ||
          a[i].chapters.length != b[i].chapters.length) {
        return false;
      }
    }
    return true;
  }
}
