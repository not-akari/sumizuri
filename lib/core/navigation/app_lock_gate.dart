import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sumizuri/core/widgets/feedback/loading_screen.dart';
import 'package:sumizuri/features/security/pages/app_lock_screen.dart';
import 'package:sumizuri/features/settings/providers/settings_providers.dart';

/// Overlays the lock screen on top of currently rendered navigation output.
class AppLockGate extends ConsumerStatefulWidget {
  const AppLockGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate>
    with WidgetsBindingObserver {
  bool _unlockedThisSession = false;
  DateTime? _pausedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedAt = DateTime.now();
      final graceMinutes =
          ref.read(appLockGracePeriodMinutesProvider).value ?? 0;
      if (graceMinutes == 0 && mounted) {
        setState(() => _unlockedThisSession = false);
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_unlockedThisSession && _pausedAt != null) {
        final graceMinutes =
            ref.read(appLockGracePeriodMinutesProvider).value ?? 0;
        if (graceMinutes > 0) {
          final elapsed = DateTime.now().difference(_pausedAt!);
          if (elapsed >= Duration(minutes: graceMinutes)) {
            if (mounted) {
              setState(() => _unlockedThisSession = false);
            }
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lockEnabledAsync = ref.watch(appLockEnabledProvider);
    // Fail closed (block) while lock state is initializing on startup.
    final stillLoading =
        lockEnabledAsync.isLoading && !lockEnabledAsync.hasValue;
    final lockEnabled = lockEnabledAsync.value ?? false;
    final locked = stillLoading || (lockEnabled && !_unlockedThisSession);

    return Stack(
      children: [
        widget.child,
        if (locked)
          Positioned.fill(
            child: stillLoading
                ? const LoadingScreen()
                : AppLockScreen(
                    onUnlocked: () => setState(() {
                      _unlockedThisSession = true;
                      _pausedAt = null;
                    }),
                  ),
          ),
      ],
    );
  }
}
