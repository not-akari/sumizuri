// Talks to a JavaScript source extension running in its own isolate.
import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

import 'package:sumizuri/features/extensions/data/engines/js/js_stdlib.dart';
import 'package:sumizuri/features/extensions/render/render_broker.dart';
import 'package:sumizuri/bootstrap/storage/app_paths.dart';
import 'package:sumizuri/bootstrap/logging/app_logger.dart';
import 'package:sumizuri/core/errors/app_failure.dart';
import 'package:sumizuri/core/errors/result.dart';
import 'package:sumizuri/features/extensions/data/extension_service.dart';
import 'package:sumizuri/features/extensions/models/engine_kind.dart';
import 'package:sumizuri/features/extensions/models/filter_group.dart';
import 'package:sumizuri/features/extensions/models/installed_source.dart';
import 'package:sumizuri/features/extensions/models/m_chapter.dart';
import 'package:sumizuri/features/extensions/models/m_comment.dart';
import 'package:sumizuri/features/extensions/models/m_entry.dart';
import 'package:sumizuri/features/extensions/models/m_page.dart';
import 'package:sumizuri/features/library/models/library_types.dart';
import 'package:sumizuri/features/extensions/models/m_video.dart';
import 'package:sumizuri/features/extensions/models/m_source_info.dart';
import 'package:sumizuri/features/extensions/models/source_preference.dart';
import 'package:sumizuri/features/extensions/data/engines/json/json_extension_loader.dart';
import 'package:sumizuri/features/extensions/data/engines/js/js_isolate_worker.dart';
import 'package:sumizuri/features/extensions/data/engines/js/js_model_mapping.dart';

Future<String> cookieDirPathFor(String sourceId) async {
  final appDir = await appDataDirectory();
  final safeId = sourceId.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
  return p.join(appDir.path, 'cookies', safeId);
}

Future<String> storageDirPathFor(String sourceId) async {
  final appDir = await appDataDirectory();
  final safeId = sourceId.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
  return p.join(appDir.path, 'source_storage', safeId);
}

const _logPreviewLength = 300;

String previewForLog(String value) => value.length <= _logPreviewLength
    ? value
    : '${value.substring(0, _logPreviewLength)}… (${value.length} characters)';

const _logTag = 'js_extension';
const _slowCallMs = 8000;

class JsExtensionService implements ExtensionService {
  JsExtensionService._(
    this.info,
    this._isolate,
    this._commandPort,
    this._logger,
    this.callTimeout,
  );

  @override
  final MSourceInfo info;

  final Isolate _isolate;
  final SendPort _commandPort;
  final AppLogger? _logger;
  bool _disposed = false;
  int? _rateLimitMs;
  Map<String, String>? _defaultHeaders;

  @override
  int? get rateLimitMs => _rateLimitMs;

  @override
  Map<String, String>? get defaultHeaders => _defaultHeaders;

  // Bounds one isolate round-trip.
  static const _defaultCallTimeout = Duration(minutes: 5);

  final Duration callTimeout;

  static Future<Result<JsExtensionService, AppFailure>> load(
    MSourceInfo info,
    String jsSource, {
    AppLogger? logger,
    Duration requestTimeout = const Duration(seconds: 30),
    String? userAgent,
    Duration callTimeout = _defaultCallTimeout,
    bool isTesting = false,
  }) async {
    final readyPort = ReceivePort();
    final rootIsolateToken = ServicesBinding.rootIsolateToken!;
    final cookieDirPath = await cookieDirPathFor(info.id);
    final storageDirPath = await storageDirPathFor(info.id);
    final stdlib = await loadJsStdlib();
    final isolate = await Isolate.spawn(jsIsolateEntryPoint, (
      readyPort.sendPort,
      rootIsolateToken,
      cookieDirPath,
      storageDirPath,
      requestTimeout.inSeconds,
      userAgent,
      isTesting,
      RenderBroker.instance.sendPort,
      stdlib,
    ));
    final commandPort = await readyPort.first as SendPort;
    final service = JsExtensionService._(
      info,
      isolate,
      commandPort,
      logger,
      callTimeout,
    );

    final initResult = await service._send('init', jsSource);
    switch (initResult) {
      case Ok():
        service._counted = true;
        liveCount++;
        await service.readCapabilities();
        return Ok(service);
      case Err(:final error):
        service._isolate.kill(priority: Isolate.immediate);
        return Err(error);
    }
  }

