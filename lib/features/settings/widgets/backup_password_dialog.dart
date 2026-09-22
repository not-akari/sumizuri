// Password prompts for creating or unlocking encrypted backup archives.
import 'package:flutter/material.dart';

import 'package:sumizuri/core/widgets/overlays/dialog_with_controller.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

/// Dialog to set a password for a new backup (returns null if cancelled, '' if skipped).
Future<String?> askNewBackupPassword(BuildContext context) =>
    showDialog<String>(
      context: context,
      builder: (context) => const _NewBackupPasswordDialog(),
    );

class _NewBackupPasswordDialog extends StatefulWidget {
  const _NewBackupPasswordDialog();

  @override
  State<_NewBackupPasswordDialog> createState() =>
      _NewBackupPasswordDialogState();
}

class _NewBackupPasswordDialogState extends State<_NewBackupPasswordDialog> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _continue() {
    final l10n = AppLocalizations.of(context)!;
    if (_password.text.isEmpty) {
      Navigator.of(context).pop('');
      return;
    }
    if (_password.text != _confirm.text) {
      setState(() => _error = l10n.backupPasswordMismatch);
      return;
    }
    Navigator.of(context).pop(_password.text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.backupPasswordSetTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.backupPasswordSetMessage),
          const SizedBox(height: 16),
          TextField(
            controller: _password,
            obscureText: _obscure,
            autofocus: true,
            // Rebuilds so the Skip/Protect action label tracks whether anything is typed.
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: l10n.backupPasswordLabel,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _confirm,
            obscureText: _obscure,
            decoration: InputDecoration(
              labelText: l10n.backupPasswordConfirmLabel,
              errorText: _error,
            ),
            onSubmitted: (_) => _continue(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.browseAddWarningCancel),
        ),
        FilledButton(
          onPressed: _continue,
          child: Text(
            _password.text.isEmpty
                ? l10n.backupPasswordSkip
                : l10n.backupPasswordSetConfirm,
          ),
        ),
      ],
    );
  }
}

/// Dialog asking for password to decrypt an existing backup.
Future<String?> askExistingBackupPassword(
  BuildContext context, {
  String? error,
}) {
  final l10n = AppLocalizations.of(context)!;
  return showAppTextFieldDialog(
    context: context,
    title: l10n.backupPasswordEnterTitle,
    label: l10n.backupPasswordLabel,
    errorText: error,
    obscureText: true,
    trim: false,
    confirmLabel: l10n.backupPasswordUnlock,
  );
}
