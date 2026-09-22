import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'package:sumizuri/bootstrap/logging/app_logger.dart';

class RebuildCounter {
  RebuildCounter._();

  static final instance = RebuildCounter._();

  final _rebuilds = <String, int>{};
  final _firstBuilds = <String, int>{};
  DateTime? _startedAt;

  bool get isRunning => _startedAt != null;

  void start() {
    if (!kDebugMode || isRunning) return;
    _rebuilds.clear();
    _firstBuilds.clear();
    _startedAt = DateTime.now();
    debugOnRebuildDirtyWidget = (Element element, bool builtOnce) {
      final type = element.widget.runtimeType.toString();
      final target = builtOnce ? _rebuilds : _firstBuilds;
      target[type] = (target[type] ?? 0) + 1;
    };
  }

  void stopAndLog(AppLogger logger) {
    final started = _startedAt;
    if (started == null) return;
    debugOnRebuildDirtyWidget = null;
    _startedAt = null;

    String top(Map<String, int> counts) {
      final entries = counts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      return entries.take(20).map((e) => '${e.key} x${e.value}').join(', ');
    }

    final seconds = DateTime.now().difference(started).inSeconds;
    final total = _rebuilds.values.fold<int>(0, (a, b) => a + b);
    final buffer = StringBuffer(
      'Widget rebuilds over ${seconds}s: $total rebuilds of '
      '${_rebuilds.length} widget types',
    )..writeln();
    buffer.writeln('  most rebuilt: ${top(_rebuilds)}');
    if (_firstBuilds.isNotEmpty) {
      buffer.writeln('  newly built: ${top(_firstBuilds)}');
    }
    logger.warning(buffer.toString().trimRight(), tag: 'rebuild');
  }
}
