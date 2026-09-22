import 'dart:io';

import 'package:sumizuri/core/errors/app_failure.dart';
import 'package:sumizuri/core/errors/result.dart';
import 'package:sumizuri/features/extensions/data/extension_service.dart';
import 'package:sumizuri/features/extensions/data/local/local_library.dart';
import 'package:sumizuri/features/extensions/models/filter_group.dart';
import 'package:sumizuri/features/extensions/models/installed_source.dart';
import 'package:sumizuri/features/extensions/models/m_chapter.dart';
import 'package:sumizuri/features/extensions/models/m_comment.dart';
import 'package:sumizuri/features/extensions/models/m_entry.dart';
import 'package:sumizuri/features/extensions/models/m_page.dart';
import 'package:sumizuri/features/extensions/models/m_source_info.dart';
import 'package:sumizuri/features/extensions/models/m_video.dart';
import 'package:sumizuri/features/extensions/models/source_preference.dart';

/// A source that reads a folder on the device: CBZ, pictures, EPUB and text files.
class LocalExtensionService implements ExtensionService {
  LocalExtensionService(this.info, this._library);

  factory LocalExtensionService.forSource(
    MSourceInfo info,
    AppInstalledSource source,
    Directory cache,
  ) => LocalExtensionService(
    info,
    LocalLibrary(root: source.baseUrl, type: source.mediaType, cache: cache),
  );

  static const _pageSize = 40;

  @override
  final MSourceInfo info;

  final LocalLibrary _library;

  @override
  int? get rateLimitMs => null;

  Future<Result<T, AppFailure>> _guard<T>(Future<T> Function() body) async {
    try {
      return Ok(await body());
    } on Object catch (error) {
      return Err(ExtensionFailure('Could not read the folder: $error'));
    }
  }

  Future<List<MEntry>> _page(List<FileSystemEntity> titles, int page) async {
    final start = (page - 1) * _pageSize;
    if (start < 0 || start >= titles.length) return const [];
    final slice = titles.skip(start).take(_pageSize);
    return [for (final title in slice) await _library.entryFor(title)];
  }

  @override
  Future<Result<List<MEntry>, AppFailure>> getPopular({int page = 1}) =>
      _guard(() => _page(_library.titles(), page));

  @override
  Future<Result<List<MEntry>, AppFailure>> getLatest({int page = 1}) =>
      _guard(() {
        final titles = _library.titles()
          ..sort(
            (a, b) => b.statSync().modified.compareTo(a.statSync().modified),
          );
        return _page(titles, page);
      });

  @override
  Future<Result<List<MEntry>, AppFailure>> search(
    String query, {
    int page = 1,
    Map<String, dynamic>? filters,
  }) => _guard(() {
    final needle = query.trim().toLowerCase();
    final titles = [
      for (final t in _library.titles())
        if (needle.isEmpty || t.path.toLowerCase().contains(needle)) t,
    ];
    return _page(titles, page);
  });

  @override
  Future<Result<MEntry, AppFailure>> getDetails(MEntry entry) =>
      _guard(() => _library.detailsOf(entry.url));

  @override
  Future<Result<List<MChapter>, AppFailure>> getChapterList(MEntry entry) =>
      _guard(() => _library.chaptersOf(entry.url));

  @override
  Future<Result<List<MPage>, AppFailure>> getPageList(MChapter chapter) =>
      _guard(() => _library.pagesOf(chapter.url));

  @override
  Future<Result<List<MVideo>, AppFailure>> getVideoList(
    MChapter chapter,
  ) async => const Err(NotImplementedFailure('A local folder has no videos.'));

  @override
  Future<Result<List<MComment>, AppFailure>> getComments(
    MEntry entry, {
    CommentSort sort = CommentSort.newest,
  }) async => const Ok([]);

  @override
  Future<Result<List<MComment>, AppFailure>> getChapterComments(
    MChapter chapter, {
    CommentSort sort = CommentSort.newest,
  }) async => const Ok([]);

  @override
  Future<Result<List<FilterGroup>, AppFailure>> getFilters() async =>
      const Ok([]);

  @override
  Future<Result<List<SourcePreference>, AppFailure>>
  getSourcePreferences() async => const Ok([]);

  @override
  Future<Result<ExtensionCapabilities, AppFailure>> readCapabilities() async =>
      const Ok((
        hasDetails: true,
        hasComments: false,
        hasChapterComments: false,
        hasFilters: false,
        hasPreferences: false,
        rateLimitMs: null,
      ));

  @override
  Future<Result<Map<String, dynamic>, AppFailure>> getPreferences() async =>
      const Ok({});

  @override
  Future<Result<void, AppFailure>> setPreference(
    String key,
    dynamic value,
  ) async => const Ok(null);

  @override
  Future<Result<void, AppFailure>> setPreferences(
    Map<String, dynamic> values,
  ) async => const Ok(null);

  @override
  Future<void> dispose() async {}
}
