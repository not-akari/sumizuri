// Samples process memory in the background and logs a warning.
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/bootstrap/logging/app_logger.dart';
import 'package:sumizuri/bootstrap/logging/logger_provider.dart';

const _tag = 'memory';

class MemoryWatchdogConfig {
  const MemoryWatchdogConfig({
    this.sampleInterval = const Duration(seconds: 10),
    this.warmupSamples = 6,
    this.windowSamples = 18,
    this.growthWarnMb = 150,
    this.minRisingShare = 0.75,
    this.warnCooldown = const Duration(minutes: 5),
    this.absoluteFirstMb = 1500,
    this.absoluteStepMb = 300,
  });

  final Duration sampleInterval;
  final int warmupSamples;
  final int windowSamples;
  final int growthWarnMb;
  final double minRisingShare;
  final Duration warnCooldown;
  final int absoluteFirstMb;
  final int absoluteStepMb;

  static const standard = MemoryWatchdogConfig();
}

final memoryWatchdogProvider = Provider<MemoryWatchdog>((ref) {
  final watchdog = MemoryWatchdog(
    logger: ref.watch(appLoggerProvider),
    breadcrumbs: memoryBreadcrumbs,
  );
  ref.onDispose(watchdog.stop);
  return watchdog;
});

final memoryBreadcrumbs = MemoryBreadcrumbs();

/// Remembers the last few routes so a memory warning can say where the user was.
class MemoryBreadcrumbs extends NavigatorObserver {
  final _crumbs = <String>[];

  List<String> get recent => List.unmodifiable(_crumbs);

  void _add(String action, Route<dynamic>? route) {
    if (route == null) return;
    final name = route.settings.name ?? route.runtimeType.toString();
    _crumbs.add('$action $name');
    if (_crumbs.length > 10) _crumbs.removeAt(0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final page = _pageTypeOf(route);
      if (page != null && _crumbs.isNotEmpty) {
        final i = _crumbs.lastIndexWhere((c) => c == '$action $name');
        if (i >= 0) _crumbs[i] = '$action $name -> $page';
      }
    });
  }

  String? _pageTypeOf(Route<dynamic> route) {
    final ctx = route is ModalRoute ? route.subtreeContext : null;
    if (ctx == null) return null;
    String? found;
    var depth = 0;
    void visit(Element e) {
      if (found != null || depth > 14) return;
      depth++;
      final t = e.widget.runtimeType.toString();
      final framework =
          t.startsWith('_') ||
          const {
            'Builder',
            'KeyedSubtree',
            'RepaintBoundary',
            'Semantics',
            'Focus',
            'FocusScope',
            'Offstage',
            'TickerMode',
            'IgnorePointer',
            'Visibility',
            'FadeTransition',
            'SlideTransition',
            'ScaleTransition',
            'AnimatedBuilder',
            'ModalScope',
            'PrimaryScrollController',
            'Shortcuts',
            'Actions',
            'DefaultSelectionStyle',
            'Directionality',
            'MediaQuery',
            'Theme',
            'Localizations',
            'ClipRect',
          }.contains(t);
      if (!framework && e.widget is! InheritedWidget) {
        found = t;
        return;
      }
      e.visitChildElements(visit);
    }

    try {
      (ctx as Element).visitChildElements(visit);
    } catch (_) {
      return null;
    }
    return found;
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _add('push', route);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _add('pop', route);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      _add('replace', newRoute);
}

class MemoryWatchdog {
  MemoryWatchdog({
    required this.logger,
    required this.breadcrumbs,
    this.config = MemoryWatchdogConfig.standard,
  });

  MemoryWatchdogConfig config;

  /// Swaps thresholds at runtime and clears history so old samples do not count.
  void applyConfig(MemoryWatchdogConfig newConfig) {
    config = newConfig;
    _rss.clear();
    _lastWarn = null;
    _nextAbsoluteMb = newConfig.absoluteFirstMb;
    if (_timer != null) {
      _timer!.cancel();
      _timer = Timer.periodic(config.sampleInterval, (_) => _sample());
    }
  }

