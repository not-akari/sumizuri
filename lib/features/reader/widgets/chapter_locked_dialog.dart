import 'package:flutter/material.dart';

import 'package:sumizuri/features/extensions/models/m_chapter.dart';
import 'package:sumizuri/features/reader/models/chapter_lock_checker.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

Future<void> showChapterLockedDialog(BuildContext context, MChapter chapter) {
  final l10n = AppLocalizations.of(context)!;
  final countdown = formatUnlockCountdown(
    AppLocalizations.of(context)!,
    chapter.unlocksAt,
  );

  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.sourceBrowseLockedTitle),
      content: Text(
        countdown != null && !chapter.locked
            ? l10n.sourceBrowseTimeLockedMessage(countdown)
            : l10n.sourceBrowseLockedMessage,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.sourceBrowseLockedDismiss),
        ),
      ],
    ),
  );
}
