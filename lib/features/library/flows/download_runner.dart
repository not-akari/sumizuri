// Doing one download: loading the source, fetching the files, and recording the folder.
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import 'package:sumizuri/core/utils/files/delete_if_exists.dart';
import 'package:sumizuri/bootstrap/logging/app_logger.dart';
import 'package:sumizuri/bootstrap/storage/app_paths.dart';
import 'package:sumizuri/bootstrap/logging/logger_provider.dart';
import 'package:sumizuri/core/utils/formatting/chapter_number.dart';
import 'package:sumizuri/core/utils/downloads/download_stopped.dart';
import 'package:sumizuri/core/utils/files/episode_files.dart';
import 'package:sumizuri/core/utils/downloads/jittered_delay.dart';
import 'package:sumizuri/features/extensions/providers/extension_providers.dart';
import 'package:sumizuri/features/extensions/data/extension_service.dart';
import 'package:sumizuri/features/extensions/models/installed_source.dart';
import 'package:sumizuri/features/extensions/models/m_chapter.dart';
import 'package:sumizuri/features/extensions/models/m_source_info.dart';
import 'package:sumizuri/features/library/flows/resumable_pages.dart';
import 'package:sumizuri/features/library/providers/library_providers.dart';
import 'package:sumizuri/features/library/models/library_types.dart';
import 'package:sumizuri/features/settings/providers/settings_providers.dart';

/// What one download needs to know about the title it belongs to.
class DownloadRequest {
  const DownloadRequest({
    required this.libraryEntryId,
    required this.sourceId,
    required this.entryTitle,
    required this.chapter,
    required this.mediaType,
  });

  final int libraryEntryId;
  final String sourceId;
  final String entryTitle;
  final MChapter chapter;
  final MediaType mediaType;
}

/// How a download ended.
sealed class DownloadOutcome {
  const DownloadOutcome();
}

class DownloadDone extends DownloadOutcome {
  const DownloadDone();
}

/// Paused or cancelled by the viewer.
class DownloadHalted extends DownloadOutcome {
  const DownloadHalted();
}

class DownloadFailed extends DownloadOutcome {
  const DownloadFailed(this.message);

  final String message;
}

/// Lets a running download be stopped from outside.
class DownloadHandle {
  var _stop = false;
  var _discard = false;
  http.Client? _client;

  bool get stopRequested => _stop;

  /// True when what was fetched so far should be deleted, not kept for later.
  bool get discard => _discard;

  /// The download's own client, so stopping can cut a request that is in flight.
  http.Client get client => _client ??= http.Client();

  void stop({required bool discard}) {
    _stop = true;
    _discard = discard;
    _client?.close();
  }

  void close() => _client?.close();
}

/// Does the downloading. The queue only decides when, so tests can put a fake in its place.
abstract interface class DownloadEngine {
  Future<DownloadOutcome> run(
    DownloadRequest request,
    DownloadHandle handle,
    void Function(double fraction) onProgress,
  );

  /// Waits between two downloads, so a source is not hit back to back.
  Future<void> spaceOut();

  /// Deletes what a download left behind.
  Future<void> discard(DownloadRequest request);

  /// Lets go of anything held between downloads (a loaded source).
  Future<void> close();
}

String _sanitizeForPath(String value) =>
    value.replaceAll(RegExp(r'[^A-Za-z0-9_.-]'), '_');

class SourceDownloadEngine implements DownloadEngine {
  SourceDownloadEngine(this._container);

  final ProviderContainer _container;
  ExtensionService? _service;
  String? _serviceSourceId;

  AppLogger get _logger => _container.read(appLoggerProvider);

  Future<Directory> _directoryFor(DownloadRequest request) async {
    final anime = request.mediaType == MediaType.anime;
    final overridePath = _container.read(downloadDirectoryPathProvider).value;
    final baseDir = await downloadsDirectory(overridePath: overridePath);
    final chapter = request.chapter;
    final label = chapter.number != null
        ? '${anime ? 'ep' : 'ch'}_${formatChapterNumber(chapter.number!)}'
        : _sanitizeForPath(chapter.title);
    return Directory(
      p.join(
        baseDir.path,
        _sanitizeForPath(request.sourceId),
        _sanitizeForPath(request.entryTitle),
        label,
      ),
    );
  }

