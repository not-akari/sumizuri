import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/core/widgets/cards/app_list_row.dart';
import 'package:sumizuri/features/trackers/models/tracker_models.dart';
import 'package:sumizuri/features/trackers/pages/tracker_account_actions.dart';
import 'package:sumizuri/features/trackers/pages/tracker_account_page.dart';
import 'package:sumizuri/features/trackers/providers/tracker_providers.dart';
import 'package:sumizuri/features/trackers/widgets/tracker_kind_icon.dart';
import 'package:sumizuri/features/trackers/widgets/tracker_login_dialog.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

/// One tracker as a row of the profile: connect it, or open its account page.
class TrackerTile extends ConsumerWidget {
  const TrackerTile({super.key, required this.kind});

  final TrackerKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final account = ref.watch(trackerAccountProvider(kind));
    final backend = ref.watch(trackerBackendProvider(kind));
    final icon = trackerKindIcon(kind);

    return account.when(
      loading: () => AppListRow(
        icon: icon,
        title: kind.label,
        trailing: const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (_, _) => AppListRow(
        icon: icon,
        title: kind.label,
        subtitle: l10n.trackerLoadFailed(kind.label),
        onTap: () => refreshTracker(ref, kind),
      ),
      data: (info) {
        if (info == null && !backend.configured) {
          // A build made without the client key cannot log in.
          return AppListRow(
            icon: icon,
            iconColor: cs.error,
            title: kind.label,
            subtitle: l10n.trackerNotConfigured(kind.label),
          );
        }
        if (info == null) {
          return AppListRow(
            icon: icon,
            title: kind.label,
            subtitle: l10n.trackerNotConnected,
            trailing: Text(l10n.trackerConnect),
            onTap: () => showTrackerLoginDialog(context, kind),
          );
        }
        return AppListRow(
          icon: icon,
          title: kind.label,
          subtitle: l10n.trackerConnectedAs(info.name),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => TrackerAccountPage(kind: kind),
            ),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.link_off),
            tooltip: l10n.trackerDisconnectConfirm,
            onPressed: () => confirmTrackerDisconnect(context, ref, kind),
          ),
        );
      },
    );
  }
}
