import 'package:sumizuri/core/utils/downloads/byte_range.dart';
import 'package:sumizuri/core/utils/downloads/mini_xml.dart';

/// A manifest that cannot be saved: live, DRM protected, or with no usable track.
class DashUnsupported implements Exception {
  const DashUnsupported(this.message);

  final String message;

  @override
  String toString() => message;
}

class DashSegment {
  const DashSegment({required this.uri, this.range});

  final Uri uri;
  final ByteRange? range;
}

/// A representation resolved to its pieces: an optional init piece, then the media ones.
class DashTrack {
  const DashTrack({
    required this.id,
    required this.bandwidth,
    required this.height,
    required this.lang,
    required this.label,
    required this.initSegment,
    required this.initRange,
    required this.segments,
  });

  final String id;
  final int? bandwidth;
  final int? height;
  final String? lang;
  final String? label;

  final Uri? initSegment;
  final ByteRange? initRange;
  final List<DashSegment> segments;
}

class DashManifest {
  const DashManifest({required this.videoTracks, required this.audioTracks});

  final List<DashTrack> videoTracks;
  final List<DashTrack> audioTracks;
}

/// Reads an MPD manifest. Only its first period is used, the whole thing for ordinary VOD.
DashManifest parseMpd(String text, Uri base) {
  final root = parseXml(text);
  if (root == null || root.tag != 'MPD') {
    throw const DashUnsupported('Not a DASH manifest');
  }
  if (root.attr('type') == 'dynamic') {
    throw const DashUnsupported('A live stream cannot be saved');
  }
  final presentationDuration = _parseIsoDuration(
    root.attr('mediaPresentationDuration'),
  );
  final mpdBase = _resolve(base, root.first('BaseURL')?.text);

  final period = root.first('Period');
  if (period == null) {
    throw const DashUnsupported('The manifest lists no period');
  }
  final periodBase = _resolve(mpdBase, period.first('BaseURL')?.text);
  final periodDuration =
      _parseIsoDuration(period.attr('duration')) ?? presentationDuration;

  final video = <DashTrack>[];
  final audio = <DashTrack>[];
  for (final adaptation in period.child('AdaptationSet')) {
    _refuseProtected(adaptation);
    final adaptationBase = _resolve(
      periodBase,
      adaptation.first('BaseURL')?.text,
    );
    final kindHint = adaptation.attr('contentType') ?? '';
    final label = _label(adaptation);
    final asTemplate = adaptation.first('SegmentTemplate');
    final asList = adaptation.first('SegmentList');
    final asSegBase = adaptation.first('SegmentBase');

    for (final representation in adaptation.child('Representation')) {
      _refuseProtected(representation);
      final mimeType =
          representation.attr('mimeType') ?? adaptation.attr('mimeType') ?? '';
      final kind = kindHint.isNotEmpty ? kindHint : _mimeKind(mimeType);
      if (kind != 'video' && kind != 'audio') continue;

      final repBase = _resolve(
        adaptationBase,
        representation.first('BaseURL')?.text,
      );
      final bandwidth = int.tryParse(representation.attr('bandwidth') ?? '');
      final height = int.tryParse(
        representation.attr('height') ?? adaptation.attr('height') ?? '',
      );
      final repId = representation.attr('id') ?? '';

      final media = _resolveMedia(
        repTemplate: representation.first('SegmentTemplate'),
        asTemplate: asTemplate,
        repList: representation.first('SegmentList'),
        asList: asList,
        repSegBase: representation.first('SegmentBase'),
        asSegBase: asSegBase,
        url: repBase,
        repId: repId,
        bandwidth: bandwidth,
        periodDuration: periodDuration,
      );
      if (media == null || media.segments.isEmpty) continue;

      final track = DashTrack(
        id: repId,
        bandwidth: bandwidth,
        height: height,
        lang: adaptation.attr('lang'),
        label: label,
        initSegment: media.initSegment,
        initRange: media.initRange,
        segments: media.segments,
      );
      (kind == 'video' ? video : audio).add(track);
    }
  }
  return DashManifest(videoTracks: video, audioTracks: audio);
}

/// The sharpest track, or the one at [preferredHeight] when the manifest has it.
DashTrack? pickDashVideo(DashManifest manifest, {int? preferredHeight}) {
  if (manifest.videoTracks.isEmpty) return null;
  if (preferredHeight != null) {
    for (final track in manifest.videoTracks) {
      if (track.height == preferredHeight) return track;
    }
  }
  final sorted = [...manifest.videoTracks]
    ..sort((a, b) {
      final byHeight = (b.height ?? 0).compareTo(a.height ?? 0);
      return byHeight != 0
          ? byHeight
          : (b.bandwidth ?? 0).compareTo(a.bandwidth ?? 0);
    });
  return sorted.first;
}