  final AppLogger logger;
  final MemoryBreadcrumbs breadcrumbs;

  Timer? _timer;
  final _rss = <int>[];
  DateTime? _lastWarn;
  int _nextAbsoluteMb = MemoryWatchdogConfig.standard.absoluteFirstMb;

  final _live = <String, int>{};
  Map<String, int> _baseline = const {};
  bool _tracking = false;

  void start() {
    if (_timer != null) return;
    if (kFlutterMemoryAllocationsEnabled) {
      _tracking = true;
      FlutterMemoryAllocations.instance.addListener(_onEvent);
    }
    _timer = Timer.periodic(config.sampleInterval, (_) => _sample());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    if (_tracking) {
      FlutterMemoryAllocations.instance.removeListener(_onEvent);
      _tracking = false;
    }
  }

  void _onEvent(ObjectEvent event) {
    if (event is ObjectCreated) {
      final key = event.object.runtimeType.toString();
      _live[key] = (_live[key] ?? 0) + 1;
    } else if (event is ObjectDisposed) {
      final key = event.object.runtimeType.toString();
      final n = (_live[key] ?? 1) - 1;
      _live[key] = n < 0 ? 0 : n;
    }
  }

  int get _currentMb => ProcessInfo.currentRss ~/ (1024 * 1024);

  void _sample() {
    final mb = _currentMb;
    _rss.add(mb);
    if (_rss.length > config.windowSamples) _rss.removeAt(0);

    if (_rss.length == config.warmupSamples) _baseline = Map.of(_live);
    if (_rss.length < config.warmupSamples) return;

    final now = DateTime.now();
    final cooled =
        _lastWarn == null || now.difference(_lastWarn!) >= config.warnCooldown;

    if (mb >= _nextAbsoluteMb) {
      _nextAbsoluteMb = mb + config.absoluteStepMb;
      _warn('Memory is high: ${mb}MB');
      return;
    }
    if (!cooled || _rss.length < config.windowSamples) return;

    final growth = _rss.last - _rss.first;
    var rising = 0;
    for (var i = 1; i < _rss.length; i++) {
      if (_rss[i] >= _rss[i - 1]) rising++;
    }
    final share = rising / (_rss.length - 1);
    if (growth >= config.growthWarnMb && share >= config.minRisingShare) {
      _warn(
        'Memory keeps climbing: +${growth}MB over '
        '${config.windowSamples * config.sampleInterval.inSeconds}s '
        '(now ${mb}MB)',
      );
    }
  }

  void _warn(String headline) {
    _lastWarn = DateTime.now();
    final buffer = StringBuffer(headline)
      ..writeln()
      ..writeln('  recent routes: ${breadcrumbs.recent.join(' | ')}')
      ..writeln('  image cache: ${_imageCacheSummary()}');
    final growers = _topGrowers();
    if (growers.isNotEmpty) {
      buffer.writeln('  objects still alive vs. baseline: $growers');
    } else if (!_tracking) {
      buffer.writeln('  (object tracking only runs in debug/profile builds)');
    }
    logger.warning(buffer.toString().trimRight(), tag: _tag);
  }

  String _imageCacheSummary() {
    final cache = PaintingBinding.instance.imageCache;
    final mb = (cache.currentSizeBytes / (1024 * 1024)).toStringAsFixed(1);
    return '${cache.currentSize} images, ${mb}MB, '
        '${cache.liveImageCount} live, ${cache.pendingImageCount} pending';
  }

  String _topGrowers() {
    if (!_tracking) return '';
    final deltas = <String, int>{};
    _live.forEach((type, count) {
      final d = count - (_baseline[type] ?? 0);
      if (d > 3) deltas[type] = d;
    });
    final top = deltas.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return top.take(8).map((e) => '${e.key} +${e.value}').join(', ');
  }
}
