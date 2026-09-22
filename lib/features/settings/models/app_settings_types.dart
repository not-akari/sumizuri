library;

enum LibraryGridTileSize {
  small(110),
  medium(140),
  large(170);

  const LibraryGridTileSize(this.maxExtent);

  final double maxExtent;
}

enum AppLibraryMode { unified, splitByType }

enum AppDarkModePreference { system, light, dark }

enum ColorIntensity { subtle, medium, vivid }

enum AppBackgroundMotion { auto, on, off }

enum AppNavStyle { auto, island, bottomBar, rail, drawer }

enum ChapterListLayout { list, grid }
