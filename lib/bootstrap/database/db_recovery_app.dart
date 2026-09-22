// Shown instead of the app when the saved data cannot be upgraded.
import 'package:flutter/material.dart';

import 'package:sumizuri/bootstrap/startup/plain_app.dart';
import 'package:sumizuri/features/settings/data/db_file_backup.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

class DbRecoveryApp extends StatelessWidget {
  const DbRecoveryApp({
    super.key,
    required this.version,
    this.error,
    required this.onReset,
  });

  final int version;

  /// What went wrong when the upgrade failed. Null when the data is too old to try.
  final String? error;

  final Future<void> Function() onReset;

  @override
  Widget build(BuildContext context) {
    return PlainApp(
      home: _DbRecoveryPage(version: version, error: error, onReset: onReset),
    );
  }
}

class _DbRecoveryPage extends StatefulWidget {
  const _DbRecoveryPage({
    required this.version,
    required this.error,
    required this.onReset,
  });

  final int version;
  final String? error;
  final Future<void> Function() onReset;

  @override
  State<_DbRecoveryPage> createState() => _DbRecoveryPageState();
}

class _DbRecoveryPageState extends State<_DbRecoveryPage> {
  bool _busy = false;
  String? _status;

  Future<void> _export() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _busy = true;
      _status = null;
    });
    String status;
    try {
      final path = await exportDatabaseCopy();
      status = path == null ? '' : l10n.dbTooOldExported(path);
    } catch (error) {
      status = l10n.dbTooOldExportFailed('$error');
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _status = status.isEmpty ? null : status;
    });
  }

  Future<void> _reset() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.dbTooOldResetConfirmTitle),
        content: Text(l10n.dbTooOldResetConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.dbTooOldCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.dbTooOldResetConfirmConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await deleteDatabaseFiles();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _status = l10n.dbTooOldResetFailed('$error');
      });
      return;
    }
    try {
      // A start that never finishes is reported too, rather than left as a spinner.
      await widget.onReset().timeout(const Duration(seconds: 45));
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _status = l10n.dbTooOldStartFailed('$error');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 40,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.error == null
                        ? l10n.dbTooOldTitle
                        : l10n.dbMigrationFailedTitle,
                    style: theme.textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.error == null
                        ? l10n.dbTooOldMessage(widget.version)
                        : l10n.dbMigrationFailedMessage(widget.version),
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  if (widget.error != null) ...[
                    const SizedBox(height: 12),
                    SelectableText(
                      widget.error!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _busy ? null : _export,
                      child: Text(l10n.dbTooOldExport),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _busy ? null : _reset,
                      child: Text(l10n.dbTooOldReset),
                    ),
                  ),
                  if (_busy) ...[
                    const SizedBox(height: 16),
                    const CircularProgressIndicator(),
                  ],
                  if (_status != null) ...[
                    const SizedBox(height: 16),
                    SelectableText(
                      _status!,
                      style: theme.textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
