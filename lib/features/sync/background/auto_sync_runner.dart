import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/features/profile/providers/profile_providers.dart';
import 'package:sumizuri/features/sync/background/background_sync.dart';
import 'package:sumizuri/features/sync/models/sync_models.dart';
import 'package:sumizuri/features/sync/providers/sync_providers.dart';

class AutoSyncRunner extends ConsumerStatefulWidget {
  const AutoSyncRunner({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AutoSyncRunner> createState() => _AutoSyncRunnerState();
}

class _AutoSyncRunnerState extends ConsumerState<AutoSyncRunner>
    with WidgetsBindingObserver {
  Timer? _launchTimer;
  Timer? _tick;

  final Map<int, int> _lastAttempt = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Delayed a moment so the first frames are not competing with it.
    _launchTimer = Timer(
      const Duration(seconds: 3),
      () => unawaited(_check(launch: true)),
    );
    _tick = Timer.periodic(const Duration(minutes: 1), (_) {
      unawaited(markForegroundActive());
      unawaited(_check());
    });
    unawaited(markForegroundActive());
    unawaited(reconcileBackgroundSync(ref.read(syncRepositoryProvider)));
  }

  @override
  void dispose() {
    _launchTimer?.cancel();
    _tick?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(markForegroundActive());
      unawaited(_check());
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(markForegroundInactive());
    }
  }

  Future<void> _check({bool launch = false}) async {
    if (!mounted) return;
    final repository = ref.read(syncRepositoryProvider);
    if (await repository.linkedProfile() == null) return;
    final preferences = await repository.preferences();
    final profileId = ref.read(currentProfileIdProvider);
    final now = DateTime.now().millisecondsSinceEpoch;
    final last = await repository.lastSyncedAt();
    final reference = last > (_lastAttempt[profileId] ?? 0)
        ? last
        : _lastAttempt[profileId] ?? 0;

    final timerDue =
        preferences.intervalMinutes > 0 &&
        now - reference >=
            preferences.intervalMinutes * Duration.millisecondsPerMinute;
    if (!timerDue && !(launch && preferences.syncOnLaunch)) return;
    if (!mounted) return;

    _lastAttempt[profileId] = now;
    await ref
        .read(syncRunnerProvider.notifier)
        .run(SyncMode.incremental, auto: true);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