/// The named language, else the best quality audio.
DashTrack? pickDashAudio(DashManifest manifest, {String? language}) {
  if (manifest.audioTracks.isEmpty) return null;
  if (language != null) {
    for (final track in manifest.audioTracks) {
      if (track.lang == language) return track;
    }
  }
  final sorted = [...manifest.audioTracks]
    ..sort((a, b) => (b.bandwidth ?? 0).compareTo(a.bandwidth ?? 0));
  return sorted.first;
}

void _refuseProtected(XmlNode node) {
  if (node.child('ContentProtection').isNotEmpty) {
    throw const DashUnsupported('This stream is protected and cannot be saved');
  }
}

String? _label(XmlNode adaptation) {
  final direct = adaptation.first('Label')?.text;
  if (direct != null && direct.isNotEmpty) return direct;
  final role = adaptation.first('Role')?.attr('value');
  return role != null && role.isNotEmpty ? role : null;
}

String _mimeKind(String mimeType) {
  if (mimeType.startsWith('video/')) return 'video';
  if (mimeType.startsWith('audio/')) return 'audio';
  return '';
}

Uri _resolve(Uri base, String? relative) {
  final text = relative?.trim();
  if (text == null || text.isEmpty) return base;
  return base.resolve(text);
}

// One resolved representation's pieces, before it becomes a DashTrack.
class _Media {
  const _Media({required this.segments, this.initSegment, this.initRange});

  final Uri? initSegment;
  final ByteRange? initRange;
  final List<DashSegment> segments;
}

_Media? _resolveMedia({
  required XmlNode? repTemplate,
  required XmlNode? asTemplate,
  required XmlNode? repList,
  required XmlNode? asList,
  required XmlNode? repSegBase,
  required XmlNode? asSegBase,
  required Uri url,
  required String repId,
  required int? bandwidth,
  required Duration? periodDuration,
}) {
  final template = repTemplate ?? asTemplate;
  if (template != null) {
    final media = _fromSegmentTemplate(
      template,
      url,
      repId: repId,
      bandwidth: bandwidth,
      periodDuration: periodDuration,
    );
    if (media != null) return media;
  }
  final list = repList ?? asList;
  if (list != null) {
    final media = _fromSegmentList(list, url);
    if (media != null) return media;
  }
  return _wholeFile(url, repSegBase ?? asSegBase);
}

_Media? _fromSegmentTemplate(
  XmlNode template,
  Uri base, {
  required String repId,
  required int? bandwidth,
  required Duration? periodDuration,
}) {
  final mediaTemplate = template.attr('media');
  if (mediaTemplate == null) return null;
  final timescale = int.tryParse(template.attr('timescale') ?? '') ?? 1;
  final startNumber = int.tryParse(template.attr('startNumber') ?? '') ?? 1;
  final timeline = template.first('SegmentTimeline');
  final segments = <DashSegment>[];

  if (timeline != null) {
    final entries = timeline.child('S').toList();
    var number = startNumber;
    var time = 0;
    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final duration = int.tryParse(entry.attr('d') ?? '') ?? 0;
      if (duration <= 0) continue;
      final start = int.tryParse(entry.attr('t') ?? '');
      if (start != null) time = start;
      final repeat = int.tryParse(entry.attr('r') ?? '0') ?? 0;
      // r=-1 fills up to the next entry, or to the end of the period for the last one.
      final count = repeat >= 0
          ? repeat + 1
          : _fillCount(entries, i, time, duration, periodDuration);
      for (var k = 0; k < count; k++) {
        segments.add(
          DashSegment(
            uri: base.resolve(
              _expandTemplate(
                mediaTemplate,
                repId: repId,
                number: number,
                time: time,
                bandwidth: bandwidth,
              ),
            ),
          ),
        );
        time += duration;
        number++;
      }
    }
  } else {
    final segmentDuration = int.tryParse(template.attr('duration') ?? '');
    if (segmentDuration == null ||
        segmentDuration <= 0 ||
        periodDuration == null) {
      return null;
    }
    final seconds = segmentDuration / timescale;
    final total = periodDuration.inMilliseconds / 1000;
    final count = (total / seconds).ceil();
    for (var n = 0; n < count; n++) {
      segments.add(
        DashSegment(
          uri: base.resolve(
            _expandTemplate(
              mediaTemplate,
              repId: repId,
              number: startNumber + n,
              bandwidth: bandwidth,
            ),
          ),
        ),
      );
    }
  }
  if (segments.isEmpty) return null;

  final initTemplate = template.attr('initialization');
  final initSegment = initTemplate == null
      ? null
      : base.resolve(
          _expandTemplate(initTemplate, repId: repId, bandwidth: bandwidth),
        );
  return _Media(initSegment: initSegment, segments: segments);
}

