// Defines the interface every source extension implementation must provide.
import 'package:sumizuri/core/errors/app_failure.dart';
import 'package:sumizuri/core/errors/result.dart';
import 'package:sumizuri/features/extensions/models/filter_group.dart';
import 'package:sumizuri/features/extensions/models/m_chapter.dart';
import 'package:sumizuri/features/extensions/models/m_comment.dart';
import 'package:sumizuri/features/extensions/models/m_entry.dart';
import 'package:sumizuri/features/extensions/models/m_page.dart';
import 'package:sumizuri/features/extensions/models/m_video.dart';
import 'package:sumizuri/features/extensions/models/m_source_info.dart';
import 'package:sumizuri/features/extensions/models/source_preference.dart';

enum CommentSort { newest, oldest, top }

typedef ExtensionCapabilities = ({
  bool hasDetails,
  bool hasComments,
  bool hasChapterComments,
  bool hasFilters,
  bool hasPreferences,
  int? rateLimitMs,
  Map<String, String>? defaultHeaders,
});

abstract interface class ExtensionService {
  MSourceInfo get info;

  int? get rateLimitMs;

  Map<String, String>? get defaultHeaders;

  Future<Result<List<MEntry>, AppFailure>> search(
    String query, {
    int page = 1,
    Map<String, dynamic>? filters,
  });

  Future<Result<List<MEntry>, AppFailure>> getPopular({int page});

  Future<Result<List<MEntry>, AppFailure>> getLatest({int page});

  Future<Result<List<MChapter>, AppFailure>> getChapterList(MEntry entry);

  Future<Result<List<MPage>, AppFailure>> getPageList(MChapter chapter);

  Future<Result<List<MVideo>, AppFailure>> getVideoList(MChapter chapter);

  Future<Result<MEntry, AppFailure>> getDetails(MEntry entry);

  Future<Result<List<MComment>, AppFailure>> getComments(
    MEntry entry, {
    CommentSort sort = CommentSort.newest,
  });

  Future<Result<List<MComment>, AppFailure>> getChapterComments(
    MChapter chapter, {
    CommentSort sort = CommentSort.newest,
  });

  Future<Result<List<FilterGroup>, AppFailure>> getFilters();

  Future<Result<List<SourcePreference>, AppFailure>> getSourcePreferences();

  Future<Result<ExtensionCapabilities, AppFailure>> readCapabilities();

  Future<Result<Map<String, dynamic>, AppFailure>> getPreferences();

  Future<Result<void, AppFailure>> setPreference(String key, dynamic value);

  Future<Result<void, AppFailure>> setPreferences(Map<String, dynamic> values);

  Future<void> dispose();
}
