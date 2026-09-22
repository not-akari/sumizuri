import 'dart:typed_data';

import 'package:sumizuri/core/utils/downloads/byte_range.dart';

/// A playlist that cannot be saved, such as a live stream.
class HlsUnsupported implements Exception {
  const HlsUnsupported(this.message);

  final String message;

  @override
  String toString() => message;
}

class HlsVariant {
  const HlsVariant({
    required this.uri,
    this.bandwidth,
    this.height,
    this.audioGroup,
  });

  final Uri uri;
  final int? bandwidth;
  final int? height;

  final String? audioGroup;
}

class HlsAudio {
  const HlsAudio({
    required this.uri,
    required this.groupId,
    required this.name,
    this.language,
    this.isDefault = false,
  });

  final Uri uri;
  final String groupId;
  final String name;
  final String? language;
  final bool isDefault;
}

class HlsMaster {
  const HlsMaster({required this.variants, required this.audio});

  final List<HlsVariant> variants;
  final List<HlsAudio> audio;
}

class HlsKey {
  const HlsKey({required this.uri, this.iv});

  final Uri uri;

  final Uint8List? iv;

  @override
  bool operator ==(Object other) =>
      other is HlsKey && other.uri == uri && _sameBytes(other.iv, iv);

  @override
  int get hashCode => Object.hash(uri, iv?.length);
}

class HlsSegment {
  const HlsSegment({
    required this.uri,
    required this.sequence,
    this.key,
    this.range,
  });

  final Uri uri;
  final ByteRange? range;

  final int sequence;
  final HlsKey? key;
}

class HlsMedia {
  const HlsMedia({
    required this.segments,
    this.initSegment,
    this.initKey,
    this.initRange,
  });

  final ByteRange? initRange;

  final List<HlsSegment> segments;

  final Uri? initSegment;
  final HlsKey? initKey;
}

bool isHlsMaster(String text) => text.contains('#EXT-X-STREAM-INF');

Map<String, String> parseHlsAttributes(String text) {
  final out = <String, String>{};
  var i = 0;
  while (i < text.length) {
    final eq = text.indexOf('=', i);
    if (eq < 0) break;
    final key = text.substring(i, eq).trim();
    var j = eq + 1;
    final String value;
    if (j < text.length && text[j] == '"') {
      final close = text.indexOf('"', j + 1);
      final end = close < 0 ? text.length : close;
      value = text.substring(j + 1, end);
      j = end + 1;
      final comma = text.indexOf(',', j);
      j = comma < 0 ? text.length : comma + 1;
    } else {
      final comma = text.indexOf(',', j);
      final end = comma < 0 ? text.length : comma;
      value = text.substring(j, end);
      j = end + 1;
    }
    if (key.isNotEmpty) out[key] = value;
    i = j;
  }
  return out;
}

Iterable<String> _lines(String text) => text
    .split(RegExp(r'\r?\n'))
    .map((line) => line.trim())
    .where((line) => line.isNotEmpty);

HlsMaster parseHlsMaster(String text, Uri base) {
  final variants = <HlsVariant>[];
  final audio = <HlsAudio>[];
  Map<String, String>? pending;
  for (final line in _lines(text)) {
    if (line.startsWith('#EXT-X-STREAM-INF:')) {
      pending = parseHlsAttributes(line.substring('#EXT-X-STREAM-INF:'.length));
    } else if (line.startsWith('#EXT-X-MEDIA:')) {
      final attributes = parseHlsAttributes(
        line.substring('#EXT-X-MEDIA:'.length),
      );
      final uri = attributes['URI'];
      // Without a URI the sound is inside the video pieces already.
      if (attributes['TYPE'] == 'AUDIO' && uri != null) {
        audio.add(
          HlsAudio(
            uri: base.resolve(uri),
            groupId: attributes['GROUP-ID'] ?? '',
            name: attributes['NAME'] ?? attributes['LANGUAGE'] ?? 'Audio',
            language: attributes['LANGUAGE'],
            isDefault: attributes['DEFAULT'] == 'YES',
          ),
        );
      }
    } else if (!line.startsWith('#') && pending != null) {
      final resolution = pending['RESOLUTION']?.split('x');
      variants.add(
        HlsVariant(
          uri: base.resolve(line),
          bandwidth: int.tryParse(pending['BANDWIDTH'] ?? ''),
          height: resolution != null && resolution.length == 2
              ? int.tryParse(resolution[1])
              : null,
          audioGroup: pending['AUDIO'],
        ),
      );
      pending = null;
    }
  }
  return HlsMaster(variants: variants, audio: audio);
}

