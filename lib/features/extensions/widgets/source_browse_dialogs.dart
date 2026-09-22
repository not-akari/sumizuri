import 'package:flutter/material.dart';

import 'package:sumizuri/l10n/generated/app_localizations.dart';
import 'package:sumizuri/core/widgets/overlays/dialog_with_controller.dart';

Future<String?> showBrowseSearchDialog(
  BuildContext context, {
  String? initialQuery,
}) {
  final l10n = AppLocalizations.of(context)!;
  return showAppTextFieldDialog(
    context: context,
    title: l10n.sourceEditorTestMethodSearch,
    initialText: initialQuery ?? '',
    hint: l10n.sourceEditorTestQueryLabel,
    confirmLabel: l10n.sourceEditorTestRun,
  );
}
