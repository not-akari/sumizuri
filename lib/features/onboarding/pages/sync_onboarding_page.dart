import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/core/widgets/ambient/ambient_bloom_background.dart';
import 'package:sumizuri/features/onboarding/widgets/onboarding_page_shell.dart';
import 'package:sumizuri/features/profile/providers/profile_providers.dart';
import 'package:sumizuri/features/sync/data/sync_api_client.dart';
import 'package:sumizuri/features/sync/models/sync_models.dart';
import 'package:sumizuri/features/sync/providers/sync_providers.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

enum _Stage { server, verifying, pick, syncing }

class SyncOnboardingPage extends ConsumerStatefulWidget {
  const SyncOnboardingPage({super.key});

  @override
  ConsumerState<SyncOnboardingPage> createState() => _SyncOnboardingPageState();
}

class _SyncOnboardingPageState extends ConsumerState<SyncOnboardingPage> {
  final _server = TextEditingController();
  _Stage _stage = _Stage.server;
  bool _waitingForBrowser = false;
  String? _error;
  List<SyncServerProfile> _profiles = const [];

  @override
  void dispose() {
    _server.dispose();
    super.dispose();
  }

  String? _addressProblem(AppLocalizations l10n) =>
      switch (SyncApiClient.addressProblem(_server.text)) {
        ServerAddressProblem.empty => l10n.onboardingSyncAddressEmpty,
        ServerAddressProblem.invalid => l10n.onboardingSyncAddressInvalid,
        null => null,
      };

  Future<void> _signIn() async {
    final l10n = AppLocalizations.of(context)!;
    final problem = _addressProblem(l10n);
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    setState(() {
      _waitingForBrowser = true;
      _error = null;
    });
    final signedIn = await ref
        .read(syncRepositoryProvider)
        .signIn(_server.text);
    if (!mounted) return;
    setState(() => _waitingForBrowser = false);
    final failure = signedIn.errorOrNull;
    if (failure != null) {
      setState(() => _error = failure.displayMessage);
      return;
    }
    ref.invalidate(syncAccountProvider);
    await _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _stage = _Stage.verifying;
      _error = null;
    });
    final result = await ref.read(syncRepositoryProvider).listServerProfiles();
    if (!mounted) return;
    final failure = result.errorOrNull;
    setState(() {
      if (failure != null) {
        _stage = _Stage.server;
        _error = l10n.onboardingSyncProfilesFailed(failure.displayMessage);
      } else {
        _profiles = result.valueOrNull ?? const [];
        _stage = _Stage.pick;
      }
    });
  }

  Future<void> _choose(SyncServerProfile? profile) async {
    final repository = ref.read(syncRepositoryProvider);
    final localName = ref.read(activeProfileProvider).value?.name;
    setState(() {
      _stage = _Stage.syncing;
      _error = null;
    });
    final linked = profile == null
        ? (await repository.createAndLinkProfile(
            localName ?? AppLocalizations.of(context)!.syncNewProfileName,
          )).errorOrNull
        : (await repository.linkProfile(profile)).errorOrNull;
    if (!mounted) return;
    if (linked != null) {
      setState(() {
        _stage = _Stage.pick;
        _error = linked.displayMessage;
      });
      return;
    }
    ref.invalidate(syncLinkedProfileProvider);
    await _sync();
  }

  Future<void> _sync() async {
    setState(() {
      _stage = _Stage.syncing;
      _error = null;
    });
    await ref.read(syncRunnerProvider.notifier).run(SyncMode.incremental);
    if (!mounted) return;
    final error = ref.read(syncRunnerProvider).error;
    if (error == null) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _error = error);
    }
  }

  void _leave() {
    if (_waitingForBrowser) ref.read(syncRepositoryProvider).cancelSignIn();
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: Stack(
        children: [
          const AmbientBloomBackground(),
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: TextButton.icon(
                      onPressed: _stage == _Stage.syncing ? null : _leave,
                      icon: const Icon(Icons.arrow_back, size: 18),
                      label: Text(l10n.onboardingBack),
                    ),
                  ),
                ),
                Expanded(
                  child: OnboardingPageShell(
                    icon: Icons.cloud_sync_outlined,
                    title: l10n.onboardingSyncTitle,
                    subtitle: l10n.onboardingSyncBody,
                    child: switch (_stage) {
                      _Stage.server => _serverStep(l10n),
                      _Stage.verifying => _Busy(l10n.onboardingSyncVerifying),
                      _Stage.pick => _pickStep(l10n),
                      _Stage.syncing => _syncingStep(l10n),
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorText(BuildContext context) {
    if (_error == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(
        _error!,
        textAlign: TextAlign.center,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    );
  }

  Widget _serverStep(AppLocalizations l10n) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _server,
          enabled: !_waitingForBrowser,
          keyboardType: TextInputType.url,
          autofocus: true,
          decoration: InputDecoration(
            labelText: l10n.syncServerLabel,
            hintText: 'sync.example.com',
          ),
          onSubmitted: (_) => _signIn(),
        ),
        const SizedBox(height: 8),
        Text(l10n.syncBrowserSignInHint, style: textTheme.bodySmall),
        _errorText(context),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _waitingForBrowser ? null : _signIn,
          icon: const Icon(Icons.open_in_browser),
          label: Text(
            _waitingForBrowser
                ? l10n.syncWaitingForBrowser
                : l10n.syncSignInWithBrowser,
          ),
        ),
        if (_waitingForBrowser)
          TextButton(
            onPressed: () => ref.read(syncRepositoryProvider).cancelSignIn(),
            child: Text(l10n.syncCancel),
          ),
      ],
    );
  }

  Widget _pickStep(AppLocalizations l10n) {
    final localName =
        ref.watch(activeProfileProvider).value?.name ?? l10n.syncNewProfileName;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _profiles.isEmpty
              ? l10n.onboardingSyncNoProfiles
              : l10n.onboardingSyncPickBody,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        for (final profile in _profiles)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OutlinedButton(
              onPressed: () => _choose(profile),
              child: Text(profile.name),
            ),
          ),
        FilledButton.icon(
          onPressed: () => _choose(null),
          icon: const Icon(Icons.add),
          label: Text('${l10n.syncCreateProfileButton} ($localName)'),
        ),
        _errorText(context),
      ],
    );
  }

  Widget _syncingStep(AppLocalizations l10n) {
    final run = ref.watch(syncRunnerProvider);
    if (_error != null && !run.running) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${l10n.syncFailed}: $_error',
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: _sync, child: Text(l10n.onboardingSyncRetry)),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.onboardingSyncContinueAnyway),
          ),
        ],
      );
    }
    return Column(
      children: [
        Text(l10n.onboardingSyncDownloading),
        const SizedBox(height: 16),
        LinearProgressIndicator(value: run.progress?.fraction),
      ],
    );
  }
}

class _Busy extends StatelessWidget {
  const _Busy(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      const CircularProgressIndicator(),
      const SizedBox(height: 16),
      Text(label),
    ],
  );
}
