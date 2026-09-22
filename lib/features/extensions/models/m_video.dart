class MSubtitle {
  const MSubtitle({required this.url, required this.label, this.language});

  final String url;

  final String label;

  final String? language;
}

class MAudioTrack {
  const MAudioTrack({required this.url, required this.label, this.language});

  final String url;
  final String label;
  final String? language;
}

class MTimeRange {
  const MTimeRange(this.start, this.end);

  final Duration start;
  final Duration end;

  bool contains(Duration position) => position >= start && position < end;
}

class MVideo {
  const MVideo({
    required this.url,
    this.quality,
    this.headers = const {},
    this.subtitles = const [],
    this.audioTracks = const [],
    this.intro,
    this.outro,
    this.pairedAudio,
  });

  final MAudioTrack? pairedAudio;

  final MTimeRange? intro;

  final MTimeRange? outro;

  final String url;

  final String? quality;

  final Map<String, String> headers;

  final List<MSubtitle> subtitles;
  final List<MAudioTrack> audioTracks;

  /// Whether url is an HLS playlist, which can be saved piece by piece.
  bool get isHls =>
      (Uri.tryParse(url)?.path ?? url).toLowerCase().endsWith('.m3u8');

  /// Whether url is a DASH manifest. It can be saved unless it is DRM protected or live.
  bool get isDash =>
      (Uri.tryParse(url)?.path ?? url).toLowerCase().endsWith('.mpd');

  bool get isPlaylist => isHls || isDash;
}
