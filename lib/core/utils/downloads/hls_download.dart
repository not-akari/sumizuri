import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:pointycastle/export.dart' as pc;

import 'package:sumizuri/core/utils/downloads/hls_playlist.dart';
import 'package:sumizuri/core/utils/downloads/media_join_job.dart';
import 'package:sumizuri/core/utils/downloads/segment_fetcher.dart';

typedef HlsSaved = ({
  String video,
  List<({String file, String label, String? language})> audio,
});

Future<HlsSaved> saveHlsStream({
  required http.Client client,
  required Uri playlist,
  required Map<String, String> headers,
  required Directory dir,
  int? preferredHeight,
  void Function(double fraction)? onProgress,
  int concurrency = 3,
  Future<void> Function(Duration) pause = defaultPause,
  bool Function()? shouldStop,
}) async {
  final fetcher = SegmentFetcher(client, headers, pause, shouldStop);
  final text = await fetcher.text(playlist);

  final Uri videoUri;
  HlsAudio? audioChoice;
  if (isHlsMaster(text)) {
    final master = parseHlsMaster(text, playlist);
    final variant = pickHlsVariant(master, preferredHeight: preferredHeight);
    if (variant == null) {
      throw const HlsUnsupported('The stream lists no video');
    }
    videoUri = variant.uri;
    audioChoice = pickHlsAudio(master, variant);
  } else {
    videoUri = playlist;
  }

  final video = await _job(fetcher, videoUri, 'episode');
  final audio = audioChoice == null
      ? null
      : await _job(fetcher, audioChoice.uri, 'audio_0');
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
      if (audio != null && audioChoice != null)
        (
          file: audio.fileName,
          label: audioChoice.name,
          language: audioChoice.language,
        ),
    ],
  );
}

Future<MediaJoinJob> _job(
  SegmentFetcher fetcher,
  Uri uri,
  String baseName,
) async {
  final media = parseHlsMedia(await fetcher.text(uri), uri);
  if (media.segments.isEmpty) {
    throw const HlsUnsupported('The stream has no pieces to save');
  }
  final hasInit = media.initSegment != null;
  final extension = hasInit
      ? '.mp4'
      : (media.segments.first.uri.path.toLowerCase().endsWith('.aac')
            ? '.aac'
            : '.ts');
  final pieces = [
    if (media.initSegment != null)
      JoinPiece(
        media.initSegment!,
        range: media.initRange,
        meta: HlsSegment(
          uri: media.initSegment!,
          sequence: 0,
          key: media.initKey,
        ),
      ),
    for (final segment in media.segments)
      JoinPiece(segment.uri, range: segment.range, meta: segment),
  ];
  return MediaJoinJob(
    baseName: baseName,
    extension: extension,
    pieces: pieces,
    transform: (index, piece, raw) async {
      final segment = piece.meta as HlsSegment;
      var bytes = raw;
      final key = segment.key;
      if (key != null) {
        bytes = _decrypt(
          bytes,
          await fetcher.cached(key.uri),
          key.iv ?? _ivFromSequence(segment.sequence),
        );
      }
      // Some hosts put a fake picture header in front of each piece so it looks like an image.
      return hasInit ? bytes : stripFakeHeader(bytes);
    },
  );
}

Uint8List _ivFromSequence(int sequence) {
  final iv = Uint8List(16);
  var value = sequence;
  for (var i = 15; i >= 8 && value > 0; i--) {
    iv[i] = value & 0xff;
    value >>= 8;
  }
  return iv;
}

Uint8List _decrypt(Uint8List data, Uint8List key, Uint8List iv) {
  if (data.isEmpty) return data;
  final cipher =
      pc.PaddedBlockCipherImpl(
        pc.PKCS7Padding(),
        pc.CBCBlockCipher(pc.AESEngine()),
      )..init(
        false,
        pc.PaddedBlockCipherParameters(
          pc.ParametersWithIV(pc.KeyParameter(key), iv),
          null,
        ),
      );
  return cipher.process(data);
}

/// Bytes without anything in front of the first transport-stream packet.
Uint8List stripFakeHeader(Uint8List bytes) {
  const packet = 188;
  if (bytes.length < packet * 3 + 1) return bytes;
  bool syncAt(int i) =>
      bytes[i] == 0x47 &&
      bytes[i + packet] == 0x47 &&
      bytes[i + packet * 2] == 0x47;
  if (syncAt(0)) return bytes;
  final last = (bytes.length - packet * 2 - 1).clamp(0, 16384);
  for (var i = 1; i < last; i++) {
    if (syncAt(i)) return Uint8List.sublistView(bytes, i);
  }
  return bytes;
}
