import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:sumizuri/features/settings/providers/settings_providers.dart';
import 'package:sumizuri/features/settings/data/update_checker.dart';
import 'package:sumizuri/features/settings/providers/update_providers.dart';
import 'package:sumizuri/features/settings/widgets/update_prompt.dart';

class UpdateStartupCheck extends ConsumerStatefulWidget {
  const UpdateStartupCheck({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<UpdateStartupCheck> createState() => _UpdateStartupCheckState();
}

class _UpdateStartupCheckState extends ConsumerState<UpdateStartupCheck> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Delayed so the check never competes with startup work.
    _timer = Timer(const Duration(seconds: 20), _check);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _check() async {
    // Read straight from the repository: an auto-disposed provider can vanish mid-load.
    final enabled = await ref
        .read(settingsRepositoryProvider)
        .watchCheckForUpdatesOnStartup()
        .first;
    if (!enabled || !mounted) return;
    final info = await PackageInfo.fromPlatform();
    final result = await ref
        .read(updateCheckerProvider)
        .checkForUpdate(info.version);
    if (!mounted || result.status != UpdateCheckStatus.updateAvailable) return;
    _showDialog(result, info.version);
  }

  void _showDialog(UpdateCheckResult result, String current) {
    showUpdatePrompt(context, result, current);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
