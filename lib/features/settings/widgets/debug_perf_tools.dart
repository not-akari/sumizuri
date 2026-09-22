// Debug-only rows: a jank simulator to try the fps watchdog.
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/bootstrap/logging/logger_provider.dart';
import 'package:sumizuri/bootstrap/monitoring/rebuild_counter.dart';
import 'package:sumizuri/core/widgets/cards/app_list_row.dart';
import 'package:sumizuri/core/widgets/controls/settings_controls.dart';

void _busyWait(int milliseconds) {
  final watch = Stopwatch()..start();
  while (watch.elapsedMilliseconds < milliseconds) {}
}

class DebugJankSimulatorRows extends StatefulWidget {
  const DebugJankSimulatorRows({super.key});

  @override
  State<DebugJankSimulatorRows> createState() => _DebugJankSimulatorRowsState();
}

class _DebugJankSimulatorRowsState extends State<DebugJankSimulatorRows>
    with SingleTickerProviderStateMixin {
  static const _smooth = Duration(seconds: 5);
  static const _janky = Duration(seconds: 5);

  Ticker? _ticker;
  bool get _running => _ticker != null;

  // Smooth frames first so the watchdog has an average to fall below, then slow ones.
  void _startSustained() {
    _ticker = createTicker((elapsed) {
      if (elapsed >= _smooth + _janky) {
        _stop();
        return;
      }
      if (elapsed >= _smooth) _busyWait(25);
    })..start();
    setState(() {});
  }

  void _stop() {
    _ticker?.dispose();
    _ticker = null;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppListRow(
          icon: Icons.ac_unit,
          title: 'Freeze the UI for 300ms (debug only)',
          subtitle: 'Should log a "Slow frame" under Logs → FPS.',
          onTap: () => _busyWait(300),
        ),
        AppSwitchRow(
          icon: Icons.speed_outlined,
          title: 'Simulate sustained jank (debug only)',
          subtitle: _running ? 'Running: 5s smooth, then 5s of slow frames.' : '5s smooth then 5s slow. Should log "FPS dropped" under Logs → FPS.',
          value: _running,
          onChanged: (on) => on ? _startSustained() : _stop(),
        ),
      ],
    );
  }
}

class DebugRebuildCounterRow extends ConsumerStatefulWidget {
  const DebugRebuildCounterRow({super.key});

  @override
  ConsumerState<DebugRebuildCounterRow> createState() =>
      _DebugRebuildCounterRowState();
}

class _DebugRebuildCounterRowState
    extends ConsumerState<DebugRebuildCounterRow> {
  @override
  Widget build(BuildContext context) {
    final counter = RebuildCounter.instance;
    return AppSwitchRow(
      icon: Icons.account_tree_outlined,
      title: 'Count widget rebuilds (debug only)',
      subtitle: counter.isRunning
          ? 'Counting. Do something, then switch off to log the totals under Logs → Rebuilds.'
          : 'Switch on, change a setting, switch off to see which widgets rebuilt.',
      value: counter.isRunning,
      onChanged: (on) {
        if (on) {
          counter.start();
        } else {
          counter.stopAndLog(ref.read(appLoggerProvider));
        }
        setState(() {});
      },
    );
  }
}
