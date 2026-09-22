import 'package:media_kit/media_kit.dart' show SubtitleTrack;

import 'package:sumizuri/features/extensions/models/m_video.dart';
import 'package:sumizuri/features/player/models/player_preferences.dart';

const watchedThreshold = 0.9;

const restartThreshold = 0.95;

const _minimumResume = Duration(seconds: 5);

double? progressFraction(Duration position, Duration duration) {
  if (duration <= Duration.zero) return null;
  final fraction = position.inMilliseconds / duration.inMilliseconds;
  return fraction.clamp(0.0, 1.0);
}

bool isWatched(double fraction) => fraction >= watchedThreshold;

Duration? resumePosition(double? stored, Duration duration) {
  if (stored == null || duration <= Duration.zero) return null;
  if (stored >= restartThreshold) return null;
  final position = Duration(
    milliseconds: (stored * duration.inMilliseconds).round(),
  );
  return position < _minimumResume ? null : position;
}

MVideo? pickVideo(
  List<MVideo> videos, {
  String? preferredQuality,
  QualityMode mode = QualityMode.remember,
  AudioPreference audio = AudioPreference.any,
}) {
  if (videos.isEmpty) return null;
  final pool = _narrowedByAudio(videos, audio);

  switch (mode) {
    case QualityMode.remember:
      if (preferredQuality != null) {
        for (final video in pool) {
          if (video.quality == preferredQuality) return video;
        }
      }
      return pool.first;
    case QualityMode.best:
    case QualityMode.lowest:
      MVideo? chosen;
      int? chosenHeight;
      for (final video in pool) {
        final height = qualityHeight(video.quality);
        if (height == null) continue;
        final better =
            chosenHeight == null ||
            (mode == QualityMode.best
                ? height > chosenHeight
                : height < chosenHeight);
        if (better) {
          chosen = video;
          chosenHeight = height;
        }
      }
      return chosen ?? pool.first;
  }
}

List<MVideo> _narrowedByAudio(List<MVideo> videos, AudioPreference audio) {
  if (audio == AudioPreference.any) return videos;
  final wanted = audio == AudioPreference.dub ? _dub : _sub;
  final matching = [
    for (final video in videos)
      if (wanted.hasMatch(video.quality ?? '')) video,
  ];
  return matching.isEmpty ? videos : matching;
}

final _dub = RegExp(r'(^|[^a-z])dub(bed)?($|[^a-z])', caseSensitive: false);
final _sub = RegExp(
  r'(^|[^a-z])(soft|hard)?sub(bed)?($|[^a-z])',
  caseSensitive: false,
);

int? qualityHeight(String? label) {
  if (label == null) return null;
  final text = label.toLowerCase();
  final pixels = RegExp(r'(\d{3,4})\s*p').firstMatch(text);
  if (pixels != null) return int.parse(pixels.group(1)!);
  if (RegExp(r'(^|[^a-z0-9])(4k|uhd)($|[^a-z0-9])').hasMatch(text)) return 2160;
  if (RegExp(r'(^|[^a-z0-9])2k($|[^a-z0-9])').hasMatch(text)) return 1440;
  final bare = RegExp(
    r'(^|[^0-9])(2160|1440|1080|720|576|480|360|240)($|[^0-9])',
  ).firstMatch(text);
  return bare == null ? null : int.parse(bare.group(2)!);
}

SubtitleChoice? pickSubtitle({
  required List<SubtitleTrack> embedded,
  required List<MSubtitle> external,
  required String language,
}) {
  final wanted = language.trim().toLowerCase();
  if (wanted.isEmpty) return null;
  for (final track in embedded) {
    if (_languageMatches(wanted, track.language, track.title)) {
      return SubtitleChoice.embedded(track);
    }
  }
  for (final subtitle in external) {
    if (_languageMatches(wanted, subtitle.language, subtitle.label)) {
      return SubtitleChoice.external(subtitle);
    }
  }
  return null;
}

SubtitleChoice? pickAlwaysOnSubtitle({
  required List<SubtitleTrack> embedded,
  required List<MSubtitle> external,
  required String language,
}) {
  return pickSubtitle(
        embedded: embedded,
        external: external,
        language: language,
      ) ??
      pickSubtitle(embedded: embedded, external: external, language: 'en') ??
      (embedded.isNotEmpty
          ? SubtitleChoice.embedded(embedded.first)
          : external.isNotEmpty
          ? SubtitleChoice.external(external.first)
          : null);
}

bool _languageMatches(String wanted, String? code, String? title) {
  bool hit(String? value) {
    if (value == null || value.trim().isEmpty) return false;
    final v = value.trim().toLowerCase();
    if (v == wanted) return true;
    if (wanted.length >= 2 &&
        v.length >= 2 &&
        (v.startsWith(wanted) || wanted.startsWith(v))) {
      return true;
    }
    return v.contains(wanted) && wanted.length >= 3;
  }

  return hit(code) || hit(title);
}

class SubtitleChoice {
  const SubtitleChoice.embedded(SubtitleTrack this.track) : subtitle = null;
  const SubtitleChoice.external(MSubtitle this.subtitle) : track = null;

  final SubtitleTrack? track;
  final MSubtitle? subtitle;
}

String formatPlaybackTime(Duration value) {
  final total = value.isNegative ? Duration.zero : value;
  final hours = total.inHours;
  final minutes = total.inMinutes.remainder(60);
  final seconds = total.inSeconds.remainder(60);
  final ss = seconds.toString().padLeft(2, '0');
  return hours > 0
      ? '$hours:${minutes.toString().padLeft(2, '0')}:$ss'
      : '$minutes:$ss';
}
