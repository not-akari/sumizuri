// Reads a Mangayomi ".backup" file: a zip holding one JSON file with the library.
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';

import 'package:sumizuri/features/library/models/library_types.dart';

enum MangayomiItemType {
  manga,
  anime,
  novel;

  static MangayomiItemType fromValue(int? value) => switch (value) {
    1 => MangayomiItemType.anime,
    2 => MangayomiItemType.novel,
    _ => MangayomiItemType.manga,
  };

  MediaType get mediaType => switch (this) {
    MangayomiItemType.manga => MediaType.manga,
    MangayomiItemType.anime => MediaType.anime,
    MangayomiItemType.novel => MediaType.novel,
  };
}

/// Library entry extracted from a Mangayomi backup.
class MangayomiManga {
  const MangayomiManga({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.link,
    required this.source,
    required this.itemType,
    required this.categories,
  });

  final int id;
  final String name;
  final String? imageUrl;
  final String link;
  final String source;
  final MangayomiItemType itemType;

  /// The ids of [MangayomiCategory] this title is in.
  final List<int> categories;
}

class MangayomiCategory {
  const MangayomiCategory({
    required this.id,
    required this.name,
    required this.pos,
    required this.forItemType,
  });

  final int id;
  final String name;
  final int pos;
  final MangayomiItemType forItemType;
}

class MangayomiChapter {
  const MangayomiChapter({
    required this.id,
    required this.mangaId,
    required this.name,
    required this.url,
    required this.dateUpload,
    required this.isRead,
    required this.lastPageRead,
    required this.isBookmarked,
    required this.scanlator,
  });

  final int id;
  final int mangaId;
  final String name;
  final String url;
  final DateTime? dateUpload;
  final bool isRead;

  /// A fraction from 0 to 1 through the chapter, or null when nothing was read.
  final double? lastPageRead;
  final bool isBookmarked;
  final String? scanlator;
}

class MangayomiHistoryEntry {
  const MangayomiHistoryEntry({
    required this.mangaId,
    required this.chapterId,
    required this.date,
  });

  final int mangaId;
  final int chapterId;
  final DateTime? date;
}

/// Data model for an imported Mangayomi backup archive.
class MangayomiBackup {
  const MangayomiBackup({
    required this.manga,
    required this.categories,
    required this.chapters,
    required this.history,
  });

  final List<MangayomiManga> manga;
  final List<MangayomiCategory> categories;
  final List<MangayomiChapter> chapters;
  final List<MangayomiHistoryEntry> history;
}

/// Something in the file could not be read as a Mangayomi backup.
class MangayomiBackupUnreadable implements Exception {
  const MangayomiBackupUnreadable(this.message);

  final String message;

  @override
  String toString() => message;
}

DateTime? _epochMs(Object? value) {
  final ms = switch (value) {
    int n => n,
    String s => int.tryParse(s),
    _ => null,
  };
  return ms == null || ms <= 0 ? null : DateTime.fromMillisecondsSinceEpoch(ms);
}

double? _fraction(Object? value) {
  final text = value is String ? value : null;
  if (text == null || text.isEmpty) return null;
  return double.tryParse(text);
}

/// Reads the one JSON file inside a Mangayomi ".backup" zip.
String _extractJson(File file) {
  final bytes = file.readAsBytesSync();
  final archive = ZipDecoder().decodeBytes(bytes);
  final entry = archive.files.firstWhere(
    (f) => f.isFile && f.name.endsWith('.db'),
    orElse: () => throw const MangayomiBackupUnreadable(
      'This does not look like a Mangayomi backup file.',
    ),
  );
  return utf8.decode(entry.content as List<int>, allowMalformed: true);
}

MangayomiBackup readMangayomiBackup(File file) {
  final Map<String, dynamic> root;
  try {
    root = jsonDecode(_extractJson(file)) as Map<String, dynamic>;
  } on MangayomiBackupUnreadable {
    rethrow;
  } catch (error) {
    throw MangayomiBackupUnreadable('Not a readable Mangayomi backup: $error');
  }

  List<Map<String, dynamic>> list(String key) => [
    for (final item in (root[key] as List? ?? const []))
      (item as Map).cast<String, dynamic>(),
  ];

  final manga = [
    for (final m in list('manga'))
      if (m['favorite'] == true)
        MangayomiManga(
          id: m['id'] as int,
          name: (m['name'] as String?)?.trim() ?? '',
          imageUrl: m['imageUrl'] as String?,
          link: (m['link'] as String?) ?? '',
          source: (m['source'] as String?) ?? '',
          itemType: MangayomiItemType.fromValue(m['itemType'] as int?),
          categories: [
            for (final c in (m['categories'] as List? ?? const [])) c as int,
          ],
        ),
  ];

  final categories = [
    for (final c in list('categories'))
      MangayomiCategory(
        id: c['id'] as int,
        name: (c['name'] as String?)?.trim() ?? '',
        pos: (c['pos'] as int?) ?? 0,
        forItemType: MangayomiItemType.fromValue(c['forItemType'] as int?),
      ),
  ];

  final chapters = [
    for (final c in list('chapters'))
      MangayomiChapter(
        id: c['id'] as int,
        mangaId: c['mangaId'] as int,
        name: (c['name'] as String?)?.trim() ?? '',
        url: (c['url'] as String?) ?? '',
        dateUpload: _epochMs(c['dateUpload']),
        isRead: c['isRead'] == true,
        lastPageRead: _fraction(c['lastPageRead']),
        isBookmarked: c['isBookmarked'] == true,
        scanlator: (c['scanlator'] as String?)?.isEmpty ?? true
            ? null
            : c['scanlator'] as String,
      ),
  ];

  final history = [
    for (final h in list('history'))
      MangayomiHistoryEntry(
        mangaId: h['mangaId'] as int,
        chapterId: h['chapterId'] as int,
        date: _epochMs(h['date']),
      ),
  ];

  return MangayomiBackup(
    manga: manga,
    categories: categories,
    chapters: chapters,
    history: history,
  );
}