  static Future<Result<JsExtensionService, AppFailure>> loadSource(
    MSourceInfo info,
    AppInstalledSource source, {
    AppLogger? logger,
    Duration requestTimeout = const Duration(seconds: 30),
    String? userAgent,
    Duration callTimeout = _defaultCallTimeout,
    bool isTesting = false,
  }) {
    final jsSource = source.engineKind == EngineKind.json
        ? buildJsSourceFromJson(source.jsSource)
        : source.jsSource;
    return load(
      info,
      jsSource,
      logger: logger,
      requestTimeout: requestTimeout,
      userAgent: userAgent,
      callTimeout: callTimeout,
      isTesting: isTesting,
    );
  }

  String? lastSkipNote;

  Future<List<Map<String, Object?>>> takeTrace() async {
    final result = await _send('takeTrace', null);
    return result.when(
      ok: (json) => [
        for (final entry in jsonDecode(json) as List)
          (entry as Map).cast<String, Object?>(),
      ],
      err: (_) => const [],
    );
  }

  static String _preview(String value) => previewForLog(value);

  Future<Result<String, AppFailure>> _send(String method, Object? args) async {
    if (_disposed) {
      return const Err(ExtensionFailure('This extension has been disposed.'));
    }
    final argsJson = jsonEncode(args);
    _logger?.debug(
      '${info.name}.$method(${previewForLog(argsJson)}) →',
      tag: _logTag,
    );
    final replyPort = ReceivePort();
    _pending.add(replyPort);
    final callWatch = Stopwatch()..start();
    _commandPort.send((method, argsJson, replyPort.sendPort));

    (bool, String) reply;
    try {
      reply = await replyPort.first.timeout(callTimeout) as (bool, String);
    } on StateError {
      // The port was closed by dispose: this call was cut short on purpose.
      return const Err(ExtensionFailure('This extension has been disposed.'));
    } on TimeoutException {
      _isolate.kill(priority: Isolate.immediate);
      _disposed = true;
      _release();
      final failure = ExtensionFailure(
        '${info.name} did not respond within $callTimeout, it may be stuck.',
      );
      _logger?.error(
        failure.message,
        tag: _logTag,
        error: 'timeout on $method',
      );
      return Err(failure);
    }

    _pending.remove(replyPort);
    replyPort.close();
    final (ok, resultOrMessage) = reply;
    // A source call is mostly network time, so a slow one is worth flagging by name.
    if (callWatch.elapsedMilliseconds >= _slowCallMs) {
      _logger?.warning(
        'Slow source call: ${info.name}.$method took '
        '${(callWatch.elapsedMilliseconds / 1000).toStringAsFixed(1)}s',
        tag: 'network',
      );
    }
    if (!ok) {
      const notImplementedMarker = '__NOT_IMPLEMENTED__:';
      final notImplementedIndex = resultOrMessage.indexOf(notImplementedMarker);
      if (notImplementedIndex != -1) {
        final methodName = resultOrMessage
            .substring(notImplementedIndex + notImplementedMarker.length)
            .split(RegExp(r'\s'))
            .first;
        _logger?.debug(
          '${info.name}.$methodName is not implemented',
          tag: _logTag,
        );
        return Err(
          NotImplementedFailure('${info.name} doesn\'t support $methodName.'),
        );
      }

      const challengeMarker = '__CHALLENGE__:';
      final challengeIndex = resultOrMessage.indexOf(challengeMarker);
      if (challengeIndex != -1) {
        final challengedUrl = resultOrMessage
            .substring(challengeIndex + challengeMarker.length)
            .split(RegExp(r'\s'))
            .first;
        _logger?.debug(
          '${info.name}.$method hit a challenge at $challengedUrl',
          tag: _logTag,
        );
        return Err(
          ChallengeFailure(
            '${info.name} needs a browser to get past a login wall or bot check.',
            url: challengedUrl,
          ),
        );
      }

      final failure = ExtensionFailure(resultOrMessage);
      _logger?.error(
        '${info.name}.$method failed: $resultOrMessage',
        tag: _logTag,
        error: resultOrMessage,
      );
      return Err(failure);
    }
    _logger?.debug(
      '${info.name}.$method →← ${_preview(resultOrMessage)}',
      tag: _logTag,
    );
    return Ok(resultOrMessage);
  }

