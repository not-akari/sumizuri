import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/features/settings/data/backup_preferences.dart';
import 'package:sumizuri/features/settings/pages/changelog_page.dart';
import 'package:sumizuri/features/settings/data/update_checker.dart';
import 'package:sumizuri/features/settings/flows/backup_service.dart';
import 'package:sumizuri/features/settings/widgets/changelog_view.dart';
import 'package:sumizuri/features/settings/widgets/update_install_dialog.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

Future<void> showUpdatePrompt(
  BuildContext context,
  UpdateCheckResult result,
  String currentVersion,
) {
  return showDialog<void>(
    context: context,
    builder: (_) => _UpdatePrompt(
      hostContext: context,
      result: result,
      currentVersion: currentVersion,
    ),
  );
}

class _UpdatePrompt extends ConsumerStatefulWidget {
  const _UpdatePrompt({
    required this.hostContext,
    required this.result,
    required this.currentVersion,
  });

  final BuildContext hostContext;
  final UpdateCheckResult result;
  final String currentVersion;

  @override
  ConsumerState<_UpdatePrompt> createState() => _UpdatePromptState();
}

class _UpdatePromptState extends ConsumerState<_UpdatePrompt> {
  bool _backingUp = false;
  Object? _backupError;

  void _startUpdate() {
    final host = widget.hostContext;
    Navigator.of(context).pop();
    if (host.mounted) startUpdate(host, widget.result);
  }

  Future<void> _backUpThenUpdate() async {
    setState(() {
      _backingUp = true;
      _backupError = null;
    });
    try {
      final prefs = await ref.read(backupPreferencesProvider.future);
      // At least a few, so this one never pushes out the last good backup.
      await ref
          .read(backupServiceProvider)
          .writeAuto(keep: prefs.keep < 3 ? 3 : prefs.keep);
    } catch (error) {
      if (!mounted) return;
      // Stays open: the person decides whether to update without it.
      setState(() {
        _backingUp = false;
        _backupError = error;
      });
      return;
    }
    if (!mounted) return;
    _startUpdate();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final notes = (widget.result.notes ?? '').trim();

    return AlertDialog(
      title: Row(
        children: [
          Expanded(
            child: Text(
              l10n.updateDialogTitle(widget.result.latestVersion ?? ''),
            ),
          ),
          IconButton(
            tooltip: l10n.updatePromptClose,
            icon: const Icon(Icons.close),
            onPressed: _backingUp ? null : () => Navigator.of(context).pop(),
          ),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.updateDialogBody(widget.currentVersion)),
              const SizedBox(height: 8),
              Text(
                l10n.updatePromptExplain,
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
              ),
              if (_backupError != null) ...[
                const SizedBox(height: 12),
                Text(
                  l10n.updatePromptBackupFailed('$_backupError'),
                  style: TextStyle(color: cs.error),
                ),
              ],
              if (notes.isNotEmpty) ...[
                const SizedBox(height: 12),
                ChangelogBody(text: notes),
              ],
            ],
          ),
        ),
      ),
      actionsOverflowDirection: VerticalDirection.down,
      actions: [
        TextButton(
          onPressed: _backingUp ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.updatePromptLater),
        ),
        TextButton(
          onPressed: _backingUp
              ? null
              : () {
                  Navigator.of(context).pop();
                  Navigator.of(widget.hostContext).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ChangelogPage(),
                    ),
                  );
                },
          child: Text(l10n.changelogTitle),
        ),
        OutlinedButton(
          onPressed: _backingUp ? null : _startUpdate,
          child: Text(l10n.updatePromptSkipBackup),
        ),
        FilledButton.icon(
          onPressed: _backingUp ? null : _backUpThenUpdate,
          icon: _backingUp
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.backup_outlined, size: 18),
          label: Text(
            _backingUp ? l10n.updatePromptBackingUp : l10n.updatePromptBackUp,
          ),
        ),
      ],
    );
  }
}
