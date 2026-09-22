import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import 'package:sumizuri/core/utils/downloads/dash_download.dart';
import 'package:sumizuri/core/utils/downloads/download_stopped.dart';
import 'package:sumizuri/core/utils/downloads/hls_download.dart';
import 'package:sumizuri/features/extensions/models/m_video.dart';

const _recordName = 'episode.json';
const _partSuffix = '.part';
const _videoExtensions = {'.mp4', '.mkv', '.webm', '.m4v', '.mov', '.avi'};

/// How long a download may go without receiving anything before it gives up.
const _idleTimeout = Duration(seconds: 30);

MVideo? pickDownloadable(List<MVideo> videos, {String? preferredQuality}) {
  final savable = videos
      .where((v) => !v.isPlaylist || v.isHls || v.isDash)
      .toList();
  if (savable.isEmpty) return null;
  final files = savable.where((v) => !v.isPlaylist).toList();
  final pool = files.isNotEmpty ? files : savable;
  if (preferredQuality != null) {
    for (final video in pool) {
      if (video.quality == preferredQuality) return video;
    }
  }
  return pool.first;
}

int? _heightIn(String? quality) {
  final match = RegExp(r'(d{3,4})s*p').firstMatch(quality ?? '');
  return match == null ? null : int.parse(match.group(1)!);
}

String _extensionOf(String url, {String fallback = '.mp4'}) {
  final ext = p.extension(Uri.tryParse(url)?.path ?? url).toLowerCase();
  return _videoExtensions.contains(ext) ? ext : fallback;
}

String _subtitleExtensionOf(String url) {
  final ext = p.extension(Uri.tryParse(url)?.path ?? url).toLowerCase();
  return const {'.vtt', '.srt', '.ass', '.ssa'}.contains(ext) ? ext : '.vtt';
}

Future<void> writeEpisodeFiles({
  required Directory dir,
  required MVideo video,
  required http.Client client,
  void Function(double fraction)? onProgress,
  bool Function()? shouldStop,
}) async {
  await dir.create(recursive: true);
  final finished = await localEpisodeVideo(dir.path);
  if (finished != null) return;

  final String name;
  final audio = <Map<String, String?>>[];
  try {
    if (video.isHls) {
      final saved = await saveHlsStream(
        client: client,
        playlist: Uri.parse(video.url),
        headers: video.headers,
        dir: dir,
        preferredHeight: _heightIn(video.quality),
        onProgress: onProgress,
        shouldStop: shouldStop,
      );
      name = saved.video;
      for (final track in saved.audio) {
        audio.add({
          'file': track.file,
          'label': track.label,
          'language': track.language,
        });
      }
    } else if (video.isDash) {
      final saved = await saveDashStream(
        client: client,
        manifest: Uri.parse(video.url),
        headers: video.headers,
        dir: dir,
        preferredHeight: _heightIn(video.quality),
        onProgress: onProgress,
        shouldStop: shouldStop,
      );
      name = saved.video;
      for (final track in saved.audio) {
        audio.add({
          'file': track.file,
          'label': track.label,
          'language': track.language,
        });
      }
    } else {
      name = 'episode${_extensionOf(video.url)}';
      final target = File(p.join(dir.path, name));
      final part = File('${target.path}$_partSuffix');
      await _fetchVideo(client, video, part, target, onProgress, shouldStop);
    }
  } catch (_) {
    // A client closed to stop a download fails its request, which is a stop, not a failure.
    if (shouldStop?.call() ?? false) throw const DownloadStopped();
    rethrow;
  }

  final subtitles = <Map<String, String?>>[];
  for (final (index, subtitle) in video.subtitles.indexed) {
    final file = 'subtitle_$index${_subtitleExtensionOf(subtitle.url)}';
    try {
      final response = await client.get(
        Uri.parse(subtitle.url),
        headers: video.headers,
      );
      if (response.statusCode != 200) continue;
      await File(p.join(dir.path, file)).writeAsBytes(response.bodyBytes);
      subtitles.add({
        'file': file,
        'label': subtitle.label,
        'language': subtitle.language,
      });
    } catch (_) {}
  }

  // Written last: a folder with a record is a whole episode, one without is not.
  await File(p.join(dir.path, _recordName)).writeAsString(
    jsonEncode({'video': name, 'subtitles': subtitles, 'audio': audio}),
  );
}

Future<void> _fetchVideo(
  http.Client client,
  MVideo video,
  File part,
  File target,
  void Function(double fraction)? onProgress,
  bool Function()? shouldStop,
) async {
  var have = await part.exists() ? await part.length() : 0;
  final request = http.Request('GET', Uri.parse(video.url))
    ..headers.addAll(video.headers);
  if (have > 0) request.headers['Range'] = 'bytes=$have-';
  final response = await client.send(request);

  if (have > 0 && response.statusCode == 416) {
    await response.stream.drain<void>();
    await part.rename(target.path);
    return;
  }
  final resumed = have > 0 && response.statusCode == 206;
  if (response.statusCode != 200 && !resumed) {
    await response.stream.drain<void>();
    throw HttpException('HTTP ${response.statusCode}', uri: request.url);
  }
  if (!resumed) have = 0;

  final file = await part.open(
    mode: resumed ? FileMode.append : FileMode.write,
  );
  try {
    // The size is known only when the server says it. Without it the progress stays unknown.
    final total = response.contentLength == null
        ? null
        : have + response.contentLength!;
    var received = have;
    await for (final chunk in response.stream.timeout(_idleTimeout)) {
      if (shouldStop?.call() ?? false) throw const DownloadStopped();
      await file.writeFrom(chunk);
      received += chunk.length;
      if (total != null && total > 0) onProgress?.call(received / total);
    }
  } finally {
    await file.close();
  }
  await part.rename(target.path);
}

Future<MVideo?> localEpisodeVideo(String directoryPath) async {
  final record = File(p.join(directoryPath, _recordName));
  if (!await record.exists()) return null;
  try {
    final json = (jsonDecode(await record.readAsString()) as Map)
        .cast<String, dynamic>();
    final video = File(p.join(directoryPath, json['video'] as String));
    if (!await video.exists()) return null;
    return MVideo(
      url: video.path,
      audioTracks: [
        for (final item in (json['audio'] as List? ?? const []))
          if ((item as Map)['file'] case final String file)
            if (await File(p.join(directoryPath, file)).exists())
              MAudioTrack(
                url: p.join(directoryPath, file),
                label: (item['label'] as String?) ?? 'Audio',
                language: item['language'] as String?,
              ),
      ],
      subtitles: [
        for (final item in (json['subtitles'] as List? ?? const []))
          if ((item as Map)['file'] case final String file)
            if (await File(p.join(directoryPath, file)).exists())
              MSubtitle(
                url: p.join(directoryPath, file),
                label: (item['label'] as String?) ?? 'Subtitle',
                language: item['language'] as String?,
              ),
      ],
    );
  } catch (_) {
    return null;
  }
}
