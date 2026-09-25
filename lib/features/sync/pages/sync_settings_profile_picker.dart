part of 'sync_settings_page.dart';

class _ProfilePicker extends ConsumerStatefulWidget {
  const _ProfilePicker(this.account);

  final SyncAccount account;

  @override
  ConsumerState<_ProfilePicker> createState() => _ProfilePickerState();
}

class _ProfilePickerState extends ConsumerState<_ProfilePicker> {
  bool _busy = false;
  String? _error;

  Future<void> _finish(Future<String?> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final failure = await action();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = failure;
    });
    if (failure == null) {
      ref.invalidate(syncLinkedProfileProvider);
      ref.invalidate(lastSyncedAtProvider);
      ref.invalidate(syncPreferencesProvider);
      unawaited(
        ref.read(syncRunnerProvider.notifier).run(SyncMode.incremental),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final repository = ref.read(syncRepositoryProvider);
    final localName = ref.watch(activeProfileProvider).value?.name ?? '';
    final profiles = ref.watch(syncServerProfilesProvider);
    final textTheme = Theme.of(context).textTheme;
    final errorColor = Theme.of(context).colorScheme.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionLabel(label: l10n.syncSectionAccount),
        Text(l10n.syncSignedInAs(widget.account.username)),
        Text(widget.account.server, style: textTheme.bodySmall),
        const SizedBox(height: 16),
        Text(l10n.syncChooseProfile, style: textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(l10n.syncChooseProfileHint, style: textTheme.bodySmall),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: _busy || profiles.isLoading
                ? null
                : () => ref.invalidate(syncServerProfilesProvider),
            icon: const Icon(Icons.refresh, size: 18),
            label: Text(l10n.syncRefresh),
          ),
        ),
        profiles.when(
          data: (list) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final profile in list)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: OutlinedButton(
                    onPressed: _busy
                        ? null
                        : () => _finish(() async {
                            final result = await repository.linkProfile(
                              profile,
                            );
                            return result.errorOrNull?.displayMessage;
                          }),
                    child: Text(profile.name),
                  ),
                ),
              FilledButton.icon(
                onPressed: _busy
                    ? null
                    : () async {
                        final name = await _askProfileName(
                          context,
                          localName.isEmpty
                              ? l10n.syncNewProfileName
                              : localName,
                        );
                        if (name == null || !mounted) return;
                        await _finish(() async {
                          final result = await repository.createAndLinkProfile(
                            name,
                          );
                          if (mounted) {
                            ref.invalidate(syncServerProfilesProvider);
                          }
                          return result.errorOrNull?.displayMessage;
                        });
                      },
                icon: const Icon(Icons.add),
                label: Text(l10n.syncCreateProfileButton),
              ),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) =>
              Text('$error', style: TextStyle(color: errorColor)),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: TextStyle(color: errorColor)),
        ],
        const SizedBox(height: 16),
        TextButton(
          onPressed: _busy
              ? null
              : () async {
                  await repository.signOut();
                  await reconcileBackgroundSync(repository);
                  if (!mounted) return;
                  ref.invalidate(syncAccountProvider);
                  ref.invalidate(syncLinkedProfileProvider);
                },
          child: Text(l10n.syncSignOut),
        ),
      ],
    );
  }
}
