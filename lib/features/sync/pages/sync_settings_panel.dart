part of 'sync_settings_page.dart';

class _SyncPanel extends ConsumerWidget {
  const _SyncPanel(this.account, this.linked);

  final SyncAccount account;
  final SyncServerProfile linked;

  String _intervalLabel(AppLocalizations l10n, int minutes) =>
      switch (minutes) {
        0 => l10n.syncIntervalOff,
        15 => l10n.syncInterval15m,
        30 => l10n.syncInterval30m,
        60 => l10n.syncInterval1h,
        180 => l10n.syncInterval3h,
        360 => l10n.syncInterval6h,
        720 => l10n.syncInterval12h,
        _ => l10n.syncInterval24h,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final run = ref.watch(syncRunnerProvider);
    final runner = ref.read(syncRunnerProvider.notifier);
    final lastSynced = ref.watch(lastSyncedAtProvider).value ?? 0;
    final preferences =
        ref.watch(syncPreferencesProvider).value ?? const SyncPreferences();
    final repository = ref.read(syncRepositoryProvider);
    final textTheme = Theme.of(context).textTheme;

    Future<void> save(SyncPreferences next) async {
      await repository.setPreferences(next);
      ref.invalidate(syncPreferencesProvider);
      await reconcileBackgroundSync(repository);
    }

    final lastLine = lastSynced == 0
        ? l10n.syncNeverSynced
        : l10n.syncLastSynced(
            DateFormat.yMMMd().add_jm().format(
              DateTime.fromMillisecondsSinceEpoch(lastSynced),
            ),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionLabel(label: l10n.syncSectionAccount),
        Text(l10n.syncSignedInAs(account.username)),
        Text(account.server, style: textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(l10n.syncLinkedTo(linked.name)),
        Text(lastLine, style: textTheme.bodySmall),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: run.running
              ? null
              : () => runner.run(SyncMode.incremental),
          icon: const Icon(Icons.sync),
          label: Text(run.running ? l10n.syncRunning : l10n.syncNow),
        ),
        if (run.running) ...[
          const SizedBox(height: 12),
          LinearProgressIndicator(value: run.progress?.fraction),
        ],
        if (run.error != null) ...[
          const SizedBox(height: 12),
          Text(
            '${l10n.syncFailed}: ${run.error}',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 24),
        AppSectionLabel(label: l10n.syncAutoTitle),
        AppChoice<int>.of(
          padded: true,
          style: AppChoiceStyle.pills,
          values: _intervalChoicesMinutes,
          label: (minutes) => _intervalLabel(l10n, minutes),
          icon: (minutes) =>
              minutes == 0 ? Icons.timer_off_outlined : Icons.timer_outlined,
          value: preferences.intervalMinutes,
          onChanged: (minutes) =>
              save(preferences.copyWith(intervalMinutes: minutes)),
        ),
        AppSwitchRow(
          icon: Icons.rocket_launch_outlined,
          title: l10n.syncOnLaunch,
          value: preferences.syncOnLaunch,
          onChanged: (on) => save(preferences.copyWith(syncOnLaunch: on)),
        ),
        if (backgroundSyncSupported)
          AppSwitchRow(
            icon: Icons.cloud_sync_outlined,
            title: l10n.syncInBackground,
            subtitle: preferences.intervalMinutes == 0
                ? l10n.syncInBackgroundNeedsTimer
                : l10n.syncInBackgroundHint,
            value: preferences.backgroundSync,
            onChanged: preferences.intervalMinutes == 0
                ? null
                : (on) => save(preferences.copyWith(backgroundSync: on)),
          ),
        const SizedBox(height: 24),
        AppSectionLabel(label: l10n.syncAdvancedLabel),
        _AdvancedAction(
          title: l10n.syncUploadOnly,
          hint: l10n.syncUploadOnlyHint,
          onPressed: run.running ? null : () => runner.run(SyncMode.uploadOnly),
        ),
        _AdvancedAction(
          title: l10n.syncDownloadOnly,
          hint: l10n.syncDownloadOnlyHint,
          onPressed: run.running
              ? null
              : () => runner.run(SyncMode.downloadOnly),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: run.running
              ? null
              : () async {
                  await repository.unlinkProfile();
                  await reconcileBackgroundSync(repository);
                  ref.invalidate(syncLinkedProfileProvider);
                  ref.invalidate(lastSyncedAtProvider);
                  ref.invalidate(syncPreferencesProvider);
                },
          child: Text(l10n.syncStopSyncingProfile),
        ),
        TextButton(
          onPressed: run.running
              ? null
              : () async {
                  await repository.signOut();
                  ref.invalidate(syncAccountProvider);
                  ref.invalidate(syncLinkedProfileProvider);
                  ref.invalidate(syncPreferencesProvider);
                },
          child: Text(l10n.syncSignOut),
        ),
      ],
    );
  }
}

class _AdvancedAction extends StatelessWidget {
  const _AdvancedAction({
    required this.title,
    required this.hint,
    required this.onPressed,
  });

  final String title;
  final String hint;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OutlinedButton(onPressed: onPressed, child: Text(title)),
          const SizedBox(height: 4),
          Text(hint, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

Future<String?> _askProfileName(BuildContext context, String suggestion) {
  final l10n = AppLocalizations.of(context)!;
  return showAppTextFieldDialog(
    context: context,
    title: l10n.syncNameProfileTitle,
    initialText: suggestion,
    label: l10n.syncProfileNameLabel,
    maxLength: 100,
    confirmLabel: l10n.syncCreate,
    cancelLabel: l10n.syncCancel,
  ).then((value) => value == null || value.isEmpty ? null : value);
}
