import 'package:sumizuri/features/extensions/models/m_video.dart';

enum MarkerKind { intro, outro }

class ActiveMarker {
  const ActiveMarker(this.kind, this.skipTo, {this.endsEpisode = false});

  final MarkerKind kind;

  final Duration skipTo;

  /// True when skipping reaches the end, so the next episode is the natural place to go.
  final bool endsEpisode;
}

const markerLead = Duration(seconds: 3);

ActiveMarker? activeMarker({
  required Duration position,
  required MTimeRange? intro,
  required MTimeRange? outro,
  required Duration length,
}) {
  if (intro != null && _within(position, intro)) {
    return ActiveMarker(MarkerKind.intro, intro.end);
  }
  if (outro != null && _within(position, outro)) {
    final near =
        length > Duration.zero &&
        outro.end >= length - const Duration(seconds: 3);
    return ActiveMarker(MarkerKind.outro, outro.end, endsEpisode: near);
  }
  return null;
}

bool _within(Duration position, MTimeRange range) =>
    position >= range.start - markerLead && position < range.end;
