import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/bootstrap/logging/logger_provider.dart';
import 'package:sumizuri/features/settings/data/backup_preferences.dart';
import 'package:sumizuri/features/settings/flows/backup_service.dart';

class AutoBackupRunner extends ConsumerStatefulWidget {
  const AutoBackupRunner({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AutoBackupRunner> createState() => _AutoBackupRunnerState();
}

class _AutoBackupRunnerState extends ConsumerState<AutoBackupRunner> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Delayed so it never competes with startup work.
    _timer = Timer(const Duration(seconds: 45), _runIfDue);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _runIfDue() async {
    if (!mounted) return;
    final prefs = await ref.read(backupPreferencesProvider.future);
    if (!prefs.isDue || !mounted) return;
    try {
      await ref.read(backupServiceProvider).writeAuto(keep: prefs.keep);
      await ref
          .read(backupPreferencesProvider.notifier)
          .change((p) => p.copyWith(lastAt: DateTime.now()));
    } catch (error, stack) {
      ref
          .read(appLoggerProvider)
          .warning(
            'Automatic backup failed',
            tag: 'backup',
            error: error,
            stackTrace: stack,
          );
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
