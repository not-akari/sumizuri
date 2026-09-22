import 'package:sumizuri/features/library/models/library_types.dart';
import 'package:sumizuri/features/settings/models/app_settings_types.dart';

enum NavDestinationKind {
  library(null),
  mangaLibrary(MediaType.manga),
  novelLibrary(MediaType.novel),
  animeLibrary(MediaType.anime),
  browse(null),
  updates(null),
  history(null),
  profile(null),
  settings(null);

  const NavDestinationKind(this.mediaType);

  final MediaType? mediaType;
}

List<NavDestinationKind> navDestinationPoolFor(
  AppLibraryMode mode,
  Set<MediaType> enabledTypes,
) {
  const rest = [
    NavDestinationKind.updates,
    NavDestinationKind.history,
    NavDestinationKind.browse,
    NavDestinationKind.profile,
    NavDestinationKind.settings,
  ];
  if (mode == AppLibraryMode.unified) {
    return [NavDestinationKind.library, ...rest];
  }
  final libraryKinds = NavDestinationKind.values.where(
    (k) => k.mediaType != null && enabledTypes.contains(k.mediaType),
  );
  return [...libraryKinds, ...rest];
}

List<NavDestinationKind> reconcileNavDestinations(
  List<NavDestinationKind> stored,
  AppLibraryMode mode,
  Set<MediaType> enabledTypes,
) {
  final pool = navDestinationPoolFor(mode, enabledTypes);
  final result = stored.where(pool.contains).toList();

  final hasLibraryKind = result.any(
    (k) => k == NavDestinationKind.library || k.mediaType != null,
  );
  if (!hasLibraryKind) {
    result.insertAll(
      0,
      mode == AppLibraryMode.unified
          ? const [NavDestinationKind.library]
          : [
              for (final kind in NavDestinationKind.values)
                if (kind.mediaType != null &&
                    enabledTypes.contains(kind.mediaType))
                  kind,
            ],
    );
  }
  if (!result.contains(NavDestinationKind.profile)) {
    result.add(NavDestinationKind.profile);
  }
  if (!result.contains(NavDestinationKind.settings)) {
    result.add(NavDestinationKind.settings);
  }
  return result;
}
