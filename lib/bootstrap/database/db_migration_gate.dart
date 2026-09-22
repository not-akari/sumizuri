import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:sumizuri/core/widgets/feedback/loading_screen.dart';
import 'package:sumizuri/features/settings/data/db_file_backup.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

enum DbGateState { checking, promptBackup, backingUp, ready }

class DbMigrationGate extends StatefulWidget {
  const DbMigrationGate({super.key, required this.child});

  final Widget child;

  @override
  State<DbMigrationGate> createState() => _DbMigrationGateState();
}

class _DbMigrationGateState extends State<DbMigrationGate> {
  DbGateState _state = DbGateState.checking;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    if (Platform.environment['FLUTTER_TEST'] == 'true') {
      if (mounted) setState(() => _state = DbGateState.ready);
      return;
    }
    // A locked file means the app is opening it now, so an unreadable version can be ignored.
    int? pending;
    try {
      pending = await pendingMigrationFromVersion();
    } on Object {
      pending = null;
    }
    if (!mounted) return;

    if (pending != null) FlutterNativeSplash.remove();
    setState(
      () => _state = pending == null
          ? DbGateState.ready
          : DbGateState.promptBackup,
    );
  }

  Future<void> _choose(bool backUp) async {
    if (!backUp) {
      setState(() => _state = DbGateState.ready);
      return;
    }
    setState(() => _state = DbGateState.backingUp);
    await backUpDatabaseNow();
    if (!mounted) return;
    setState(() => _state = DbGateState.ready);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),

      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: KeyedSubtree(
        key: ValueKey(_state),
        child: switch (_state) {
          DbGateState.checking => const LoadingScreen(),
          DbGateState.promptBackup => DbMigrationPrompt(onChoice: _choose),
          DbGateState.backingUp => const DbBackingUpScreen(),
          DbGateState.ready => widget.child,
        },
      ),
    );
  }
}

class DbMigrationPrompt extends StatelessWidget {
  const DbMigrationPrompt({super.key, required this.onChoice});

  final ValueChanged<bool> onChoice;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.storage_outlined,
                    size: 40,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.dbMigrationTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.dbMigrationMessage,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => onChoice(true),
                      child: Text(l10n.dbMigrationBackUpAndContinue),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => onChoice(false),
                      child: Text(l10n.dbMigrationSkipAndContinue),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DbBackingUpScreen extends StatelessWidget {
  const DbBackingUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(l10n.dbMigrationBackingUp),
          ],
        ),
      ),
    );
  }
}
