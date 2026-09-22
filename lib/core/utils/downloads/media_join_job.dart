import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import 'package:sumizuri/core/utils/downloads/byte_range.dart';
import 'package:sumizuri/core/utils/downloads/segment_fetcher.dart';

/// One piece to fetch and join. [meta] is room for a downloader's own bookkeeping, such as an HLS key.
class JoinPiece {
  const JoinPiece(this.uri, {this.range, this.meta});

  final Uri uri;
  final ByteRange? range;
  final Object? meta;
}

/// Fetches a list of pieces and joins them into one file, resuming what was already fetched.
class MediaJoinJob {
  MediaJoinJob({
    required this.baseName,
    required this.extension,
    required this.pieces,
    this.transform,
  });

  final String baseName;

  /// Includes the leading dot.
  final String extension;

  final List<JoinPiece> pieces;

  /// Changes a piece's bytes after fetching, such as HLS's decryption. Told the piece's index.
  final Future<Uint8List> Function(int index, JoinPiece piece, Uint8List raw)?
  transform;

  String get fileName => '$baseName$extension';

  Future<void> save(
    SegmentFetcher fetcher,
    Directory dir,
    int concurrency,
    void Function() oneDone,
  ) async {
    final target = File(p.join(dir.path, fileName));
    if (await target.exists()) {
      for (var i = 0; i < pieces.length; i++) {
        oneDone();
      }
      return;
    }
    final parts = Directory(p.join(dir.path, '.parts_$baseName'));
    await _prepareParts(parts);

    File part(int i) => File(p.join(parts.path, i.toString().padLeft(6, '0')));

    var next = 0;
    Object? failure;
    StackTrace? failureStack;
    Future<void> worker() async {
      while (failure == null) {
        final i = next++;
        if (i >= pieces.length) return;
        if (await part(i).exists()) {
          oneDone();
          continue;
        }
        try {
          final piece = pieces[i];
          var bytes = await fetcher.bytes(piece.uri, range: piece.range);
          if (transform != null) bytes = await transform!(i, piece, bytes);
          final temp = File('${part(i).path}.tmp');
          await temp.writeAsBytes(bytes, flush: true);
          await temp.rename(part(i).path);
          oneDone();
        } catch (error, stack) {
          failure ??= error;
          failureStack ??= stack;
        }
      }
    }

    await Future.wait([
      for (var w = 0; w < concurrency.clamp(1, 8); w++) worker(),
    ]);
    final error = failure;
    if (error != null) Error.throwWithStackTrace(error, failureStack!);

    // Joined into a part file first, so a folder never holds a half-joined video.
    final joined = File('${target.path}.part');
    final out = await joined.open(mode: FileMode.write);
    try {
      for (var i = 0; i < pieces.length; i++) {
        await out.writeFrom(await part(i).readAsBytes());
      }
    } finally {
      await out.close();
    }
    await joined.rename(target.path);
    await parts.delete(recursive: true);
  }

  Future<void> _prepareParts(Directory parts) async {
    final marker = File(p.join(parts.path, 'plan'));
    final plan = '$baseName|${pieces.length}';
    if (await parts.exists()) {
      final same = await marker.exists() && await marker.readAsString() == plan;
      if (same) return;
      await parts.delete(recursive: true);
    }
    await parts.create(recursive: true);
    await marker.writeAsString(plan);
  }
}
