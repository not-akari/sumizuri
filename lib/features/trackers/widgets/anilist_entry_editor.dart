import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/core/widgets/controls/app_choice.dart';
import 'package:sumizuri/core/theming/app_layout.dart';
import 'package:sumizuri/core/errors/result.dart';
import 'package:sumizuri/core/widgets/overlays/app_sheet.dart';
import 'package:sumizuri/core/widgets/overlays/confirm_dialog.dart';
import 'package:sumizuri/features/profile/providers/profile_providers.dart';
import 'package:sumizuri/features/trackers/providers/anilist_providers.dart';
import 'package:sumizuri/features/trackers/models/anilist_media.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

String aniListStatusLabel(
  AppLocalizations l10n,
  AniListListStatus? status, {
  required bool anime,
}) => switch (status) {
  AniListListStatus.current =>
    anime ? l10n.trackingStatusCurrentAnime : l10n.trackingStatusCurrent,
  AniListListStatus.planning => l10n.trackingStatusPlanning,
  AniListListStatus.completed => l10n.trackingStatusCompleted,
  AniListListStatus.dropped => l10n.trackingStatusDropped,
  AniListListStatus.paused => l10n.trackingStatusPaused,
  AniListListStatus.repeating =>
    anime ? l10n.trackingStatusRepeatingAnime : l10n.trackingStatusRepeating,
  null => '',
};

/// Opens the editor for one list entry. True when saved or removed, so the list reloads.
Future<bool> showAniListEntryEditor(
  BuildContext context,
  AniListListEntry entry,
) async {
  final changed = await showAppSheet<bool>(
    context,
    builder: (_) => _EntryEditor(entry: entry),
  );
  return changed ?? false;
}

class _EntryEditor extends ConsumerStatefulWidget {
  const _EntryEditor({required this.entry});

  final AniListListEntry entry;

  @override
  ConsumerState<_EntryEditor> createState() => _EntryEditorState();
}

class _EntryEditorState extends ConsumerState<_EntryEditor> {
  late AniListListStatus? _status = widget.entry.status;
  late int _progress = widget.entry.progress;
  late int _score = widget.entry.score;
  late AniListFuzzyDate? _started = widget.entry.startedAt;
  late AniListFuzzyDate? _completed = widget.entry.completedAt;
  late final _progressField = TextEditingController(text: '$_progress');
  var _busy = false;

  AniListMedia? get _media => widget.entry.media;
  bool get _anime => _media?.type == AniListMediaType.anime;
  int? get _total => _anime ? _media?.episodes : _media?.chapters;

  @override
  void dispose() {
    _progressField.dispose();
    super.dispose();
  }

  void _setProgress(int value) {
    final total = _total;
    final capped = value.clamp(0, total != null && total > 0 ? total : 99999);
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
    final date = AniListFuzzyDate.fromDateTime(picked);
    setState(() => started ? _started = date : _completed = date);
  }

  String _dateText(AppLocalizations l10n, AniListFuzzyDate? date) {
    if (date == null || date.year == null) return l10n.aniListDateNotSet;
    final month = (date.month ?? 1).toString().padLeft(2, '0');
    final day = (date.day ?? 1).toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _busy = true);
    final result = await ref
        .read(aniListRepositoryProvider)
        .saveEntry(
          ref.read(currentProfileIdProvider),
          AniListEntryUpdate(
            mediaId: widget.entry.mediaId,
            status: _status,
            progress: _progress,
            score: _score,
            startedAt: _started,
            completedAt: _completed,
          ),
        );
    if (!mounted) return;
    switch (result) {
      case Ok():
        messenger.showSnackBar(SnackBar(content: Text(l10n.aniListSaved)));
        navigator.pop(true);
      case Err(:final error):
        setState(() => _busy = false);
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.aniListSaveFailed(error.displayMessage))),
        );
    }
  }

  Future<void> _remove() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: l10n.aniListRemoveEntryTitle,
      message: l10n.aniListRemoveEntryMessage(_media?.title.display ?? ''),
      confirmLabel: l10n.aniListRemoveEntry,
      cancelLabel: l10n.browseAddWarningCancel,
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;
    setState(() => _busy = true);
    final result = await ref
        .read(aniListRepositoryProvider)
        .deleteEntry(ref.read(currentProfileIdProvider), widget.entry.id);
    if (!mounted) return;
    switch (result) {
      case Ok():
        navigator.pop(true);
      case Err(:final error):
        setState(() => _busy = false);
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.aniListSaveFailed(error.displayMessage))),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final total = _total;
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
            AppSheetHeader(
              title: _media?.title.display ?? l10n.aniListEditTitle,
            ),
            Text(l10n.aniListFieldStatus, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            AppChoice<AniListListStatus>.of(
              style: AppChoiceStyle.pills,
              values: AniListListStatus.values,
              label: (status) =>
                  aniListStatusLabel(l10n, status, anime: _anime),
              icon: (_) => Icons.label_outline,
              value: _status,
              onChanged: (status) => setState(() => _status = status),
            ),
            const SizedBox(height: 20),
            Text(l10n.aniListFieldProgress, style: theme.textTheme.titleSmall),
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
                      if (value != null) {
                        setState(() => _progress = value);
                      }
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
                if (total != null && total > 0) ...[
                  const SizedBox(width: 12),
                  Text('/ $total', style: theme.textTheme.bodyLarge),
                ],
              ],
            ),
            const SizedBox(height: 20),
            Text(l10n.aniListFieldScore, style: theme.textTheme.titleSmall),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _score.toDouble(),
                    max: 100,
                    divisions: 20,
                    label: _score == 0 ? l10n.aniListNoScore : '$_score',
                    onChanged: (v) => setState(() => _score = v.round()),
                  ),
                ),
                SizedBox(
                  width: 72,
                  child: Text(
                    _score == 0 ? l10n.aniListNoScore : '$_score',
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _DateRow(
              label: l10n.aniListFieldStarted,
              text: _dateText(l10n, _started),
              onTap: () => _pickDate(started: true),
            ),
            _DateRow(
              label: l10n.aniListFieldCompleted,
              text: _dateText(l10n, _completed),
              onTap: () => _pickDate(started: false),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _busy ? null : _save,
              child: Text(l10n.aniListSave),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _busy ? null : _remove,
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
              ),
              child: Text(l10n.aniListRemoveEntry),
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
