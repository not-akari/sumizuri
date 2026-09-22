import 'package:sumizuri/features/extensions/models/m_chapter.dart';

String formatChapterNumber(double? number) {
  if (number == null) return '';
  return number == number.roundToDouble()
      ? number.toInt().toString()
      : number.toString();
}

double? parseChapterNumber(String title) {
  final regex = RegExp(
    r'(?:(?:chapter|ch\.|ch|episode|ep\.|ep|#)\s*|^)(\d+(?:\.\d+)?)',
    caseSensitive: false,
  );
  final match = regex.firstMatch(title);
  if (match != null) {
    return double.tryParse(match.group(1)!);
  }
  final anyNum = RegExp(r'\b(\d+(?:\.\d+)?)\b').firstMatch(title);
  if (anyNum != null) {
    return double.tryParse(anyNum.group(1)!);
  }
  return null;
}

List<MChapter> sortChapters(
  List<MChapter> chapters, {
  required bool ascending,
}) {
  final sorted = [...chapters];
  sorted.sort((a, b) {
    final an = a.number ?? parseChapterNumber(a.title);
    final bn = b.number ?? parseChapterNumber(b.title);
    if (an != null && bn != null) {
      final cmp = an.compareTo(bn);
      if (cmp != 0) return ascending ? cmp : -cmp;
    } else if (an != null) {
      return ascending ? -1 : 1;
    } else if (bn != null) {
      return ascending ? 1 : -1;
    }

    if (a.dateUploaded != null && b.dateUploaded != null) {
      final cmp = a.dateUploaded!.compareTo(b.dateUploaded!);
      if (cmp != 0) return ascending ? cmp : -cmp;
    }
    return 0;
  });
  return sorted;
}