  // The source of the download, kept while the next downloads are from the same one.
  Future<ExtensionService?> _serviceFor(String sourceId) async {
    if (_service != null && _serviceSourceId == sourceId) return _service;
    await _releaseService();
    final sources = await _container.read(installedSourcesProvider.future);
    AppInstalledSource? source;
    for (final candidate in sources) {
      if ('${candidate.id}' == sourceId) source = candidate;
    }
    if (source == null) return null;
    final loaded = await loadInstalledSource(
      _container,
      MSourceInfo.fromInstalledSource(source),
      source,
      logger: _logger,
    );
    _service = loaded.valueOrNull;
    _serviceSourceId = _service == null ? null : sourceId;
    return _service;
  }

  Future<void> _releaseService() async {
    final service = _service;
    _service = null;
    _serviceSourceId = null;
    await service?.dispose();
  }

  @override
  Future<DownloadOutcome> run(
    DownloadRequest request,
    DownloadHandle handle,
    void Function(double fraction) onProgress,
  ) async {
    try {
      final service = await _serviceFor(request.sourceId);
      if (handle.stopRequested) return const DownloadHalted();
      if (service == null) {
        return const DownloadFailed(
          'The source could not be opened. Is it still installed?',
        );
      }
      final dir = await _directoryFor(request);
      final anime = request.mediaType == MediaType.anime;
      // An anime episode is one video file in its folder and anything else is a folder of pages.
      final saved = anime
          ? await _saveEpisode(
              service,
              request.chapter,
              dir,
              handle,
              onProgress,
            )
          : await _savePages(service, request.chapter, dir, handle);
      if (handle.stopRequested) return const DownloadHalted();
      if (saved != null) return DownloadFailed(saved);
      await _container
          .read(libraryRepositoryProvider)
          .setChapterLocalPath(
            libraryEntryId: request.libraryEntryId,
            chapterUrl: request.chapter.url,
            path: dir.path,
          );
      return const DownloadDone();
    } on DownloadStopped {
      return const DownloadHalted();
    } catch (error, stackTrace) {
      if (handle.stopRequested) return const DownloadHalted();
      _logger.error(
        'Download failed',
        tag: 'downloads',
        error: error,
        stackTrace: stackTrace,
      );
      return DownloadFailed('$error');
    }
  }

  // Null when it worked, else what went wrong in words for the viewer.
  Future<String?> _savePages(
    ExtensionService service,
    MChapter chapter,
    Directory dir,
    DownloadHandle handle,
  ) async {
    final pages = (await service.getPageList(chapter)).valueOrNull;
    if (pages == null || pages.isEmpty) {
      return 'The source gave no pages for this chapter.';
    }
    await writeChapterPages(
      dir: dir,
      pages: pages,
      shouldStop: () => handle.stopRequested,
      fetch: (url) async {
        final response = await handle.client.get(Uri.parse(url));
        if (response.statusCode != 200) {
          throw Exception('HTTP ${response.statusCode}');
        }
        return response.bodyBytes;
      },
    );
    return null;
  }

  Future<String?> _saveEpisode(
    ExtensionService service,
    MChapter chapter,
    Directory dir,
    DownloadHandle handle,
    void Function(double fraction) onProgress,
  ) async {
    final videos = (await service.getVideoList(chapter)).valueOrNull;
    final video = videos == null ? null : pickDownloadable(videos);
    if (video == null) {
      return 'No video that can be downloaded: the source offers none, or only DASH streams.';
    }
    await writeEpisodeFiles(
      dir: dir,
      video: video,
      client: handle.client,
      onProgress: onProgress,
      shouldStop: () => handle.stopRequested,
    );
    return null;
  }

  @override
  Future<void> spaceOut() async {
    final userDelayMs =
        await _container
            .read(settingsRepositoryProvider)
            .watchDownloadDelaySeconds()
            .first *
        1000;
    final delayMs = [
      userDelayMs,
      _service?.rateLimitMs ?? 0,
    ].reduce((a, b) => a > b ? a : b);
    if (delayMs > 0) await Future<void>.delayed(jitteredDelay(delayMs));
  }

  @override
  Future<void> discard(DownloadRequest request) async {
    final dir = await _directoryFor(request);
    await deleteIfExists(dir, recursive: true);
  }

  @override
  Future<void> close() => _releaseService();
}
