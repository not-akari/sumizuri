import 'package:flutter/material.dart';

import 'package:sumizuri/l10n/generated/app_localizations.dart';

Future<bool> showAppConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  String? confirmLabel,
  String? cancelLabel,
  bool isDestructive = false,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final cancel = cancelLabel ?? l10n.browseAddWarningCancel;
  final confirm = confirmLabel ?? l10n.commonConfirm;
  final cs = Theme.of(context).colorScheme;

  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(cancel),
        ),
        FilledButton(
          style: isDestructive
              ? FilledButton.styleFrom(
                  backgroundColor: cs.error,
                  foregroundColor: cs.onError,
                )
              : null,
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(confirm),
        ),
      ],
    ),
  );
  return result ?? false;
}
