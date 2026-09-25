import 'package:flutter/material.dart';

import 'package:sumizuri/core/widgets/overlays/app_sheet.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

/// The small button at the end of the library search bar, and the sheet it
/// opens listing what the search understands.
class LibrarySearchHelpButton extends StatelessWidget {
  const LibrarySearchHelpButton({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return IconButton(
      icon: const Icon(Icons.help_outline_rounded, size: 20),
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      tooltip: l10n.librarySearchHelpTooltip,
      onPressed: () =>
          showAppSheet<void>(context, builder: (_) => const _SearchHelpSheet()),
    );
  }
}

class _SearchHelpSheet extends StatelessWidget {
  const _SearchHelpSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tips = <(String, String)>[
      ('"one piece"', l10n.librarySearchHelpPhrase),
      ('-bleach', l10n.librarySearchHelpExclude),
      ('naruto OR bleach', l10n.librarySearchHelpOr),
      ('(naruto OR bleach) -filler', l10n.librarySearchHelpGroup),
      ('status:ongoing', l10n.librarySearchHelpStatus),
      ('source:mangadex', l10n.librarySearchHelpSource),
      ('category:reading', l10n.librarySearchHelpCategory),
      ('type:novel', l10n.librarySearchHelpType),
      ('fav:yes', l10n.librarySearchHelpFavorite),
      ('unread:>5', l10n.librarySearchHelpUnread),
    ];
    final cs = Theme.of(context).colorScheme;
    return AppSheet(
      title: l10n.librarySearchHelpTitle,
      subtitle: l10n.librarySearchHelpSubtitle,
      children: [
        for (final (example, meaning) in tips)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Text(
                    example,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: cs.primary,
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Text(
                    meaning,
                    style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