int _fillCount(
  List<XmlNode> entries,
  int index,
  int time,
  int duration,
  Duration? periodDuration,
) {
  if (index + 1 < entries.length) {
    final next = int.tryParse(entries[index + 1].attr('t') ?? '');
    if (next != null && next > time) return ((next - time) / duration).round();
  }
  if (periodDuration != null) {
    final endMs = periodDuration.inMilliseconds;
    if (endMs > time) {
      return ((endMs - time) / duration).round().clamp(1, 100000);
    }
  }
  return 1;
}

_Media? _fromSegmentList(XmlNode list, Uri base) {
  final initElement = list.first('Initialization');
  final initSource = initElement?.attr('sourceURL');
  final segments = <DashSegment>[];
  for (final entry in list.child('SegmentURL')) {
    final media = entry.attr('media');
    if (media == null) continue;
    segments.add(
      DashSegment(
        uri: base.resolve(media),
        range: _parseByteRange(entry.attr('mediaRange')),
      ),
    );
  }
  if (segments.isEmpty) return null;
  return _Media(
    initSegment: initSource == null ? null : base.resolve(initSource),
    initRange: _parseByteRange(initElement?.attr('range')),
    segments: segments,
  );
}

// SegmentBase alone means the whole representation is one file with nothing to list.
_Media _wholeFile(Uri repBase, XmlNode? segmentBase) {
  final initElement = segmentBase?.first('Initialization');
  final initSource = initElement?.attr('sourceURL');
  if (initSource != null) {
    final initUri = repBase.resolve(initSource);
    if (initUri.toString() != repBase.toString()) {
      return _Media(
        initSegment: initUri,
        initRange: _parseByteRange(initElement!.attr('range')),
        segments: [DashSegment(uri: repBase)],
      );
    }
  }
  return _Media(segments: [DashSegment(uri: repBase)]);
}

String _expandTemplate(
  String template, {
  required String repId,
  int? number,
  int? time,
  int? bandwidth,
}) {
  var out = template.replaceAll(r'$RepresentationID$', repId);
  out = out.replaceAllMapped(
    RegExp(r'\$Bandwidth(%0(\d+)d)?\$'),
    (m) => _padded(bandwidth ?? 0, m[2]),
  );
  out = out.replaceAllMapped(
    RegExp(r'\$Number(%0(\d+)d)?\$'),
    (m) => _padded(number ?? 0, m[2]),
  );
  out = out.replaceAllMapped(
    RegExp(r'\$Time(%0(\d+)d)?\$'),
    (m) => _padded(time ?? 0, m[2]),
  );
  return out.replaceAll(r'$$', r'$');
}

String _padded(int value, String? width) =>
    width == null ? '$value' : '$value'.padLeft(int.parse(width), '0');

ByteRange? _parseByteRange(String? text) {
  if (text == null) return null;
  final parts = text.split('-');
  if (parts.length != 2) return null;
  final start = int.tryParse(parts[0].trim());
  final end = int.tryParse(parts[1].trim());
  if (start == null || end == null || end < start) return null;
  return ByteRange(start, end - start + 1);
}

Duration? _parseIsoDuration(String? text) {
  if (text == null) return null;
  final match = RegExp(
    r'^P(?:\d+Y)?(?:\d+M)?(?:\d+D)?(?:T(?:(\d+)H)?(?:(\d+)M)?(?:([\d.]+)S)?)?$',
  ).firstMatch(text.trim());
  if (match == null) return null;
  final hours = int.tryParse(match[1] ?? '') ?? 0;
  final minutes = int.tryParse(match[2] ?? '') ?? 0;
  final seconds = double.tryParse(match[3] ?? '') ?? 0;
  return Duration(
    hours: hours,
    minutes: minutes,
    milliseconds: (seconds * 1000).round(),
  );
}
