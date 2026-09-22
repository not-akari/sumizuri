import 'package:http/http.dart' as http;

import 'package:sumizuri/core/utils/downloads/hls_playlist.dart';
import 'package:sumizuri/features/extensions/models/m_video.dart';

Future<List<MVideo>> expandHlsMasters(
  List<MVideo> videos, {
  required http.Client client,
  Duration timeout = const Duration(seconds: 8),
}) async {
  final out = <MVideo>[];
  for (final video in videos) {
    out.addAll(video.isHls ? await _expand(video, client, timeout) : [video]);
  }
  return out;
}

Future<List<MVideo>> _expand(
  MVideo video,
  http.Client client,
  Duration timeout,
) async {
  try {
    final address = Uri.parse(video.url);
    final response = await client
        .get(address, headers: video.headers)
        .timeout(timeout);
    if (response.statusCode != 200 || !isHlsMaster(response.body)) {
      return [video];
    }
    final master = parseHlsMaster(response.body, address);
    final byHeight = <int?, HlsVariant>{};
    for (final variant in master.variants) {
      final held = byHeight[variant.height];
      if (held == null || (variant.bandwidth ?? 0) > (held.bandwidth ?? 0)) {
        byHeight[variant.height ?? -variant.uri.hashCode] = variant;
      }
    }
    final variants = byHeight.values.toList()
      ..sort((a, b) => (b.height ?? 0).compareTo(a.height ?? 0));
    if (variants.length < 2) return [video];

    final wording = RegExp(
      r'\b(softsub|hardsub|sub|dub)\b',
      caseSensitive: false,
    ).firstMatch(video.quality ?? '')?.group(1);
    return [
      for (final (index, variant) in variants.indexed)
        _variantVideo(video, variant, master, index, wording),
    ];
  } catch (_) {
    return [video];
  }
}

MVideo _variantVideo(
  MVideo original,
  HlsVariant variant,
  HlsMaster master,
  int index,
  String? wording,
) {
  final base = variant.height != null
      ? '${variant.height}p'
      : variant.bandwidth != null
      ? '${(variant.bandwidth! / 1000).round()} kbps'
      : 'Quality ${index + 1}';
  final audio = pickHlsAudio(master, variant);
  return MVideo(
    url: variant.uri.toString(),
    quality: wording == null ? base : '$base $wording',
    headers: original.headers,
    subtitles: original.subtitles,
    audioTracks: original.audioTracks,
    intro: original.intro,
    outro: original.outro,
    pairedAudio: audio == null
        ? null
        : MAudioTrack(
            url: audio.uri.toString(),
            label: audio.name,
            language: audio.language,
          ),
  );
}
