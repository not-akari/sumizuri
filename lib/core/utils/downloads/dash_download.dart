import 'dart:io';

import 'package:http/http.dart' as http;

import 'package:sumizuri/core/utils/downloads/dash_playlist.dart';
import 'package:sumizuri/core/utils/downloads/media_join_job.dart';
import 'package:sumizuri/core/utils/downloads/segment_fetcher.dart';

typedef DashSaved = ({
  String video,
  List<({String file, String label, String? language})> audio,
});

/// Saves a DASH stream that is not DRM protected and not live, video and audio as separate files, the same as HLS with a separate audio rendition.
Future<DashSaved> saveDashStream({
  required http.Client client,
  required Uri manifest,
  required Map<String, String> headers,
  required Directory dir,
  int? preferredHeight,
  String? preferredLanguage,
  void Function(double fraction)? onProgress,
  int concurrency = 3,
  Future<void> Function(Duration) pause = defaultPause,
  bool Function()? shouldStop,
}) async {
  final fetcher = SegmentFetcher(client, headers, pause, shouldStop);
  final text = await fetcher.text(manifest);
  final parsed = parseMpd(text, manifest);

  final videoTrack = pickDashVideo(parsed, preferredHeight: preferredHeight);
  if (videoTrack == null) {
    throw const DashUnsupported('The manifest lists no video');
  }
  final audioTrack = pickDashAudio(parsed, language: preferredLanguage);

  final video = _job(videoTrack, 'episode');
  final audio = audioTrack == null ? null : _job(audioTrack, 'audio_0');
  final jobs = [video, ?audio];
  final total = jobs.fold<int>(0, (sum, job) => sum + job.pieces.length);
  var done = 0;
  void oneDone() {
    done++;
    onProgress?.call(done / total);
  }

  await dir.create(recursive: true);
  for (final job in jobs) {
    await job.save(fetcher, dir, concurrency, oneDone);
  }
  return (
    video: video.fileName,
    audio: [
      if (audio != null && audioTrack != null)
        (
          file: audio.fileName,
          label: audioTrack.label ?? audioTrack.lang ?? 'Audio',
          language: audioTrack.lang,
        ),
    ],
  );
}

MediaJoinJob _job(DashTrack track, String baseName) {
  final pieces = [
    if (track.initSegment != null)
      JoinPiece(track.initSegment!, range: track.initRange),
    for (final segment in track.segments)
      JoinPiece(segment.uri, range: segment.range),
  ];
  return MediaJoinJob(
    baseName: baseName,
    extension: baseName == 'episode' ? '.mp4' : '.m4a',
    pieces: pieces,
  );
}
