library;

enum LibraryGridTileSize {
  small(110),
  medium(140),
  large(170);

  const LibraryGridTileSize(this.maxExtent);

  final double maxExtent;
}

/// How the library and other lists of titles are laid out: a grid of covers
/// with the title under, over or left off, or rows, plain or dense.
enum LibraryDisplayStyle {
  comfortableGrid,
  compactGrid,
  coverGrid,
  list,
  compactList;

  bool get isGrid => index <= coverGrid.index;
}

/// How a section of the library's home page shows its titles: a row that
/// scrolls sideways, a grid, or a short list.
enum DashboardShelfStyle { shelf, grid, list }

enum AppLibraryMode { unified, splitByType }

enum AppDarkModePreference { system, light, dark }

enum ColorIntensity { subtle, medium, vivid }

enum AppBackgroundMotion { auto, on, off }

enum AppNavStyle { auto, island, bottomBar, rail, drawer }

/// How rows in lists are drawn: boxed as cards, or flat and dense so more
/// fit on screen. Automatic is dense on a phone and boxed on a bigger screen.
enum AppListStyle { auto, cards, compact }

enum ChapterListLayout { list, grid }
