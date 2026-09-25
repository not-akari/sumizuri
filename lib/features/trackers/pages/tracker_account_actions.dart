import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/core/widgets/controls/settings_controls.dart';
import 'package:sumizuri/core/widgets/overlays/confirm_dialog.dart';
import 'package:sumizuri/features/library/migration/migration_prompt.dart';
import 'package:sumizuri/features/trackers/models/tracker_models.dart';
import 'package:sumizuri/features/trackers/providers/tracker_actions.dart';
import 'package:sumizuri/features/trackers/widgets/tracker_problem_text.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

/// 8590 as 8,590.
String trackerGrouped(int value) => value.toString().replaceAllMapped(
  RegExp(r'\B(?=(\d{3})+(?!\d))'),
  (_) => ',',
);

/// Forgets everything read from the tracker, so the pages load it again.
void refreshTracker(WidgetRef ref, TrackerKind kind) =>
    ref.read(trackerActionsProvider(kind)).refresh();

// The functions below start work that outlives the page. They take what they
// need from `ref` before the first `await` and never touch it again: a page
// closed half way must not make them fail.

/// Asks, then logs out of the tracker. True when the account was disconnected.
Future<bool> confirmTrackerDisconnect(
  BuildContext context,
  WidgetRef ref,
  TrackerKind kind,
) async {
  final l10n = AppLocalizations.of(context)!;
  final actions = ref.read(trackerActionsProvider(kind));
  final confirmed = await showAppConfirmDialog(
    context: context,
    title: l10n.trackerDisconnectTitle(kind.label),
    message: l10n.trackerDisconnectMessage(kind.label),
    confirmLabel: l10n.trackerDisconnectConfirm,
    cancelLabel: l10n.browseAddWarningCancel,
    isDestructive: true,
  );
  if (!confirmed) return false;
  await actions.disconnect();
  return true;
}

/// Adds [entries] to the library and offers to move them to a source.
Future<void> importTrackerTitles(
  BuildContext context,
  WidgetRef ref,
  TrackerKind kind,
  List<TrackerEntry> entries,
) async {
  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  final actions = ref.read(trackerActionsProvider(kind));
  messenger.showSnackBar(SnackBar(content: Text(l10n.trackerImportRunning)));
  try {
    final result = await actions.import(entries);
    messenger.hideCurrentSnackBar();
    if (!context.mounted) return;
    showMigratePrompt(
      context,
      l10n.trackerImportDone(result.added, result.skipped, result.failed),
      result.addedIds,
    );
  } catch (error) {
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          l10n.trackerLoadListFailed(trackerReason(l10n, kind, error)),
        ),
      ),
    );
  }
}

/// Lets the person pick which of the two lists to import, then imports them.
Future<void> importTrackerLists(
  BuildContext context,
  WidgetRef ref,
  TrackerKind kind,
) async {
  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  final actions = ref.read(trackerActionsProvider(kind));
  final ({List<TrackerEntry> anime, List<TrackerEntry> manga}) lists;
  try {
    lists = await actions.lists();
  } catch (error) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          l10n.trackerLoadListFailed(trackerReason(l10n, kind, error)),
        ),
      ),
    );
    return;
  }
  if (!context.mounted) return;
  final anime = lists.anime;
  final manga = lists.manga;
  var pickAnime = anime.isNotEmpty;
  var pickManga = manga.isNotEmpty;
  final chosen = await showDialog<bool>(
    context: context,
    builder: (dialog) => StatefulBuilder(
      builder: (dialog, setState) => AlertDialog(
        title: Text(l10n.trackerImportPickTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppToggleTile(
              checkbox: true,
              dense: false,
              value: pickAnime,
              onChanged: anime.isEmpty
                  ? null
                  : (v) => setState(() => pickAnime = v),
              title: l10n.trackerImportAnime(anime.length),
            ),
            AppToggleTile(
              checkbox: true,
              dense: false,
              value: pickManga,
              onChanged: manga.isEmpty
                  ? null
                  : (v) => setState(() => pickManga = v),
              title: l10n.trackerImportManga(manga.length),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(false),
            child: Text(l10n.browseAddWarningCancel),
          ),
          FilledButton(
            onPressed: pickAnime || pickManga
                ? () => Navigator.of(dialog).pop(true)
                : null,
            child: Text(l10n.trackerImportTitle),
          ),
        ],
      ),
    ),
  );
  if (chosen != true || !context.mounted) return;
  await importTrackerTitles(context, ref, kind, [
    if (pickAnime) ...anime,
    if (pickManga) ...manga,
  ]);
}

/// Reads both lists fresh and brings progress level in both directions.
Future<void> syncTrackerNow(
  BuildContext context,
  WidgetRef ref,
  TrackerKind kind,
) async {
  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  final actions = ref.read(trackerActionsProvider(kind));
  messenger.showSnackBar(SnackBar(content: Text(l10n.trackerSyncRunning)));
  try {
    final result = await actions.sync();
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          l10n.trackerSyncDone(
            kind.label,
            result.pulled,
            result.pushed,
            result.waiting,
          ),
        ),
      ),
    );
  } catch (error) {
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          l10n.trackerLoadListFailed(trackerReason(l10n, kind, error)),
        ),
      ),
    );
  }
}
