library;

enum ReaderMode { continuousVertical, rightToLeft, leftToRight, verticalPaged }

enum ReaderScaleType { fitScreen, fitWidth, fitHeight, original }

enum ReaderBackground { black, dark, white, sepia }

enum ReaderPageGap {
  none(0.0),
  small(4.0),
  medium(8.0),
  large(16.0);

  const ReaderPageGap(this.pixels);
  final double pixels;
}

enum ReaderDualPageMode { off, dualPage, dualPageCover }

enum ReaderFontFamily {
  systemDefault(null),
  openDyslexic('OpenDyslexic');

  const ReaderFontFamily(this.fontFamily);
  final String? fontFamily;
}

enum ReaderColumnWidth {
  small(600.0),
  medium(800.0),
  large(1000.0),
  fullWidth(double.infinity);

  const ReaderColumnWidth(this.pixels);
  final double pixels;
}

enum ReaderImageQuality {
  quality(
    continuousCacheWidthCap: 3240,
    pagedHeadroom: 3.0,
    pagedCacheWidthCap: 6144,
  ),
  balanced(
    continuousCacheWidthCap: 2160,
    pagedHeadroom: 2.0,
    pagedCacheWidthCap: 4096,
  ),
  performance(
    continuousCacheWidthCap: 1440,
    pagedHeadroom: 1.0,
    pagedCacheWidthCap: 2048,
  );

  const ReaderImageQuality({
    required this.continuousCacheWidthCap,
    required this.pagedHeadroom,
    required this.pagedCacheWidthCap,
  });

  final int continuousCacheWidthCap;

  final double pagedHeadroom;

  final int pagedCacheWidthCap;
}
