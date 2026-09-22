// Watches frame timings in the background and logs a warning.
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/bootstrap/logging/app_logger.dart';
import 'package:sumizuri/bootstrap/logging/logger_provider.dart';
import 'package:sumizuri/bootstrap/monitoring/memory_watchdog.dart';

const _tag = 'fps';

class FrameWatchdogConfig {
  const FrameWatchdogConfig({
    this.dropThreshold = 20,
    this.minActiveFrames = 30,
    this.baselineSeconds = 30,
    this.warmupSeconds = 3,
    this.hitchMs = 120,
    this.startupGrace = const Duration(seconds: 20),
    this.warnCooldown = const Duration(seconds: 15),
  });

  final int dropThreshold;

  final int minActiveFrames;
  final int baselineSeconds;
  final int warmupSeconds;

  final int hitchMs;

  /// Launch is always janky (database, first builds), so nothing is logged for this long.
  final Duration startupGrace;
  final Duration warnCooldown;

  static const standard = FrameWatchdogConfig();
}

final frameWatchdogProvider = Provider<FrameWatchdog>((ref) {
  final watchdog = FrameWatchdog(
    logger: ref.watch(appLoggerProvider),
    breadcrumbs: memoryBreadcrumbs,
  );
  ref.onDispose(watchdog.stop);
  return watchdog;
});

class FrameWatchdog {
  FrameWatchdog({
    required this.logger,
    required this.breadcrumbs,
    this.config = FrameWatchdogConfig.standard,
  });

  final AppLogger logger;
  final MemoryBreadcrumbs breadcrumbs;
  FrameWatchdogConfig config;

  bool _running = false;
  DateTime? _startedAt;
  final _spansUs = <int>[];
  int _bucket = -1;
  int _frames = 0;
  int _buildUs = 0;
  int _rasterUs = 0;
  int _worstUs = 0;
  final _history = <int>[];
  DateTime? _lastWarn;
  DateTime? _lastHitch;

  void start() {
    if (_running) return;
    _running = true;
    _startedAt = DateTime.now();
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
  }

  void stop() {
    if (!_running) return;
    _running = false;
    SchedulerBinding.instance.removeTimingsCallback(_onTimings);
  }

  void _onTimings(List<FrameTiming> timings) {
    for (final t in timings) {
      final second =
          t.timestampInMicroseconds(FramePhase.rasterFinish) ~/ 1000000;
      if (second != _bucket) {
        _closeBucket();
        _bucket = second;
      }
      _frames++;
      _spansUs.add(t.totalSpan.inMicroseconds);
      _checkHitch(t);
      _buildUs += t.buildDuration.inMicroseconds;
      _rasterUs += t.rasterDuration.inMicroseconds;
      if (t.totalSpan.inMicroseconds > _worstUs) {
        _worstUs = t.totalSpan.inMicroseconds;
      }
    }
  }

  void _checkHitch(FrameTiming t) {
    final totalMs = t.totalSpan.inMicroseconds / 1000;
    if (totalMs < config.hitchMs) return;
    final now = DateTime.now();
    if (now.difference(_startedAt!) < config.startupGrace) return;
    if (_lastHitch != null &&
        now.difference(_lastHitch!) < const Duration(seconds: 3)) {
      return;
    }
    _lastHitch = now;
    final buildMs = t.buildDuration.inMicroseconds / 1000;
    final rasterMs = t.rasterDuration.inMicroseconds / 1000;
    final buffer = StringBuffer('Slow frame: ${totalMs.round()}ms')..writeln();
    buffer
      ..writeln(
        '  build ${buildMs.toStringAsFixed(0)}ms, '
        'raster ${rasterMs.toStringAsFixed(0)}ms '
        '(${buildMs >= rasterMs ? 'UI thread' : 'GPU raster'} is the slower side)',
      )
      ..writeln('  recent routes: ${breadcrumbs.recent.join(' | ')}');
    if (kDebugMode) buffer.writeln('  (debug build: frame times are inflated)');
    logger.warning(buffer.toString().trimRight(), tag: _tag);
  }

  void _closeBucket() {
    final frames = _frames;
    final buildMs = frames == 0 ? 0.0 : _buildUs / frames / 1000;
    final rasterMs = frames == 0 ? 0.0 : _rasterUs / frames / 1000;
    final worstMs = _worstUs / 1000;
    final spans = List<int>.of(_spansUs);
    _spansUs.clear();
    _frames = 0;
    _buildUs = 0;
    _rasterUs = 0;
    _worstUs = 0;
    if (frames < config.minActiveFrames) return;

    if (_history.length >= config.warmupSeconds) {
      final average = _history.reduce((a, b) => a + b) / _history.length;
      final drop = average - frames;
      final now = DateTime.now();
      final cooled =
          _lastWarn == null ||
          now.difference(_lastWarn!) >= config.warnCooldown;
      // Fewer frames alone is not jank, since an animation ending also lowers the count.
      final budgetMs = 1000 / average;
      final slowFrames = spans.where((us) => us / 1000 > budgetMs * 2).length;
      final workMs = buildMs + rasterMs;
      final reallySlow = slowFrames >= 2 || workMs > budgetMs * 0.6;
      final pastGrace = now.difference(_startedAt!) >= config.startupGrace;
      if (drop >= config.dropThreshold && cooled && reallySlow && pastGrace) {
        _lastWarn = now;
        _warn(
          fps: frames,
          average: average,
          buildMs: buildMs,
          rasterMs: rasterMs,
          worstMs: worstMs,
        );
        // The slow second must not drag the average down and hide the next one.
        return;
      }
    }
    _history.add(frames);
    if (_history.length > config.baselineSeconds) _history.removeAt(0);
  }

  void _warn({
    required int fps,
    required double average,
    required double buildMs,
    required double rasterMs,
    required double worstMs,
  }) {
    final side = buildMs >= rasterMs
        ? 'UI thread (building/laying out widgets)'
        : 'GPU raster (painting, shaders, layers)';
    final buffer = StringBuffer(
      'FPS dropped to $fps (average ${average.round()}, '
      '-${(average - fps).round()})',
    )..writeln();
    buffer
      ..writeln(
        '  avg frame: build ${buildMs.toStringAsFixed(1)}ms, '
        'raster ${rasterMs.toStringAsFixed(1)}ms, '
        'worst ${worstMs.toStringAsFixed(0)}ms',
      )
      ..writeln('  slower side: $side')
      ..writeln('  recent routes: ${breadcrumbs.recent.join(' | ')}');
    if (kDebugMode) {
      buffer.writeln('  (debug build: frame times are inflated)');
    }
    logger.warning(buffer.toString().trimRight(), tag: _tag);
  }
}