  Future<Result<List<T>, AppFailure>> _callList<T>(
    String method,
    List<Object?> args,
    T Function(Map<String, dynamic> json) fromJson,
  ) async {
    final result = await _send(method, args);
    return result.when(
      ok: (json) {
        // fromJson can throw, because it casts required fields of data the source produced.
        try {
          final read = decodeListLeniently(json, fromJson);
          lastSkipNote = read.skipped == 0
              ? null
              : '${read.skipped} item(s) were skipped because they could not be read. The first problem: ${read.firstError}';
          if (read.skipped > 0) {
            _logger?.warning(
              '${info.name}.$method: $lastSkipNote',
              tag: _logTag,
            );
          }
          return Ok(read.items);
        } catch (error) {
          final failure = ExtensionFailure('${info.name}.$method: $error');
          _logger?.error(failure.message, tag: _logTag, error: error);
          return Err(failure);
        }
      },
      err: Err.new,
    );
  }

  Future<Result<Map<String, String?>, AppFailure>> readMetadata() async {
    final result = await _send('metadata', null);
    return result.when(
      ok: (json) {
        try {
          return Ok((jsonDecode(json) as Map).cast<String, String?>());
        } catch (error) {
          final failure = ExtensionFailure('${info.name}.metadata: $error');
          _logger?.error(failure.message, tag: _logTag, error: error);
          return Err(failure);
        }
      },
      err: Err.new,
    );
  }

  @override
  Future<Result<ExtensionCapabilities, AppFailure>> readCapabilities() async {
    final result = await _send('metadata', null);
    return result.when(
      ok: (json) {
        try {
          final decoded = (jsonDecode(json) as Map).cast<String, dynamic>();
          final rateLimit = decoded['rateLimitMs'] as int?;
          _rateLimitMs = rateLimit;
          final headersRaw = decoded['headers'] as Map?;
          final headers = headersRaw?.map(
            (k, v) => MapEntry(k.toString(), v.toString()),
          );
          _defaultHeaders = headers;
          return Ok((
            hasDetails: decoded['hasDetails'] == true,
            hasComments: decoded['hasComments'] == true,
            hasChapterComments: decoded['hasChapterComments'] == true,
            hasFilters: decoded['hasFilters'] == true,
            hasPreferences: decoded['hasPreferences'] == true,
            rateLimitMs: rateLimit,
            defaultHeaders: headers,
          ));
        } catch (error) {
          final failure = ExtensionFailure('${info.name}.metadata: $error');
          _logger?.error(failure.message, tag: _logTag, error: error);
          return Err(failure);
        }
      },
      err: Err.new,
    );
  }

  @override
  Future<Result<List<MEntry>, AppFailure>> search(
    String query, {
    int page = 1,
    Map<String, dynamic>? filters,
  }) {
    final args = [
      query,
      page,
      if (filters != null && filters.isNotEmpty) filters,
    ];
    return _callList('search', args, entryFromJson);
  }

  @override
  Future<Result<List<MEntry>, AppFailure>> getPopular({int page = 1}) =>
      _callList('getPopular', [page], entryFromJson);

  @override
  Future<Result<List<MEntry>, AppFailure>> getLatest({int page = 1}) =>
      _callList('getLatest', [page], entryFromJson);

  @override
  Future<Result<List<MChapter>, AppFailure>> getChapterList(MEntry entry) =>
      _callList(
        'getChapterList',
        [entry.url],
        (json) => chapterFromJson(
          json,
          numberedAs: info.mediaType == MediaType.anime ? 'Episode' : 'Chapter',
        ),
      );

  @override
  Future<Result<List<MPage>, AppFailure>> getPageList(MChapter chapter) =>
      _callList('getPageList', [chapter.url], pageFromJson);

  @override
  Future<Result<List<MVideo>, AppFailure>> getVideoList(MChapter chapter) =>
      _callList('getVideoList', [chapter.url], videoFromJson);

