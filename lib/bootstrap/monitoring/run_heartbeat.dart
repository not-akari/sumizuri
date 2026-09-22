// Notices when the app stopped without closing, and says what it was doing.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' show AppExitResponse;

import 'package:flutter/widgets.dart';

class RunRecord {
  const RunRecord({
    required this.startedAt,
    required this.lastSeen,
    required this.memoryMb,
    required this.foreground,
    required this.routes,
    required this.closedCleanly,
    this.engines = 0,
  });

  factory RunRecord.fromJson(Map<String, dynamic> json) => RunRecord(
    startedAt: DateTime.parse(json['startedAt'] as String),
    lastSeen: DateTime.parse(json['lastSeen'] as String),
    memoryMb: (json['memoryMb'] as num?)?.toInt() ?? 0,
    foreground: json['foreground'] as bool? ?? true,
    routes: [...(json['routes'] as List? ?? const []).cast<String>()],
    closedCleanly: json['closedCleanly'] as bool? ?? false,
    engines: (json['engines'] as num?)?.toInt() ?? 0,
  );

  final DateTime startedAt;
  final DateTime lastSeen;
  final int memoryMb;

  final bool foreground;

  final List<String> routes;

  final bool closedCleanly;

  /// Source engines (each an isolate with a JavaScript runtime) running at the last note.
  final int engines;

  Map<String, Object?> toJson() => {
    'startedAt': startedAt.toIso8601String(),
    'lastSeen': lastSeen.toIso8601String(),
    'memoryMb': memoryMb,
    'foreground': foreground,
    'routes': routes,
    'closedCleanly': closedCleanly,
    'engines': engines,
  };
}

class PreviousRunReport {
  const PreviousRunReport(this.message, {required this.suspicious});

  final String message;

  final bool suspicious;
}

const _highMemoryMb = 1200;

/// A run from the dev tools ends quietly when stopped, so it is not reported as a crash.
PreviousRunReport? describePreviousRun(
  RunRecord? previous, {
  bool debugBuild = false,
}) {
  if (previous == null || previous.closedCleanly) return null;
  final ranFor = previous.lastSeen.difference(previous.startedAt);
  final where = previous.routes.isEmpty
      ? ''
      : ' Last pages: ${previous.routes.reversed.take(3).toList().reversed.join(' > ')}.';
  final base =
      'The app did not close normally last time. It was last seen at '
      '${_clock(previous.lastSeen)} after ${_span(ranFor)}, using '
      '${previous.memoryMb} MB, with ${previous.engines} source engine(s) running.$where';

  if (!previous.foreground) {
    return PreviousRunReport(
      '$base It was in the background, so the system most likely closed it to free memory, which is normal.',
      suspicious: false,
    );
  }
  if (debugBuild) {
    return PreviousRunReport(
      '$base It was on screen when it stopped. This is a debug build: '
      'stopping the run, or starting it again, from the development tools '
      'ends the app the same way a crash does, so this may be that. To catch '
      'a real crash, let it happen, then start the app fresh (from its icon, '
      'or a new run) without stopping anything first.',
      suspicious: true,
    );
  }
  final leftBehind = previous.engines >= 3
      ? ' Several source engines were still running: engines left running after their pages were closed use a lot of memory.'
      : '';
  final memory = previous.memoryMb >= _highMemoryMb
      ? ' It held a lot of memory, so running out is the likeliest cause.'
      : ' Memory was not high, so a crash in the video engine or another native part is likelier than running out.';
  return PreviousRunReport(
    '$base It was on screen when it stopped.$memory$leftBehind',
    suspicious: true,
  );
}

String _clock(DateTime t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}';

String _span(Duration d) {
  if (d.inHours >= 1) return '${d.inHours} h ${d.inMinutes % 60} min';
  if (d.inMinutes >= 1) return '${d.inMinutes} min ${d.inSeconds % 60} s';
  return '${d.inSeconds} s';
}

class RunHeartbeat with WidgetsBindingObserver {
  RunHeartbeat({
    required this.file,
    required this.routes,
    int Function()? memoryMb,
    int Function()? engines,
    DateTime Function()? now,
    this.every = const Duration(seconds: 10),
  }) : _memoryMb = memoryMb ?? (() => ProcessInfo.currentRss ~/ (1024 * 1024)),
       _engines = engines ?? (() => 0),
       _now = now ?? DateTime.now;

  /// The one running, so code that ends the app on purpose can tell it.
  static RunHeartbeat? current;

  final File file;

  final List<String> Function() routes;
  final Duration every;
  final int Function() _memoryMb;
  final int Function() _engines;
  final DateTime Function() _now;

  Timer? _timer;
  AppLifecycleListener? _exitListener;
  late DateTime _startedAt;
  bool _foreground = true;

  /// What the last run left, or null if there is nothing.
  Future<RunRecord?> readPrevious() async {
    try {
      if (!await file.exists()) return null;
      return RunRecord.fromJson(
        jsonDecode(await file.readAsString()) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> start() async {
    _startedAt = _now();
    WidgetsBinding.instance.addObserver(this);
    _exitListener = AppLifecycleListener(
      onExitRequested: () async {
        await stopCleanly();
        return AppExitResponse.exit;
      },
    );
    await _write(closedCleanly: false);
    _timer = Timer.periodic(every, (_) => _write(closedCleanly: false));
    current = this;
  }

  Future<void> stopCleanly() async {
    _timer?.cancel();
    _exitListener?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    await _write(closedCleanly: true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (state == AppLifecycleState.detached) {
      unawaited(stopCleanly());
    } else {
      unawaited(_write(closedCleanly: false));
    }
  }

  Future<void> _write({required bool closedCleanly}) async {
    try {
      final record = RunRecord(
        startedAt: _startedAt,
        lastSeen: _now(),
        memoryMb: _memoryMb(),
        foreground: _foreground,
        routes: routes().length > 5
            ? routes().sublist(routes().length - 5)
            : routes(),
        closedCleanly: closedCleanly,
        engines: _engines(),
      );
      await file.writeAsString(jsonEncode(record.toJson()), flush: true);
    } catch (_) {
      // A note that cannot be written must never disturb the app.
    }
  }
}

Future<void> markCleanExit() async => RunHeartbeat.current?.stopCleanly();
