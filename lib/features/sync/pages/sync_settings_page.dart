import 'dart:async';

import 'package:sumizuri/features/settings/widgets/settings_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:sumizuri/core/widgets/controls/app_choice.dart';
import 'package:sumizuri/core/widgets/cards/app_list_row.dart';
import 'package:sumizuri/core/widgets/overlays/dialog_with_controller.dart';
import 'package:sumizuri/core/widgets/controls/settings_controls.dart';
import 'package:sumizuri/features/profile/providers/profile_providers.dart';
import 'package:sumizuri/features/sync/background/background_sync.dart';
import 'package:sumizuri/features/sync/models/sync_models.dart';
import 'package:sumizuri/features/sync/providers/sync_providers.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

part 'sync_settings_profile_picker.dart';
part 'sync_settings_panel.dart';

const _intervalChoicesMinutes = [0, 15, 30, 60, 180, 360, 720, 1440];

class SyncSettingsPage extends ConsumerWidget {
  const SyncSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final account = ref.watch(syncAccountProvider);
    final linked = ref.watch(syncLinkedProfileProvider);
    final profile = ref.watch(activeProfileProvider).value;

    Widget body(SyncAccount? signedIn) {
      if (signedIn == null) return const _SignIn();
      return linked.when(
        data: (link) => link == null
            ? _ProfilePicker(signedIn)
            : _SyncPanel(signedIn, link),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _ProfilePicker(signedIn),
      );
    }

    return SettingsScaffold(
      title: Text(l10n.syncTitle),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          if (profile != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                l10n.syncProfileNote(profile.name),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          account.when(
            data: body,
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => const _SignIn(),
          ),
        ],
      ),
    );
  }
}

class _SignIn extends ConsumerStatefulWidget {
  const _SignIn();

  @override
  ConsumerState<_SignIn> createState() => _SignInState();
}

class _SignInState extends ConsumerState<_SignIn> {
  final _server = TextEditingController();
  bool _waiting = false;
  String? _error;

  @override
  void dispose() {
    _server.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() {
      _waiting = true;
      _error = null;
    });
    final result = await ref.read(syncRepositoryProvider).signIn(_server.text);
    if (!mounted) return;
    setState(() {
      _waiting = false;
      _error = result.errorOrNull?.displayMessage;
    });
    if (result.isOk) {
      ref.invalidate(syncAccountProvider);
      ref.invalidate(syncLinkedProfileProvider);
      ref.invalidate(syncServerProfilesProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.syncSubtitle, style: textTheme.bodyMedium),
        const SizedBox(height: 16),
        TextField(
          controller: _server,
          enabled: !_waiting,
          keyboardType: TextInputType.url,
          decoration: InputDecoration(
            labelText: l10n.syncServerLabel,
            hintText: 'http://192.168.1.10:3000',
          ),
          onSubmitted: (_) => _signIn(),
        ),
        const SizedBox(height: 8),
        Text(l10n.syncBrowserSignInHint, style: textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(l10n.syncNewAccountHint, style: textTheme.bodySmall),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _waiting ? null : _signIn,
          icon: const Icon(Icons.open_in_browser),
          label: Text(
            _waiting ? l10n.syncWaitingForBrowser : l10n.syncSignInWithBrowser,
          ),
        ),
        if (_waiting)
          TextButton(
            onPressed: () => ref.read(syncRepositoryProvider).cancelSignIn(),
            child: Text(l10n.syncCancel),
          ),
      ],
    );
  }
}
