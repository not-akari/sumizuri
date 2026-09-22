import 'dart:convert';

import 'package:html/parser.dart' as html_parser;

import 'package:sumizuri/core/utils/formatting/chapter_number.dart';
import 'package:sumizuri/features/extensions/models/m_chapter.dart';
import 'package:sumizuri/features/extensions/models/m_comment.dart';
import 'package:sumizuri/features/extensions/models/m_entry.dart';
import 'package:sumizuri/features/extensions/models/m_page.dart';
import 'package:sumizuri/features/extensions/models/m_video.dart';

({List<T> items, int skipped, Object? firstError}) decodeListLeniently<T>(
  String json,
  T Function(Map<String, dynamic> json) fromJson,
) {
  final decoded = jsonDecode(json) as List;
  final items = <T>[];
  var skipped = 0;
  Object? firstError;
  for (final raw in decoded) {
    try {
      items.add(fromJson((raw as Map).cast<String, dynamic>()));
    } catch (error) {
      skipped++;
      firstError ??= error;
    }
  }
  if (items.isEmpty && firstError != null) throw firstError;
  return (items: items, skipped: skipped, firstError: firstError);
}

String requireString(Map<String, dynamic> json, String key, String shape) {
  final value = json[key];
  if (value is String) return value;
  throw StateError(
    '$shape is missing its required "$key" field (got ${jsonEncode(json)}). '
    'Check the field mapping for this section.',
  );
}

MEntry entryFromJson(Map<String, dynamic> json) => MEntry(
  url: requireString(json, 'url', 'Entry'),
  title: requireString(json, 'title', 'Entry'),
  coverUrl: json['coverUrl'] as String?,
  bannerUrl: json['bannerUrl'] as String?,
  webUrl: json['webUrl'] as String?,
  author: json['author'] as String?,
  description: stripHtml(json['description'] as String?),
  rating: (json['rating'] as num?)?.toDouble(),
  status: json['status'] as String?,
  genres: (json['genres'] as List?)?.cast<String>(),
);

String? stripHtml(String? value) {
  if (value == null) return null;
  final text = html_parser.parse(value).body?.text.trim() ?? value.trim();
  return text.isEmpty ? null : text;
}

MChapter chapterFromJson(
  Map<String, dynamic> json, {
  String numberedAs = 'Chapter',
}) => MChapter(
  url: requireString(json, 'url', 'Chapter'),
  webUrl: json['webUrl'] as String?,
  title: _chapterTitle(json, numberedAs),
  number: (json['number'] as num?)?.toDouble(),
  scanlator: (json['scanlator'] as String?)?.trim().isEmpty ?? true
      ? null
      : (json['scanlator'] as String).trim(),
  dateUploaded: json['dateUploaded'] != null
      ? DateTime.tryParse(json['dateUploaded'] as String)
      : null,
  locked: json['locked'] as bool? ?? false,
  unlocksAt: json['unlocksAt'] != null
      ? DateTime.tryParse(json['unlocksAt'] as String)
      : null,
  season: _seasonKey(json['season']),
  seasonName: _cleanText(json['seasonName']),
  seasonCoverUrl: _cleanText(json['seasonCoverUrl']),
);

String? _seasonKey(Object? value) {
  if (value is num) return formatChapterNumber(value.toDouble());
  return _cleanText(value);
}

String _chapterTitle(Map<String, dynamic> json, String numberedAs) {
  final title = json['title'];
  if (title is String && title.trim().isNotEmpty) return title.trim();
  final number = json['number'];
  if (number is num) {
    return '$numberedAs ${formatChapterNumber(number.toDouble())}';
  }
  return requireString(json, 'title', 'Chapter');
}

MComment commentFromJson(Map<String, dynamic> json) => MComment(
  author: requireString(json, 'author', 'Comment'),
  text: requireString(json, 'text', 'Comment'),
  date: json['date'] != null ? DateTime.tryParse(json['date'] as String) : null,
  avatarUrl: json['avatarUrl'] as String?,
);

MPage pageFromJson(Map<String, dynamic> json) => MPage(
  index: json['index'] as int,
  imageUrl: json['imageUrl'] as String?,
  text: json['text'] as String?,
);

MTimeRange? _range(Map<String, dynamic> json, String name) {
  Duration? seconds(Object? value) {
    final number = value is num ? value : num.tryParse('$value'.trim());
    if (number == null || number.isNaN || number.isInfinite || number < 0) {
      return null;
    }
    return Duration(milliseconds: (number * 1000).round());
  }

  final nested = json[name];
  final start = seconds(nested is Map ? nested['start'] : json['${name}Start']);
  final end = seconds(nested is Map ? nested['end'] : json['${name}End']);
  if (start == null || end == null || end <= start) return null;
  return MTimeRange(start, end);
}

String _playableUrl(String url, Map<String, dynamic> json) {
  final full = url.startsWith('//') ? 'https:$url' : url;
  final uri = Uri.tryParse(full);
  if (uri == null ||
      uri.host.isEmpty ||
      (uri.scheme != 'http' && uri.scheme != 'https')) {
    throw FormatException(
      'The video address "$url" is not a full address (it must start with '
      'https://). The source most likely could not find the part it builds '
      'the address from; check that part of the page or response. '
      'Got: ${jsonEncode(json)}',
    );
  }
  return full;
}

MVideo videoFromJson(Map<String, dynamic> json) {
  final raw = requireString(json, 'url', 'Video').trim();
  if (raw.isEmpty) {
    throw StateError('Video has an empty "url" (got ${jsonEncode(json)}).');
  }
  final url = _playableUrl(raw, json);
  return MVideo(
    url: url,
    intro: _range(json, 'intro'),
    outro: _range(json, 'outro'),
    quality: _cleanText(json['quality']),
    headers: _stringMap(json['headers']),
    subtitles: [
      for (final item in _objects(json['subtitles']))
        if (_cleanText(item['url']) case final subtitleUrl?)
          MSubtitle(
            url: subtitleUrl,
            label:
                _cleanText(item['label']) ??
                _cleanText(item['language']) ??
                'Subtitle',
            language: _cleanText(item['language']),
          ),
    ],
    audioTracks: [
      for (final item in _objects(json['audioTracks']))
        if (_cleanText(item['url']) case final trackUrl?)
          MAudioTrack(
            url: trackUrl,
            label:
                _cleanText(item['label']) ??
                _cleanText(item['language']) ??
                'Audio',
            language: _cleanText(item['language']),
          ),
    ],
  );
}

String? _cleanText(Object? value) {
  if (value is! String) return null;
  final text = value.trim();
  return text.isEmpty ? null : text;
}

Map<String, String> _stringMap(Object? value) {
  if (value is! Map) return const {};
  return {
    for (final entry in value.entries)
      if (entry.key is String && entry.value is String)
        entry.key as String: entry.value as String,
  };
}

Iterable<Map<String, dynamic>> _objects(Object? value) sync* {
  if (value is! List) return;
  for (final item in value) {
    if (item is Map) yield item.cast<String, dynamic>();
  }
}
