import 'package:flutter/material.dart';

import 'package:sumizuri/core/navigation/nav_destination_kind.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

IconData navDestinationIcon(NavDestinationKind kind) => switch (kind) {
  NavDestinationKind.library => Icons.collections_bookmark_outlined,
  NavDestinationKind.mangaLibrary => Icons.menu_book_outlined,
  NavDestinationKind.novelLibrary => Icons.auto_stories_outlined,
  NavDestinationKind.animeLibrary => Icons.movie_outlined,
  NavDestinationKind.updates => Icons.new_releases_outlined,
  NavDestinationKind.history => Icons.history,
  NavDestinationKind.browse => Icons.explore_outlined,
  NavDestinationKind.profile => Icons.person_outline,
  NavDestinationKind.settings => Icons.settings_outlined,
};

String navDestinationLabel(NavDestinationKind kind, AppLocalizations l10n) =>
    switch (kind) {
      NavDestinationKind.library => l10n.libraryTitle,
      NavDestinationKind.mangaLibrary => l10n.navMangaLibrary,
      NavDestinationKind.novelLibrary => l10n.navNovelLibrary,
      NavDestinationKind.animeLibrary => l10n.navAnimeLibrary,
      NavDestinationKind.updates => l10n.updatesTitle,
      NavDestinationKind.history => l10n.historyTitle,
      NavDestinationKind.browse => l10n.browseTitle,
      NavDestinationKind.profile => l10n.navProfile,
      NavDestinationKind.settings => l10n.settingsTitle,
    };
