import 'package:sumizuri/core/utils/files/folder_picker.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

String folderProblemText(AppLocalizations l10n, FolderProblem problem) =>
    switch (problem) {
      FolderProblem.needsAccess => l10n.dataLocationNeedsAccess,
      FolderProblem.notWritable => l10n.dataLocationNotWritable,
    };