HlsVariant? pickHlsVariant(HlsMaster master, {int? preferredHeight}) {
  if (master.variants.isEmpty) return null;
  if (preferredHeight != null) {
    for (final variant in master.variants) {
      if (variant.height == preferredHeight) return variant;
    }
  }
  final sorted = [...master.variants]
    ..sort((a, b) {
      final byHeight = (b.height ?? 0).compareTo(a.height ?? 0);
      return byHeight != 0
          ? byHeight
          : (b.bandwidth ?? 0).compareTo(a.bandwidth ?? 0);
    });
  return sorted.first;
}

HlsAudio? pickHlsAudio(HlsMaster master, HlsVariant variant) {
  final group = variant.audioGroup;
  if (group == null) return null;
  final candidates = master.audio.where((a) => a.groupId == group).toList();
  if (candidates.isEmpty) return null;
  return candidates.firstWhere((a) => a.isDefault, orElse: () => candidates[0]);
}

HlsMedia parseHlsMedia(String text, Uri base) {
  final segments = <HlsSegment>[];
  var sequence = 0;
  HlsKey? key;
  Uri? initSegment;
  HlsKey? initKey;
  ByteRange? initRange;
  // A range without an offset starts where the last one of the same file ended.
  (int, int?)? pendingRange;
  final ends = <String, int>{};
  for (final line in _lines(text)) {
    if (line.startsWith('#EXT-X-MEDIA-SEQUENCE:')) {
      sequence =
          int.tryParse(line.substring('#EXT-X-MEDIA-SEQUENCE:'.length)) ?? 0;
    } else if (line.startsWith('#EXT-X-KEY:')) {
      final attributes = parseHlsAttributes(
        line.substring('#EXT-X-KEY:'.length),
      );
      final method = attributes['METHOD'] ?? 'NONE';
      if (method == 'NONE') {
        key = null;
      } else if (method == 'AES-128') {
        final uri = attributes['URI'];
        if (uri == null) {
          throw const HlsUnsupported(
            'An encrypted stream gives no key address',
          );
        }
        key = HlsKey(uri: base.resolve(uri), iv: _parseIv(attributes['IV']));
      } else {
        throw HlsUnsupported(
          'This stream uses $method encryption, which cannot be saved',
        );
      }
    } else if (line.startsWith('#EXT-X-MAP:')) {
      final attributes = parseHlsAttributes(
        line.substring('#EXT-X-MAP:'.length),
      );
      final uri = attributes['URI'];
      if (uri != null) {
        initSegment = base.resolve(uri);
        initKey = key;
        final raw = _parseRange(attributes['BYTERANGE']);
        initRange = raw == null ? null : ByteRange(raw.$2 ?? 0, raw.$1);
      }
    } else if (line.startsWith('#EXT-X-BYTERANGE:')) {
      pendingRange = _parseRange(line.substring('#EXT-X-BYTERANGE:'.length));
    } else if (!line.startsWith('#')) {
      final uri = base.resolve(line);
      ByteRange? range;
      final raw = pendingRange;
      if (raw != null) {
        final start = raw.$2 ?? ends[uri.toString()] ?? 0;
        range = ByteRange(start, raw.$1);
        ends[uri.toString()] = start + raw.$1;
        pendingRange = null;
      }
      segments.add(
        HlsSegment(uri: uri, sequence: sequence, key: key, range: range),
      );
      sequence++;
    }
  }
  return HlsMedia(
    segments: segments,
    initSegment: initSegment,
    initKey: initKey,
    initRange: initRange,
  );
}

// "length" or "length@offset", as (length, offset).
(int, int?)? _parseRange(String? text) {
  if (text == null) return null;
  final parts = text.split('@');
  final length = int.tryParse(parts[0].trim());
  if (length == null || length <= 0) return null;
  return (length, parts.length > 1 ? int.tryParse(parts[1].trim()) : null);
}

Uint8List? _parseIv(String? value) {
  if (value == null) return null;
  var hex = value.trim();
  if (hex.startsWith('0x') || hex.startsWith('0X')) hex = hex.substring(2);
  if (hex.isEmpty || hex.length > 32) return null;
  hex = hex.padLeft(32, '0');
  final bytes = Uint8List(16);
  for (var i = 0; i < 16; i++) {
    final part = int.tryParse(hex.substring(i * 2, i * 2 + 2), radix: 16);
    if (part == null) return null;
    bytes[i] = part;
  }
  return bytes;
}

bool _sameBytes(Uint8List? a, Uint8List? b) {
  if (a == null || b == null) return a == b;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
