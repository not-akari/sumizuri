import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'package:sumizuri/features/extensions/models/m_video.dart';

const _maxEntries = 400;
const _hiddenHeaders = {'cookie', 'authorization', 'proxy-authorization'};

class PlaybackLogEntry {
  const PlaybackLogEntry(
    this.at,
    this.text, {
    this.isProblem = false,
    this.count = 1,
  });

  final Duration at;
  final String text;

  /// An error or a warning, shown in a stronger colour.
  final bool isProblem;

  final int count;

  String get line => '${_clock(at)}  $text${count > 1 ? '  x$count' : ''}';
}

class PlaybackLog extends ChangeNotifier {
  PlaybackLog({Stopwatch? clock, DateTime? startedAt})
    : _clock = clock ?? (Stopwatch()..start()),
      startedAt = startedAt ?? DateTime.now();

  final Stopwatch _clock;
  final DateTime startedAt;
  final _entries = <PlaybackLogEntry>[];
  var _dropped = 0;

  List<PlaybackLogEntry> get entries => UnmodifiableListView(_entries);

  PlaybackLogEntry? get latest => _entries.isEmpty ? null : _entries.last;

  bool get hasProblem => _entries.any((e) => e.isProblem);

  var _disposed = false;

  static const _notifyEvery = Duration(milliseconds: 200);
  Timer? _notifyTimer;
  var _notifyPending = false;

  void _changed() {
    if (_notifyTimer != null) {
      _notifyPending = true;
      return;
    }
    notifyListeners();
    _notifyTimer = Timer(_notifyEvery, () {
      _notifyTimer = null;
      if (_notifyPending && !_disposed) {
        _notifyPending = false;
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _notifyTimer?.cancel();
    super.dispose();
  }

  void add(String text, {bool problem = false, bool similar = false}) {
    if (_disposed) return;
    // The same line again, such as an engine repeating a warning.
    final last = _entries.isEmpty ? null : _entries.last;
    if (last != null &&
        (last.text == text || (similar && _alike(last.text, text)))) {
      _entries[_entries.length - 1] = PlaybackLogEntry(
        _clock.elapsed,
        last.text,
        isProblem: last.isProblem || problem,
        count: last.count + 1,
      );
      _changed();
      return;
    }
    if (_entries.length >= _maxEntries) {
      _entries.removeAt(0);
      _dropped++;
    }
    _entries.add(PlaybackLogEntry(_clock.elapsed, text, isProblem: problem));
    _changed();
  }

  String toText({String? heading}) {
    final out = StringBuffer()
      ..writeln('Sumizuri player log${heading == null ? '' : ' - $heading'}')
      ..writeln('Started ${startedAt.toIso8601String()}');
    if (_dropped > 0) out.writeln('($_dropped earlier lines were dropped)');
    for (final entry in _entries) {
      out.writeln(entry.line);
    }
    return out.toString();
  }
}

bool _alike(String a, String b) => _shape(a) == _shape(b);

String _shape(String text) =>
    text.replaceAll(RegExp(r'0x[0-9a-fA-F]+|\d+'), '#');

String describeVideo(MVideo video) {
  final headers = [
    for (final entry in video.headers.entries)
      _hiddenHeaders.contains(entry.key.toLowerCase())
          ? '${entry.key}: (hidden)'
          : '${entry.key}: ${entry.value}',
  ];
  final extras = [
    if (video.isPlaylist) 'playlist',
    if (video.subtitles.isNotEmpty) '${video.subtitles.length} subtitle(s)',
    if (video.audioTracks.isNotEmpty)
      '${video.audioTracks.length} audio track(s)',
  ];
  return '${video.quality ?? 'no label'}${extras.isEmpty ? '' : ' [${extras.join(', ')}]'}'
      '\n    ${video.url}'
      '${headers.isEmpty ? '' : '\n    headers: ${headers.join('; ')}'}';
}

String _clock(Duration at) {
  final seconds = at.inMilliseconds / 1000;
  return '+${seconds.toStringAsFixed(1).padLeft(6)}s';
}
