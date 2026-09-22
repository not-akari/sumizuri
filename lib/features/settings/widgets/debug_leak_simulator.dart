// Debug only tool that leaks memory on purpose to try the watchdog and log viewer.
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/bootstrap/monitoring/memory_watchdog.dart';
import 'package:sumizuri/core/widgets/cards/app_list_row.dart';

class LeakSimulator {
  LeakSimulator._();

  static final instance = LeakSimulator._();

  Timer? _timer;
  final _buffers = <Uint8List>[];
  final _controllers = <TextEditingController>[];
  final _focusNodes = <FocusNode>[];

  bool get isRunning => _timer != null;
  int get leakedMb => _buffers.length * 6;

  void start() {
    if (_timer != null) return;
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      // Fill touches every page, otherwise the OS may not count it in RSS.
      _buffers.add(
        Uint8List(6 * 1024 * 1024)..fillRange(0, 6 * 1024 * 1024, 1),
      );
      for (var i = 0; i < 10; i++) {
        _controllers.add(TextEditingController());
        _focusNodes.add(FocusNode());
      }
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _buffers.clear();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _controllers.clear();
    _focusNodes.clear();
  }
}

// Fast enough to see a warning within about 30 seconds of starting.
const _fastConfig = MemoryWatchdogConfig(
  sampleInterval: Duration(seconds: 2),
  warmupSamples: 3,
  windowSamples: 8,
  growthWarnMb: 60,
  warnCooldown: Duration(seconds: 20),
);

class DebugLeakSimulatorRow extends ConsumerStatefulWidget {
  const DebugLeakSimulatorRow({super.key});

  @override
  ConsumerState<DebugLeakSimulatorRow> createState() =>
      _DebugLeakSimulatorRowState();
}

class _DebugLeakSimulatorRowState extends ConsumerState<DebugLeakSimulatorRow> {
  Timer? _refresh;

  @override
  void initState() {
    super.initState();
    _refresh = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && LeakSimulator.instance.isRunning) setState(() {});
    });
  }

  @override
  void dispose() {
    _refresh?.cancel();
    super.dispose();
  }

  void _toggle(bool on) {
    final watchdog = ref.read(memoryWatchdogProvider);
    final sim = LeakSimulator.instance;
    if (on) {
      watchdog.applyConfig(_fastConfig);
      sim.start();
    } else {
      sim.stop();
      watchdog.applyConfig(MemoryWatchdogConfig.standard);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final sim = LeakSimulator.instance;
    return AppListRow(
      icon: Icons.memory_outlined,
      title: 'Simulate memory leak (debug only)',
      subtitle: sim.isRunning
          ? 'Leaking ~12MB/s, ${sim.leakedMb}MB so far. Watch Logs → Memory.'
          : 'Leaks memory and speeds up the watchdog so a warning appears in ~30s.',
      trailing: Switch(value: sim.isRunning, onChanged: _toggle),
    );
  }
}
