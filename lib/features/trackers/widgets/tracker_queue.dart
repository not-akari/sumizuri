import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/core/theming/app_layout.dart';
import 'package:sumizuri/core/utils/formatting/relative_date.dart';
import 'package:sumizuri/core/widgets/cards/app_card.dart';
import 'package:sumizuri/core/widgets/feedback/error_view.dart';
import 'package:sumizuri/features/trackers/data/tracker_store.dart';
import 'package:sumizuri/features/trackers/models/tracker_models.dart';
import 'package:sumizuri/features/trackers/providers/tracker_actions.dart';
import 'package:sumizuri/features/trackers/providers/tracker_providers.dart';
import 'package:sumizuri/features/trackers/widgets/tracker_problem_text.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

/// Progress that is waiting to be sent to a tracker, with a way to send it now
/// or drop a title from the wait.
class TrackerQueueSlivers extends ConsumerStatefulWidget {
  const TrackerQueueSlivers({super.key, required this.kind});

  final TrackerKind kind;

  @override
  ConsumerState<TrackerQueueSlivers> createState() =>
      _TrackerQueueSliversState();
}

class _TrackerQueueSliversState extends ConsumerState<TrackerQueueSlivers> {
  var _sending = false;

  TrackerKind get _kind => widget.kind;

  Future<void> _sendNow() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    // Nothing from [ref] after the first await: the page may be gone by then.
    final actions = ref.read(trackerActionsProvider(_kind));
    setState(() => _sending = true);
    final TrackerFlushResult result;
    try {
      result = await actions.sendNow();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
    final text = switch (result.outcome) {
      TrackerFlushOutcome.sent => l10n.trackerSendResultSent(
        result.sent,
        result.failed,
      ),
      TrackerFlushOutcome.noAccount => l10n.trackerSendResultNoAccount(
        _kind.label,
      ),
      TrackerFlushOutcome.loginExpired => l10n.trackerSendResultExpired(
        _kind.label,
      ),
      TrackerFlushOutcome.postponed => l10n.trackerSendResultLater(_kind.label),
      _ => l10n.trackerSendResultNothing,
    };
    messenger.showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _discard(int linkId) =>
      ref.read(trackerActionsProvider(_kind)).discard(linkId);

  Widget _row(BuildContext context, AppLocalizations l10n, QueuedTitle item) {
    final cs = Theme.of(context).colorScheme;
    final meta = [
      formatRelativeDate(
        l10n,
        DateTime.fromMillisecondsSinceEpoch(item.firstQueuedAt),
      ),
      if (item.attempts > 0) l10n.trackerQueueTries(item.attempts),
    ].join(' · ');
    return AdaptiveRowCard(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(meta, style: TextStyle(fontSize: 12, color: cs.outline)),
                if (item.lastError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      trackerStoredError(l10n, _kind, item.lastError!),
                      style: TextStyle(fontSize: 12, color: cs.error),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 20),
            tooltip: l10n.trackerQueueDiscard,
            onPressed: () => _discard(item.linkId),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final queue = ref.watch(trackerQueueProvider(_kind));
    final gutter = context.layout.gutter;
    return SliverToBoxAdapter(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: EdgeInsets.fromLTRB(gutter, 12, gutter, 0),
            child: queue.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) =>
                  ErrorView(message: trackerReason(l10n, _kind, error)),
              data: (items) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppCard(
                    flattenWhenCompact: true,
                    tone: AppCardTone.inset,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.trackerQueueHint,
                          style: TextStyle(
                            fontSize: 13,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          icon: _sending
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.upload_outlined, size: 18),
                          label: Text(l10n.trackerSendNow),
                          onPressed: items.isEmpty || _sending
                              ? null
                              : _sendNow,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (items.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(child: Text(l10n.trackerQueueEmpty)),
                    ),
                  for (final item in items) _row(context, l10n, item),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
