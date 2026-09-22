import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/features/trackers/providers/anilist_providers.dart';

class TrackerFlushRunner extends ConsumerStatefulWidget {
  const TrackerFlushRunner({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<TrackerFlushRunner> createState() => _TrackerFlushRunnerState();
}

class _TrackerFlushRunnerState extends ConsumerState<TrackerFlushRunner>
    with WidgetsBindingObserver {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tick = Timer.periodic(const Duration(minutes: 1), (_) => _flush());
    Timer(const Duration(seconds: 20), _flush);
  }

  @override
  void dispose() {
    _tick?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _flush(force: true);
    }
  }

  void _flush({bool force = false}) {
    if (!mounted) return;
    unawaited(ref.read(aniListSyncServiceProvider).flushAll(force: force));
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
