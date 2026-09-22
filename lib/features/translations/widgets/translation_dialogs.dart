import 'package:flutter/material.dart';

import 'package:sumizuri/l10n/generated/app_localizations.dart';
import 'package:sumizuri/core/widgets/overlays/dialog_with_controller.dart';

Future<String?> showAddExactNumberDialog(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  return showAppTextFieldDialog(
    context: context,
    title: l10n.translationEditorExactNumberMatch,
    initialText: '=0',
    hint: '=0, =1, =2...',
    label: l10n.translationEditorCustomCategoryLabel,
    confirmLabel: l10n.commonAdd,
    cancelLabel: l10n.commonCancel,
    canSubmit: (text) => text.isNotEmpty,
    transform: (text) => text.startsWith('=') ? text : '=$text',
  );
}

Future<String?> showAddSelectOptionDialog(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  return showAppTextFieldDialog(
    context: context,
    title: l10n.translationEditorAddCategory,
    hint: l10n.translationEGFemaleMaleOther,
    label: l10n.translationEditorCustomCategoryLabel,
    confirmLabel: l10n.commonAdd,
    cancelLabel: l10n.commonCancel,
    canSubmit: (text) => text.isNotEmpty,
  );
}
