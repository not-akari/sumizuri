// The download queue: waiting, running, paused and failed items, one download at a time.
import 'dart:async';
import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:sumizuri/features/extensions/models/m_chapter.dart';
import 'package:sumizuri/features/library/flows/auto_download_gate.dart';
import 'package:sumizuri/features/settings/registry/settings_catalog.dart';
import 'package:sumizuri/features/settings/providers/settings_providers.dart';
import 'package:sumizuri/features/library/flows/download_runner.dart';
import 'package:sumizuri/features/library/models/library_types.dart';

part 'download_queue.g.dart';

enum DownloadStatus { queued, running, paused, failed }

class DownloadItem {
  const DownloadItem({
    required this.request,
    this.status = DownloadStatus.queued,
    this.progress,
    this.error,
  });

  final DownloadRequest request;
  final DownloadStatus status;

  /// 0 to 1 while it runs, when the size is known.
  final double? progress;

  /// What went wrong, for a failed one.
  final String? error;

  String get key => downloadKey(request.libraryEntryId, request.chapter.url);

  DownloadItem copyWith({
    DownloadStatus? status,
    double? progress,
    String? error,
    bool clearProgress = false,
    bool clearError = false,
  }) => DownloadItem(
    request: request,
    status: status ?? this.status,
    progress: clearProgress ? null : progress ?? this.progress,
    error: clearError ? null : error ?? this.error,
  );
}

String downloadKey(int libraryEntryId, String chapterUrl) =>
    '$libraryEntryId:$chapterUrl';

/// Where the queue is kept between runs of the app.
abstract interface class DownloadQueueStore {
  Future<String> read();

  Future<void> write(String json);
}

class _SettingsQueueStore implements DownloadQueueStore {
  _SettingsQueueStore(this._ref);

  final Ref _ref;

  @override
  Future<String> read() => _ref
      .read(settingsRepositoryProvider)
      .watchSetting(Settings.downloadQueue)
      .first;

  @override
  Future<void> write(String json) async {
    await _ref
        .read(settingsRepositoryProvider)
        .putSetting(Settings.downloadQueue, json);
  }
}

@Riverpod(keepAlive: true)
DownloadQueueStore downloadQueueStore(Ref ref) => _SettingsQueueStore(ref);

/// Whether downloads from the last run carry on alone, or wait when Wi-Fi only is set.
@Riverpod(keepAlive: true)
Future<bool> Function() downloadResumeGate(Ref ref) =>
    () => canAutoDownloadNow(ref.container);

/// The queue as text, without what only matters while a download runs (its progress).
String encodeDownloadQueue(List<DownloadItem> items) => jsonEncode({
  'v': 1,
  'items': [
    for (final item in items)
      {
        'entry': item.request.libraryEntryId,
        'source': item.request.sourceId,
        'title': item.request.entryTitle,
        'type': item.request.mediaType.name,
        'status': item.status.name,
        if (item.error != null) 'error': item.error,
        'chapter': {
          'url': item.request.chapter.url,
          'title': item.request.chapter.title,
          'number': item.request.chapter.number,
          'scanlator': item.request.chapter.scanlator,
          'webUrl': item.request.chapter.webUrl,
          'uploaded': item.request.chapter.dateUploaded?.millisecondsSinceEpoch,
        },
      },
  ],
});

/// The queue from text. Anything unreadable is left out, so a bad file never stops the app.
List<DownloadItem> decodeDownloadQueue(String json) {
  if (json.isEmpty) return const [];
  try {
    final root = jsonDecode(json);
    if (root is! Map || root['items'] is! List) return const [];
    final out = <DownloadItem>[];
    for (final raw in root['items'] as List) {
      try {
        final m = raw as Map;
        final c = m['chapter'] as Map;
        final type = MediaType.values.firstWhere((t) => t.name == m['type']);
        final status = DownloadStatus.values.firstWhere(
          (s) => s.name == m['status'],
        );
        final uploaded = c['uploaded'] as int?;
        out.add(
          DownloadItem(
            request: DownloadRequest(
              libraryEntryId: m['entry'] as int,
              sourceId: m['source'] as String,
              entryTitle: m['title'] as String,
              mediaType: type,
              chapter: MChapter(
                url: c['url'] as String,
                title: c['title'] as String,
                number: (c['number'] as num?)?.toDouble(),
                scanlator: c['scanlator'] as String?,
                webUrl: c['webUrl'] as String?,
                dateUploaded: uploaded == null
                    ? null
                    : DateTime.fromMillisecondsSinceEpoch(uploaded),
              ),
            ),
            status: status,
            error: m['error'] as String?,
          ),
        );
      } catch (_) {
        // One item that cannot be read does not cost the others.
      }
    }
    return out;
  } catch (_) {
    return const [];
  }
}

