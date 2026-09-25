import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/core/theming/app_layout.dart';
import 'package:sumizuri/core/widgets/controls/app_choice.dart';
import 'package:sumizuri/core/widgets/overlays/app_sheet.dart';
import 'package:sumizuri/core/widgets/overlays/confirm_dialog.dart';
import 'package:sumizuri/features/profile/providers/profile_providers.dart';
import 'package:sumizuri/features/trackers/models/tracker_exception.dart';
import 'package:sumizuri/features/trackers/models/tracker_models.dart';
import 'package:sumizuri/features/trackers/providers/tracker_providers.dart';
import 'package:sumizuri/features/trackers/widgets/tracker_problem_text.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

String trackerStatusLabel(
  AppLocalizations l10n,
  TrackerStatus? status, {
  required bool anime,
}) => switch (status) {
  TrackerStatus.current =>
    anime ? l10n.trackingStatusCurrentAnime : l10n.trackingStatusCurrent,
  TrackerStatus.planning => l10n.trackingStatusPlanning,
  TrackerStatus.completed => l10n.trackingStatusCompleted,
  TrackerStatus.dropped => l10n.trackingStatusDropped,
  TrackerStatus.paused => l10n.trackingStatusPaused,
  TrackerStatus.repeating =>
    anime ? l10n.trackingStatusRepeatingAnime : l10n.trackingStatusRepeating,
  null => '',
};

/// A score out of 100 as the out of 10 people know it: 8, or 8.5.
String trackerScoreText(int score) =>
    score % 10 == 0 ? '${score ~/ 10}' : (score / 10).toStringAsFixed(1);

/// Opens the editor for one list entry. True when saved or removed, so the list reloads.
Future<bool> showTrackerEntryEditor(
  BuildContext context,
  TrackerEntry entry,
) async {
  final changed = await showAppSheet<bool>(
    context,
    builder: (_) => _EntryEditor(entry: entry),
  );
  return changed ?? false;
}

class _EntryEditor extends ConsumerStatefulWidget {
  const _EntryEditor({required this.entry});

  final TrackerEntry entry;

  @override
  ConsumerState<_EntryEditor> createState() => _EntryEditorState();
}

class _EntryEditorState extends ConsumerState<_EntryEditor> {
  late TrackerStatus? _status = widget.entry.status;
  late int _progress = widget.entry.progress;
  late int _score = widget.entry.score;
  late TrackerDate? _started = widget.entry.startedAt;
  late TrackerDate? _completed = widget.entry.completedAt;
  late final _progressField = TextEditingController(text: '$_progress');
  var _busy = false;

  TrackerEntry get _entry => widget.entry;
  TrackerKind get _kind => _entry.tracker;
  int? get _total => _entry.total;

  /// MyAnimeList takes whole points only; AniList takes halves too.
  int get _scoreSteps => _kind == TrackerKind.mal ? 10 : 20;

  @override
  void dispose() {
    _progressField.dispose();
    super.dispose();
  }

  void _setProgress(int value) {
    final total = _total;
    final capped = value.clamp(0, total ?? 99999);
    setState(() => _progress = capped);
    _progressField.text = '$capped';
    _progressField.selection = TextSelection.collapsed(
      offset: _progressField.text.length,
    );
  }

  Future<void> _pickDate({required bool started}) async {
    final current = started ? _started : _completed;
    final now = DateTime.now();
    final initial = current?.year == null
        ? now
        : DateTime(current!.year!, current.month ?? 1, current.day ?? 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(now) ? now : initial,
      firstDate: DateTime(1970),
      lastDate: now,
    );
    if (picked == null || !mounted) return;
    final date = TrackerDate.fromDateTime(picked);
    setState(() => started ? _started = date : _completed = date);
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _busy = true);
    try {
      await ref
          .read(trackerBackendProvider(_kind))
          .save(
            ref.read(currentProfileIdProvider),
            TrackerEntryUpdate(
              media: _entry.media,
              mediaId: _entry.mediaId,
              status: _status,
              progress: _progress,
              score: _score,
              startedAt: _started,
              completedAt: _completed,
            ),
          );
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.trackerSaved(_kind.label))),
      );
      navigator.pop(true);
    } on TrackerException catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            l10n.trackerSaveFailed(trackerReason(l10n, _kind, error)),
          ),
        ),
      );
    }
  }

  Future<void> _remove() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: l10n.trackerRemoveEntryTitle(_kind.label),
      message: l10n.trackerRemoveEntryMessage(_kind.label, _entry.title),
      confirmLabel: l10n.trackerRemoveEntry(_kind.label),
      cancelLabel: l10n.browseAddWarningCancel,
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(trackerBackendProvider(_kind))
          .remove(ref.read(currentProfileIdProvider), _entry);
      if (mounted) navigator.pop(true);
    } on TrackerException catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            l10n.trackerSaveFailed(trackerReason(l10n, _kind, error)),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final total = _total;
    final anime = _entry.isAnime;
    String dateText(TrackerDate? date) => date?.iso ?? l10n.trackerDateNotSet;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          context.layout.gutter,
          0,
          context.layout.gutter,
          24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSheetHeader(title: _entry.title),
            Text(l10n.trackerFieldStatus, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            AppChoice<TrackerStatus>.of(
              style: AppChoiceStyle.pills,
              values: TrackerStatus.values,
              label: (status) => trackerStatusLabel(l10n, status, anime: anime),
              icon: (_) => Icons.label_outline,
              value: _status,
              onChanged: (status) => setState(() => _status = status),
            ),
            const SizedBox(height: 20),
            Text(l10n.trackerFieldProgress, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton.outlined(
                  icon: const Icon(Icons.remove),
                  onPressed: _progress > 0
                      ? () => _setProgress(_progress - 1)
                      : null,
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 84,
                  child: TextField(
                    controller: _progressField,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (text) {
                      final value = int.tryParse(text);
                      if (value != null) setState(() => _progress = value);
                    },
                    onEditingComplete: () => _setProgress(_progress),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton.outlined(
                  icon: const Icon(Icons.add),
                  onPressed: total == null || _progress < total
                      ? () => _setProgress(_progress + 1)
                      : null,
                ),
                if (total != null) ...[
                  const SizedBox(width: 12),
                  Text('/ $total', style: theme.textTheme.bodyLarge),
                ],
              ],
            ),
            const SizedBox(height: 20),
            Text(l10n.trackerFieldScore, style: theme.textTheme.titleSmall),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _score.toDouble(),
                    max: 100,
                    divisions: _scoreSteps,
                    label: _score == 0
                        ? l10n.trackerNoScore
                        : trackerScoreText(_score),
                    onChanged: (v) => setState(() => _score = v.round()),
                  ),
                ),
                SizedBox(
                  width: 72,
                  child: Text(
                    _score == 0
                        ? l10n.trackerNoScore
                        : trackerScoreText(_score),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _DateRow(
              label: l10n.trackerFieldStarted,
              text: dateText(_started),
              onTap: () => _pickDate(started: true),
            ),
            _DateRow(
              label: l10n.trackerFieldCompleted,
              text: dateText(_completed),
              onTap: () => _pickDate(started: false),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _busy ? null : _save,
              child: Text(l10n.trackerSave(_kind.label)),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _busy ? null : _remove,
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
              ),
              child: Text(l10n.trackerRemoveEntry(_kind.label)),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({
    required this.label,
    required this.text,
    required this.onTap,
  });

  final String label;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(label),
    trailing: Text(text),
    onTap: onTap,
  );
}
