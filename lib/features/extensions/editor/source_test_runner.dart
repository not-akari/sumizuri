import 'package:sumizuri/bootstrap/logging/app_logger.dart';
import 'package:sumizuri/core/errors/app_failure.dart';
import 'package:sumizuri/core/errors/result.dart';
import 'package:sumizuri/features/extensions/data/engines/js/js_extension_service.dart';
import 'package:sumizuri/features/extensions/editor/debug_report.dart';
import 'package:sumizuri/features/extensions/models/filter_group.dart';
import 'package:sumizuri/features/extensions/models/m_chapter.dart';
import 'package:sumizuri/features/extensions/models/m_comment.dart';
import 'package:sumizuri/features/extensions/models/m_entry.dart';
import 'package:sumizuri/features/extensions/models/m_page.dart';
import 'package:sumizuri/features/extensions/models/m_source_info.dart';
import 'package:sumizuri/features/extensions/models/m_video.dart';
import 'package:sumizuri/features/extensions/models/source_preference.dart';

enum SourceTestMethod {
  search,
  getPopular,
  getLatest,
  getChapterList,
  getPageList,
  getVideoList,
  getDetails,
  getComments,
  getChapterComments,
  getFilters,
  getSourcePreferences;

  bool get needsQuery => this == SourceTestMethod.search;
  bool get needsPage =>
      this == SourceTestMethod.search ||
      this == SourceTestMethod.getPopular ||
      this == SourceTestMethod.getLatest;
  bool get needsUrl =>
      this == SourceTestMethod.getChapterList ||
      this == SourceTestMethod.getPageList ||
      this == SourceTestMethod.getVideoList ||
      this == SourceTestMethod.getDetails ||
      this == SourceTestMethod.getComments ||
      this == SourceTestMethod.getChapterComments;
}

/// What one test run of a source produced.
class SourceTestRun {
  const SourceTestRun({
    required this.output,
    required this.trace,
    required this.took,
  });

  final String output;
  final List<TraceEntry> trace;
  final Duration took;
}

/// Loads the source, calls one method and returns its formatted output and request trace.
Future<SourceTestRun> runSourceTest({
  required MSourceInfo info,
  required String sourceCode,
  required AppLogger logger,
  required SourceTestMethod method,
  required String query,
  required String url,
  required int page,
}) async {
  final watch = Stopwatch()..start();
  final loadResult = await JsExtensionService.load(
    info,
    sourceCode,
    logger: logger,
    callTimeout: const Duration(seconds: 20),
    isTesting: true,
  );
  final service = loadResult.valueOrNull;
  if (service == null) {
    return SourceTestRun(
      output: 'Load failed: ${loadResult.errorOrNull!.displayMessage}',
      trace: const [],
      took: watch.elapsed,
    );
  }

  Future<String> run<T>(
    Future<Result<T, AppFailure>> op,
    String Function(T) format,
  ) async => (await op).when(ok: format, err: _formatError);

  final output = await switch (method) {
    SourceTestMethod.search => run(
      service.search(query, page: page),
      _formatEntries,
    ),
    SourceTestMethod.getPopular => run(
      service.getPopular(page: page),
      _formatEntries,
    ),
    SourceTestMethod.getLatest => run(
      service.getLatest(page: page),
      _formatEntries,
    ),
    SourceTestMethod.getChapterList => run(
      service.getChapterList(MEntry(url: url, title: '')),
      _formatChapters,
    ),
    SourceTestMethod.getPageList => run(
      service.getPageList(MChapter(url: url, title: '')),
      _formatPages,
    ),
    SourceTestMethod.getVideoList => run(
      service.getVideoList(MChapter(url: url, title: '')),
      _formatVideos,
    ),
    SourceTestMethod.getDetails => run(
      service.getDetails(MEntry(url: url, title: '')),
      _formatEntryDetails,
    ),
    SourceTestMethod.getComments => run(
      service.getComments(MEntry(url: url, title: '')),
      _formatComments,
    ),
    SourceTestMethod.getChapterComments => run(
      service.getChapterComments(MChapter(url: url, title: '')),
      _formatComments,
    ),
    SourceTestMethod.getFilters => run(service.getFilters(), _formatFilters),
    SourceTestMethod.getSourcePreferences => run(
      service.getSourcePreferences(),
      _formatPreferences,
    ),
  };

  final skipNote = service.lastSkipNote;
  final trace = await service.takeTrace();
  await service.dispose();
  return SourceTestRun(
    output: skipNote == null ? output : '⚠ $skipNote\n\n$output',
    trace: trace,
    took: watch.elapsed,
  );
}