/// Adds chapters to the saved queue without downloading, for a run that cannot download.
Future<int> saveToStoredQueue(
  DownloadQueueStore store, {
  required int libraryEntryId,
  required String sourceId,
  required String entryTitle,
  required MediaType mediaType,
  required List<MChapter> chapters,
}) async {
  final saved = decodeDownloadQueue(await store.read());
  final have = {for (final item in saved) item.key};
  final next = [...saved];
  for (final chapter in chapters) {
    if (have.contains(downloadKey(libraryEntryId, chapter.url))) continue;
    next.add(
      DownloadItem(
        request: DownloadRequest(
          libraryEntryId: libraryEntryId,
          sourceId: sourceId,
          entryTitle: entryTitle,
          chapter: chapter,
          mediaType: mediaType,
        ),
      ),
    );
  }
  final added = next.length - saved.length;
  if (added > 0) await store.write(encodeDownloadQueue(next));
  return added;
}

@Riverpod(keepAlive: true)
DownloadEngine downloadEngine(Ref ref) {
  final engine = SourceDownloadEngine(ref.container);
  ref.onDispose(engine.close);
  return engine;
}

@Riverpod(keepAlive: true)
class DownloadQueue extends _$DownloadQueue {
  DownloadHandle? _handle;
  var _pumping = false;
  Timer? _saveTimer;

  @override
  List<DownloadItem> build() {
    ref.onDispose(() => _saveTimer?.cancel());
    return const [];
  }

  int _indexOf(String key) => state.indexWhere((i) => i.key == key);

