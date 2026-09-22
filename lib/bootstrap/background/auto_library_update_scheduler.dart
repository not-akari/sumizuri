import 'dart:async';

import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sumizuri/features/library/background/background_library_update.dart';
import 'package:sumizuri/features/library/flows/library_update_flow.dart';
import 'package:sumizuri/features/settings/providers/settings_providers.dart';

class AutoLibraryUpdateScheduler extends StatefulWidget {
  const AutoLibraryUpdateScheduler({super.key, required this.child});

  final Widget child;

  @override
  State<AutoLibraryUpdateScheduler> createState() =>
      _AutoLibraryUpdateSchedulerState();
}

class _AutoLibraryUpdateSchedulerState extends State<AutoLibraryUpdateScheduler>
    with WidgetsBindingObserver {
  Timer? _initTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _initTimer = Timer(const Duration(seconds: 5), () {
      _check();
      _reconcileBackground();
    });
  }

  @override
  void dispose() {
    _initTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
    if (state == AppLifecycleState.paused) _reconcileBackground();
  }

  void _reconcileBackground() {
    if (!mounted) return;
    final container = ProviderScope.containerOf(context, listen: false);
    unawaited(
      reconcileBackgroundLibraryUpdate(
        container.read(settingsRepositoryProvider),
      ),
    );
  }

  void _check() {
    if (!mounted) return;
    unawaited(
      autoUpdateLibraryIfDue(ProviderScope.containerOf(context, listen: false)),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
