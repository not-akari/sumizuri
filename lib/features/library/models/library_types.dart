import 'package:sumizuri/l10n/generated/app_localizations.dart';

enum MediaType { manga, novel, anime }

extension MediaTypeL10nX on MediaType {
  String localizedLabel(AppLocalizations l10n) => switch (this) {
    MediaType.manga => l10n.navMangaLibrary,
    MediaType.novel => l10n.navNovelLibrary,
    MediaType.anime => l10n.navAnimeLibrary,
  };
}

Set<MediaType> reconcileEnabledMediaTypes(Set<MediaType> stored) =>
    stored.isEmpty ? {MediaType.manga} : stored;