  // Saves changes a moment later, but not progress alone, which is useless after a restart.
  void _publish(List<DownloadItem> next, {bool keep = true}) {
    state = next;
    if (!keep) return;
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 200), () {
      if (!ref.mounted) return;
      unawaited(
        ref
            .read(downloadQueueStoreProvider)
            .write(encodeDownloadQueue(state))
            .catchError((Object _) {}),
      );
    });
  }

  void _update(
    String key,
    DownloadItem Function(DownloadItem) change, {
    bool keep = true,
  }) {
    final at = _indexOf(key);
    if (at < 0) return;
    final next = [...state];
    next[at] = change(next[at]);
    _publish(next, keep: keep);
  }

  void _remove(String key) {
    _publish([
      for (final item in state)
        if (item.key != key) item,
    ]);
  }

  /// Brings back the queue from the last run. Call once at start-up.
  Future<void> restore() async {
    final List<DownloadItem> stored;
    try {
      stored = decodeDownloadQueue(
        await ref.read(downloadQueueStoreProvider).read(),
      );
    } catch (_) {
      return;
    }
    if (stored.isEmpty || !ref.mounted) return;
    final mayResume = await ref.read(downloadResumeGateProvider)();
    if (!ref.mounted) return;
    final have = {for (final item in state) item.key};
    final next = [...state];
    for (final item in stored) {
      if (have.contains(item.key)) continue;
      final wasActive =
          item.status == DownloadStatus.queued ||
          item.status == DownloadStatus.running;
      next.add(
        wasActive
            ? item.copyWith(
                status: mayResume
                    ? DownloadStatus.queued
                    : DownloadStatus.paused,
              )
            : item,
      );
    }
    _publish(next);
    unawaited(_pump());
  }

  /// Adds chapters to the end of the queue and returns how many were added or put back.
  int enqueue({
    required int libraryEntryId,
    required String sourceId,
    required String entryTitle,
    required MediaType mediaType,
    required List<MChapter> chapters,
  }) {
    var added = 0;
    final next = [...state];
    for (final chapter in chapters) {
      final key = downloadKey(libraryEntryId, chapter.url);
      final at = next.indexWhere((i) => i.key == key);
      if (at < 0) {
        next.add(
          DownloadItem(
            request: DownloadRequest(
              libraryEntryId: libraryEntryId,
              sourceId: sourceId,
              entryTitle: entryTitle,
              chapter: chapter,
              mediaType: mediaType,
            ),
          ),
        );
        added++;
      } else if (next[at].status == DownloadStatus.paused ||
          next[at].status == DownloadStatus.failed) {
        next[at] = next[at].copyWith(
          status: DownloadStatus.queued,
          clearError: true,
        );
        added++;
      }
    }
    _publish(next);
    unawaited(_pump());
    return added;
  }

  /// Stops a download and keeps what it fetched, so it carries on from there when resumed.
  void pause(String key) {
    final at = _indexOf(key);
    if (at < 0) return;
    final item = state[at];
    if (item.status == DownloadStatus.running) _handle?.stop(discard: false);
    if (item.status == DownloadStatus.queued ||
        item.status == DownloadStatus.running) {
      _update(
        key,
        (i) => i.copyWith(status: DownloadStatus.paused, clearProgress: true),
      );
    }
  }

  void resume(String key) {
    final at = _indexOf(key);
    if (at < 0) return;
    final status = state[at].status;
    if (status != DownloadStatus.paused && status != DownloadStatus.failed) {
      return;
    }
    _update(
      key,
      (i) => i.copyWith(status: DownloadStatus.queued, clearError: true),
    );
    unawaited(_pump());
  }

  /// Stops a download, takes it out of the queue and deletes what it fetched.
  void cancel(String key) {
    final at = _indexOf(key);
    if (at < 0) return;
    final item = state[at];
    _remove(key);
    if (item.status == DownloadStatus.running) {
      // The loop deletes what was fetched once the download has really stopped.
      _handle?.stop(discard: true);
    } else {
      unawaited(ref.read(downloadEngineProvider).discard(item.request));
    }
  }

  void pauseAll() {
    for (final item in state) {
      pause(item.key);
    }
  }

  void resumeAll() {
    for (final item in [...state]) {
      if (item.status == DownloadStatus.paused) resume(item.key);
    }
  }

  void clearFailed() {
    for (final item in [...state]) {
      if (item.status == DownloadStatus.failed) cancel(item.key);
    }
  }

  Future<void> _pump() async {
    if (_pumping) return;
    _pumping = true;
    final engine = ref.read(downloadEngineProvider);
    try {
      var first = true;
      while (ref.mounted) {
        if (!state.any((i) => i.status == DownloadStatus.queued)) break;
        if (!first) await engine.spaceOut();
        first = false;
        final at = state.indexWhere((i) => i.status == DownloadStatus.queued);
        if (at < 0) continue;
        final item = state[at];
        final handle = DownloadHandle();
        _handle = handle;
        _update(
          item.key,
          (i) => i.copyWith(
            status: DownloadStatus.running,
            clearProgress: true,
            clearError: true,
          ),
        );
        final outcome = await engine.run(item.request, handle, (fraction) {
          final held = state
              .where((i) => i.key == item.key)
              .map((i) => i.progress)
              .firstOrNull;
          // A hundred steps are plenty to draw, and a stream has thousands of pieces.
          if (held != null && (fraction - held).abs() < 0.01 && fraction < 1) {
            return;
          }
          _update(item.key, (i) => i.copyWith(progress: fraction), keep: false);
        });
        handle.close();
        _handle = null;
        switch (outcome) {
          case DownloadDone():
            _remove(item.key);
          case DownloadHalted():
            // Pause and cancel already changed the item, and a cancel also clears its files.
            if (handle.discard) await engine.discard(item.request);
          case DownloadFailed(:final message):
            _update(
              item.key,
              (i) => i.copyWith(
                status: DownloadStatus.failed,
                error: message,
                clearProgress: true,
              ),
            );
        }
      }
    } finally {
      _pumping = false;
      await engine.close();
    }
    // Something may have been added while the source was being let go.
    if (ref.mounted && state.any((i) => i.status == DownloadStatus.queued)) {
      unawaited(_pump());
    }
  }
}

/// The chapters that are waiting or running, for the download buttons.
@riverpod
Set<String> downloadingChapters(Ref ref) => {
  for (final item in ref.watch(downloadQueueProvider))
    if (item.status == DownloadStatus.queued ||
        item.status == DownloadStatus.running)
      item.key,
};

/// How far each running download has got.
@riverpod
Map<String, double> downloadProgress(Ref ref) => {
  for (final item in ref.watch(downloadQueueProvider))
    if (item.progress != null) item.key: item.progress!,
};
