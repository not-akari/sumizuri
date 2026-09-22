import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:sumizuri/bootstrap/logging/app_logger.dart';

/// Times steps before first screen and broadcasts them for live overlay.
class StartupTimer {
  StartupTimer._();

  static final instance = StartupTimer._();

  final _clock = Stopwatch();
  final _steps = <(String, int)>[];
  final _stepController = StreamController<(String, int)>.broadcast();
  bool _finished = false;

  void start() {
    if (!_clock.isRunning) _clock.start();
  }

  /// Notes that step is done, with the time since the app started.
  void mark(String step) {
    if (_finished) return;
    final entry = (step, _clock.elapsedMilliseconds);
    _steps.add(entry);
    _stepController.add(entry);
    debugPrint('startup: $step at ${_clock.elapsedMilliseconds} ms');
  }

  bool get finished => _finished;

  /// Steps recorded before a listener starts for historical replay.
  List<(String, int)> get stepsSoFar => List.unmodifiable(_steps);

  /// Broadcast stream of steps as they complete.
  Stream<(String, int)> get onStep => _stepController.stream;

  /// What starting has done so far, for a report.
  String get progress =>
      'Started ${_clock.elapsedMilliseconds} ms ago. Steps done: ${_steps.map((s) => '${s.$1} (${s.$2} ms)').join(', ')}.';

  /// Writes the steps to the log once, as a warning when the start was slow.
  void finish(AppLogger logger) {
    if (_finished) return;
    mark('first screen');
    _finished = true;
    final total = _clock.elapsedMilliseconds;
    final buffer = StringBuffer('Start took $total ms:');
    var previous = 0;
    for (final (step, at) in _steps) {
      buffer.write(' $step +${at - previous} ms;');
      previous = at;
    }
    final message = buffer.toString();
    if (total > 2500) {
      logger.warning(message, tag: 'startup');
    } else {
      logger.info(message, tag: 'startup');
    }
    unawaited(_stepController.close());
  }
}

/// One named unit of start-up work run sequentially by [runStartupSteps].
class StartupStep {
  const StartupStep(this.name, this.action);

  final String name;
  final Future<void> Function() action;
}

/// Runs [steps] one after another, marking each done as it finishes.
Future<void> runStartupSteps(List<StartupStep> steps) async {
  for (final step in steps) {
    await step.action();
    StartupTimer.instance.mark(step.name);
  }
}