String _formatError(AppFailure failure) => 'Error: ${failure.displayMessage}';

String _formatPreferences(List<SourcePreference> prefs) {
  if (prefs.isEmpty) return '(no preferences defined)';
  final buffer = StringBuffer();
  for (final p in prefs) {
    buffer.writeln('- [${p.type.name}] ${p.title} (key: "${p.key}")');
    if (p.summary != null) buffer.writeln('    summary: ${p.summary}');
    if (p.defaultValue != null) {
      buffer.writeln('    default: ${p.defaultValue}');
    }
    if (p.options.isNotEmpty) {
      for (final opt in p.options) {
        buffer.writeln('    • ${opt.label} => "${opt.value}"');
      }
    }
  }
  return buffer.toString().trim();
}

String _formatFilters(List<FilterGroup> filters) {
  if (filters.isEmpty) return '(no filters defined)';
  final buffer = StringBuffer();
  for (final f in filters) {
    buffer.writeln('- [${f.type.name}] ${f.name} (key: "${f.key}")');
    if (f.options.isNotEmpty) {
      for (final opt in f.options) {
        buffer.writeln('    • ${opt.label} => "${opt.value}"');
      }
    }
    if (f.defaultIndex != null) {
      buffer.writeln('    defaultIndex: ${f.defaultIndex}');
    }
    if (f.defaultSelected != null) {
      buffer.writeln('    defaultSelected: ${f.defaultSelected}');
    }
    if (f.defaultValue != null) {
      buffer.writeln('    defaultValue: ${f.defaultValue}');
    }
  }
  return buffer.toString().trim();
}

String _formatEntries(List<MEntry> entries) {
  if (entries.isEmpty) return '(empty list)';
  return entries.map((e) => '- ${e.title}\n  url: ${e.url}').join('\n');
}

String _formatChapters(List<MChapter> chapters) {
  if (chapters.isEmpty) return '(empty list)';
  return chapters.map((c) => '- ${c.title}\n  url: ${c.url}').join('\n');
}

String _formatPages(List<MPage> pages) {
  if (pages.isEmpty) return '(empty list)';
  return pages
      .map((p) => '- #${p.index} ${p.imageUrl ?? p.text ?? '(empty)'}')
      .join('\n');
}

String _formatVideos(List<MVideo> videos) {
  if (videos.isEmpty) return '(empty list)';
  return videos
      .map((v) {
        final extras = [
          if (v.headers.isNotEmpty) '${v.headers.length} header(s)',
          if (v.subtitles.isNotEmpty) '${v.subtitles.length} subtitle(s)',
          if (v.audioTracks.isNotEmpty)
            '${v.audioTracks.length} audio track(s)',
          if (v.isPlaylist) 'playlist',
        ];
        final tail = extras.isEmpty ? '' : '  [${extras.join(', ')}]';
        return '- ${v.quality ?? '(no label)'}: ${v.url}$tail';
      })
      .join('\n');
}

String _formatEntryDetails(MEntry entry) {
  final buffer = StringBuffer()
    ..writeln('title: ${entry.title}')
    ..writeln(
      'cover: ${entry.coverUrl ?? '(none: the app keeps the one from the list)'}',
    )
    ..writeln('rating: ${entry.rating ?? '(none)'}')
    ..writeln('status: ${entry.status ?? '(none)'}')
    ..writeln('genres: ${entry.genres?.join(', ') ?? '(none)'}')
    ..writeln('description: ${entry.description ?? '(none)'}');
  return buffer.toString().trim();
}

String _formatComments(List<MComment> comments) {
  if (comments.isEmpty) return '(empty list)';
  return comments.map((c) => '- ${c.author}: ${c.text}').join('\n');
}
