import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/core/widgets/cards/app_list_row.dart';
import 'package:sumizuri/core/widgets/overlays/confirm_dialog.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';
import 'package:sumizuri/features/trackers/pages/anilist_account_page.dart';
import 'package:sumizuri/features/trackers/providers/anilist_providers.dart';
import 'package:sumizuri/features/trackers/data/tracker_client_config.dart';
import 'package:sumizuri/features/trackers/widgets/anilist_login_dialog.dart';

class AniListTrackerTile extends ConsumerWidget {
  const AniListTrackerTile({super.key});

  Future<void> _connect(BuildContext context, WidgetRef ref) =>
      showAniListLoginDialog(context);

  Future<void> _disconnect(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: l10n.aniListDisconnectTitle,
      message: l10n.aniListDisconnectMessage,
      confirmLabel: l10n.aniListDisconnectConfirm,
      cancelLabel: l10n.browseAddWarningCancel,
      isDestructive: true,
    );
    if (confirmed) {
      await ref.read(aniListAccountProvider.notifier).logout();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final accountAsync = ref.watch(aniListAccountProvider);

    return accountAsync.when(
      loading: () => const AppListRow(
        icon: Icons.auto_awesome_outlined,
        title: 'AniList',
        trailing: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (_, _) => AppListRow(
        icon: Icons.auto_awesome_outlined,
        title: 'AniList',
        subtitle: l10n.aniListLoadFailed,
        onTap: () => _connect(context, ref),
      ),
      data: (account) => account == null && !aniListConfigured
          // A build made without the AniList secret cannot log in.
          ? AppListRow(
              icon: Icons.auto_awesome_outlined,
              title: 'AniList',
              subtitle: l10n.aniListNotConfigured,
              iconColor: Theme.of(context).colorScheme.error,
            )
          : account == null
          ? AppListRow(
              icon: Icons.auto_awesome_outlined,
              title: 'AniList',
              subtitle: l10n.aniListNotConnected,
              trailing: Text(l10n.aniListConnect),
              onTap: () => _connect(context, ref),
            )
          : AppListRow(
              icon: Icons.auto_awesome_outlined,
              title: 'AniList',
              subtitle: l10n.aniListConnectedAs(account.name),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const AniListAccountPage(),
                ),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.link_off),
                tooltip: l10n.aniListDisconnectConfirm,
                onPressed: () => _disconnect(context, ref),
              ),
            ),
    );
  }
}