  @override
  Future<Result<MEntry, AppFailure>> getDetails(MEntry entry) async {
    final result = await _send('getDetails', [entry.url]);
    return result.when(
      ok: (json) {
        try {
          return Ok(
            entryFromJson((jsonDecode(json) as Map).cast<String, dynamic>()),
          );
        } catch (error) {
          final failure = ExtensionFailure('${info.name}.getDetails: $error');
          _logger?.error(failure.message, tag: _logTag, error: error);
          return Err(failure);
        }
      },
      err: Err.new,
    );
  }

  @override
  Future<Result<List<MComment>, AppFailure>> getComments(
    MEntry entry, {
    CommentSort sort = CommentSort.newest,
  }) => _callList('getComments', [entry.url, sort.name], commentFromJson);

  @override
  Future<Result<List<MComment>, AppFailure>> getChapterComments(
    MChapter chapter, {
    CommentSort sort = CommentSort.newest,
  }) => _callList('getChapterComments', [
    chapter.url,
    sort.name,
  ], commentFromJson);

  @override
  Future<Result<List<FilterGroup>, AppFailure>> getFilters() async {
    final result = await _send('getFilters', <dynamic>[]);
    return result.when(
      ok: (json) {
        try {
          final decoded = jsonDecode(json) as List;
          return Ok(
            decoded
                .map(
                  (e) =>
                      FilterGroup.fromJson((e as Map).cast<String, dynamic>()),
                )
                .toList(),
          );
        } catch (error) {
          final failure = ExtensionFailure('${info.name}.getFilters: $error');
          _logger?.error(failure.message, tag: _logTag, error: error);
          return Err(failure);
        }
      },
      err: Err.new,
    );
  }

  @override
  Future<Result<List<SourcePreference>, AppFailure>>
  getSourcePreferences() async {
    final result = await _send('getSourcePreferences', <dynamic>[]);
    return result.when(
      ok: (json) {
        try {
          final decoded = jsonDecode(json) as List;
          return Ok(
            decoded
                .map(
                  (e) => SourcePreference.fromJson(
                    (e as Map).cast<String, dynamic>(),
                  ),
                )
                .toList(),
          );
        } catch (error) {
          final failure = ExtensionFailure(
            '${info.name}.getSourcePreferences: $error',
          );
          _logger?.error(failure.message, tag: _logTag, error: error);
          return Err(failure);
        }
      },
      err: Err.new,
    );
  }

  @override
  Future<Result<Map<String, dynamic>, AppFailure>> getPreferences() async {
    final result = await _send('getPreferences', null);
    return result.when(
      ok: (json) {
        try {
          final decoded = (jsonDecode(json) as Map).cast<String, dynamic>();
          return Ok(decoded);
        } catch (error) {
          final failure = ExtensionFailure(
            '${info.name}.getPreferences: $error',
          );
          _logger?.error(failure.message, tag: _logTag, error: error);
          return Err(failure);
        }
      },
      err: Err.new,
    );
  }

  @override
  Future<Result<void, AppFailure>> setPreference(
    String key,
    dynamic value,
  ) async {
    final result = await _send('setPreference', {'key': key, 'value': value});
    return result.when(ok: (_) => const Ok(null), err: Err.new);
  }

  @override
  Future<Result<void, AppFailure>> setPreferences(
    Map<String, dynamic> values,
  ) async {
    final result = await _send('setPreferences', values);
    return result.when(ok: (_) => const Ok(null), err: Err.new);
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _release();
    for (final port in _pending.toList()) {
      port.close();
    }
    // The isolate is asked to finish what it is doing and free its runtime.
    final done = ReceivePort();
    _commandPort.send(('dispose', '', done.sendPort));
    try {
      await done.first.timeout(const Duration(seconds: 4));
    } catch (_) {
    } finally {
      done.close();
      _isolate.kill(priority: Isolate.immediate);
    }
  }

  // Source engines running now, each an isolate holding a JavaScript runtime.
  static int liveCount = 0;
  bool _counted = false;

  void _release() {
    if (!_counted) return;
    _counted = false;
    liveCount--;
  }

  final _pending = <ReceivePort>{};
}
