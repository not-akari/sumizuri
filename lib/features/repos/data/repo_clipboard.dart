import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:sumizuri/l10n/generated/app_localizations.dart';

/// Puts a repo's address on the clipboard, so it can be shared or added on another device.
Future<void> copyRepoUrl(BuildContext context, String url) async {
  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  await Clipboard.setData(ClipboardData(text: url));
  messenger.showSnackBar(SnackBar(content: Text(l10n.repoUrlCopied)));
}
