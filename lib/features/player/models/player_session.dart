import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import 'package:sumizuri/core/errors/result.dart';
import 'package:sumizuri/core/utils/files/episode_files.dart';
import 'package:sumizuri/features/extensions/data/extension_service.dart';
import 'package:sumizuri/features/extensions/models/m_chapter.dart';
import 'package:sumizuri/features/extensions/models/m_video.dart';
import 'package:sumizuri/features/library/data/library_repository.dart';
import 'package:sumizuri/features/player/models/hls_variants.dart';
import 'package:sumizuri/features/player/models/playback_progress.dart';
import 'package:sumizuri/features/player/models/player_errors.dart';
import 'package:sumizuri/features/player/models/player_log.dart';
import 'package:sumizuri/features/player/models/player_preferences.dart';

enum PlayerPhase { loading, ready, failed }

enum PlayerFailureKind {
  source,

  noVideos,

  /// A video was opened but never started.
  didNotStart,

  playback,

  network,
}

class PlayerFailure {
  const PlayerFailure(this.kind, [this.detail]);

  final PlayerFailureKind kind;

  final String? detail;
}

/// How far into an episode the viewer must be before it is written to History.
const _countsAsWatchingAfter = Duration(seconds: 20);

const _saveEvery = Duration(seconds: 5);

/// How long a video may take to report its length before it is treated as broken.
const _startTimeout = Duration(seconds: 30);

const _errorGrace = Duration(seconds: 4);

class PlayerSession extends ChangeNotifier {
  PlayerSession({
    required this.service,
    required this._episodes,
    required int startIndex,
    required this.libraryEntryId,
    required this.library,
    required this.isIncognito,
    required this.autoPlayNext,
    this._preferredQuality,
    this.onQualityChosen,
    this.preferences = const PlayerPreferences(),
  }) : _index = startIndex {
    _watch();
  }

  final ExtensionService service;
  final int? libraryEntryId;
  final LibraryRepository library;

  final bool Function() isIncognito;

  final bool Function() autoPlayNext;

  /// Told the quality the viewer picks, so it can be remembered for next time.
  final void Function(String quality)? onQualityChosen;

  final PlayerPreferences preferences;

  final List<MChapter> _episodes;
  int _index;

  final Player player = Player(
    configuration: const PlayerConfiguration(logLevel: MPVLogLevel.warn),
  );

  final PlaybackLog log = PlaybackLog();
  late final VideoController video = VideoController(player);

  PlayerPhase _phase = PlayerPhase.loading;
  PlayerFailure? _failure;
  List<MVideo> _videos = const [];
  MVideo? _current;
  String? _preferredQuality;

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  DateTime _lastSave = DateTime.fromMillisecondsSinceEpoch(0);
  bool _markedWatched = false;
  bool _sessionRecorded = false;
  bool _disposed = false;

  Completer<String>? _loadFailure;

  final _retries = RetryBudget();
  bool _recovering = false;

  int _generation = 0;

  final List<StreamSubscription<Object?>> _subscriptions = [];

  PlayerPhase get phase => _phase;
  PlayerFailure? get failure => _failure;
  List<MVideo> get videos => _videos;
  MVideo? get currentVideo => _current;
  MChapter get episode => _episodes[_index];
  bool get hasNext => _index < _episodes.length - 1;
  bool get hasPrevious => _index > 0;

  void _watch() {
    _subscriptions
      ..add(
        player.stream.position.listen((position) {
          _position = position;
          if (player.state.playing &&
              DateTime.now().difference(_lastSave) >= _saveEvery) {
            unawaited(_saveProgress());
          }
        }),
      )
      ..add(player.stream.duration.listen((duration) => _duration = duration))
      ..add(
        player.stream.playing.listen((playing) {
          if (!playing) unawaited(_saveProgress());
        }),
      )
      ..add(
        player.stream.completed.listen((done) {
          if (done) unawaited(_onCompleted());
        }),
      )
      ..add(
        player.stream.log.listen((entry) {
          final text = entry.text.trim();
          if (text.isEmpty) return;
          log.add(
            'engine [${entry.prefix}] $text',
            problem:
                (entry.level == 'error' || entry.level == 'fatal') &&
                !isHarmlessEngineNoise(text),
            similar: true,
          );
        }),
      )
      ..add(
        player.stream.buffering.listen((buffering) {
          if (_phase == PlayerPhase.ready) {
            log.add(buffering ? 'Buffering...' : 'Buffering done');
          }
        }),
      )
      ..add(
        player.stream.error.listen((message) {
          if (message.trim().isEmpty) return;
          log.add('Engine error: $message', problem: true);
          final loading = _loadFailure;
          if (_phase == PlayerPhase.loading &&
              loading != null &&
              !loading.isCompleted) {
            loading.complete(message);
          } else if (_phase == PlayerPhase.ready) {
            if (isDecodeGlitch(message) && !isNetworkError(message)) {
              unawaited(_checkAfterGlitch());
              return;
            }
            if (isNetworkError(message) &&
                !_recovering &&
                _retries.take(_position)) {
              log.add(
                'Connection dropped at ${formatPlaybackTime(_position)}: starting again from there',
                problem: true,
              );
              unawaited(_recover());
            } else {
              _fail(_failureFor(message));
            }
          }
        }),
      );
  }

  Future<void> start() async {
    await _configureNetwork();
    await _openEpisode(_index);
  }

  // A stalled connection is given up on after 20 seconds instead of a minute.
  Future<void> _configureNetwork() async {
    final platform = player.platform;
    if (platform is! NativePlayer) return;
    try {
      await platform.setProperty('demuxer-max-bytes', '50331648');
      await platform.setProperty('demuxer-max-back-bytes', '16777216');
      await platform.setProperty('network-timeout', '20');
      await platform.setProperty('cache-secs', '60');
      // No reconnect 1 here: HLS and DASH would reconnect at every segment end.
      await platform.setProperty(
        'stream-lavf-o',
        'reconnect_on_network_error=1,reconnect_on_http_error=429,'
            'reconnect_delay_max=8',
      );
    } catch (_) {
      // Playback works with the defaults, so a setting that is refused is not worth failing over.
    }
  }

  bool _checkingGlitch = false;

  Future<void> _checkAfterGlitch() async {
    if (_checkingGlitch) return;
    _checkingGlitch = true;
    final at = _position;
    final generation = _generation;
    try {
      await Future<void>.delayed(const Duration(seconds: 5));
      if (_stale(generation) || _phase != PlayerPhase.ready) return;
      final moved = _position > at || player.state.buffering;
      if (moved || !player.state.playing) return;
      if (_retries.take(_position)) {
        log.add(
          'Playback stopped after a damaged piece at ${formatPlaybackTime(_position)}: starting again from there',
          problem: true,
        );
        await _recover();
      } else {
        _fail(
          const PlayerFailure(
            PlayerFailureKind.playback,
            'The stream is damaged and playback stopped',
          ),
        );
      }
    } finally {
      _checkingGlitch = false;
    }
  }

  Future<void> _recover() async {
    final video = _current;
    if (video == null) return;
    _recovering = true;
    final generation = ++_generation;
    final at = _position;
    _setPhase(PlayerPhase.loading);
    try {
      await Future<void>.delayed(const Duration(seconds: 1));
      if (_stale(generation)) return;
      await _play(video, generation, startAt: at);
    } finally {
      _recovering = false;
    }
  }

  PlayerFailure _failureFor(String message) => PlayerFailure(
    isNetworkError(message)
        ? PlayerFailureKind.network
        : PlayerFailureKind.playback,
    message,
  );

  Future<void> nextEpisode() async {
    if (hasNext) await _openEpisode(_index + 1);
  }

  Future<void> previousEpisode() async {
    if (hasPrevious) await _openEpisode(_index - 1);
  }

  Future<void> selectVideo(MVideo choice) async {
    if (identical(choice, _current)) return;
    final quality = choice.quality;
    if (quality != null && quality.isNotEmpty) {
      _preferredQuality = quality;
      onQualityChosen?.call(quality);
    }
    final resumeAt = _position;
    final generation = ++_generation;
    log.add('Switching to ${choice.quality ?? 'another video'}');
    _setPhase(PlayerPhase.loading);
    await _play(choice, generation, startAt: resumeAt);
  }

  Future<void> tryAnotherVideo() async {
    final at = _current == null ? -1 : _videos.indexOf(_current!);
    final next = at + 1;
    if (next >= _videos.length) return;
    await selectVideo(_videos[next]);
  }

  bool get hasAnotherVideo {
    final at = _current == null ? -1 : _videos.indexOf(_current!);
    return at + 1 < _videos.length;
  }

  Future<void> retry() => _openEpisode(_index);

  Future<void> _openEpisode(int index) async {
    await _saveProgress();
    final generation = ++_generation;
    _index = index;
    _videos = const [];
    _current = null;
    _markedWatched = false;
    _sessionRecorded = false;
    _retries.reset();
    _position = Duration.zero;
    _duration = Duration.zero;
    _failure = null;
    _setPhase(PlayerPhase.loading);
    log.add(
      'Episode ${index + 1} of ${_episodes.length}: "${episode.title}"\n    ${episode.url}',
    );

    // A saved copy plays without asking the source, so it works offline.
    final local = await _localVideo();
    if (_stale(generation)) return;
    if (local != null) {
      log.add('Using the downloaded copy');
      _videos = [local];
      await _play(local, generation);
      return;
    }

    log.add('Asking ${service.info.name} for the videos...');
    final asked = Stopwatch()..start();
    final result = await service.getVideoList(episode);
    if (_stale(generation)) return;
    switch (result) {
      case Ok(:final value):
        log.add(
          'The source answered in ${asked.elapsedMilliseconds} ms with ${value.length} video(s)',
        );
        for (final video in value) {
          log.add('  ${describeVideo(video)}');
        }
        _videos = await _withQualities(value);
        if (_stale(generation)) return;
      case Err(:final error):
        log.add('The source failed: ${error.message}', problem: true);
        _fail(PlayerFailure(PlayerFailureKind.source, error.message));
        return;
    }
    final choice = pickVideo(
      _videos,
      preferredQuality: _preferredQuality,
      mode: preferences.qualityMode,
      audio: preferences.audioPreference,
    );
    if (choice != null) {
      log.add(
        'Chose ${choice.quality ?? 'the first video'} (${preferences.qualityMode.name}${preferences.audioPreference == AudioPreference.any ? '' : ', ${preferences.audioPreference.name} preferred'})',
      );
    }
    if (choice == null) {
      log.add('The source listed no videos for this episode', problem: true);
      _fail(const PlayerFailure(PlayerFailureKind.noVideos));
      return;
    }
    await _play(choice, generation);
  }

  Future<List<MVideo>> _withQualities(List<MVideo> videos) async {
    if (!videos.any((v) => v.isHls)) return videos;
    final client = http.Client();
    try {
      final started = Stopwatch()..start();
      final expanded = await expandHlsMasters(videos, client: client);
      if (expanded.length != videos.length) {
        log.add(
          'Read the playlist in ${started.elapsedMilliseconds} ms: ${expanded.map((v) => v.quality).join(', ')}',
        );
      }
      return expanded;
    } finally {
      client.close();
    }
  }

  Future<void> _play(MVideo choice, int generation, {Duration? startAt}) async {
    _current = choice;
    log.add(
      'Opening ${choice.quality ?? 'video'}${startAt == null ? '' : ' at ${formatPlaybackTime(startAt)}'}',
    );
    final opened = Stopwatch()..start();
    try {
      final lengthKnown =
          player.stream.duration
              .firstWhere((length) => length > Duration.zero)
              .timeout(_startTimeout)
            // If the load is dropped unawaited, a later timeout must not become an uncaught error.
            ..ignore();
      // Opened paused so the place can be restored before anything is heard.
      await player.open(
        Media(choice.url, httpHeaders: choice.headers),
        play: false,
      );
      if (_stale(generation)) return;
      final failed = Completer<String>();
      _loadFailure = failed;
      final failure = await Future.any<String?>([
        lengthKnown.then<String?>((_) => null),
        failed.future.then<String?>(
          (message) => Future<String?>.delayed(_errorGrace, () => message),
        ),
      ]);
      _loadFailure = null;
      if (_stale(generation)) return;
      if (failure != null) {
        log.add('The video did not open: $failure', problem: true);
        _fail(_failureFor(failure));
        return;
      }

      log.add(
        'Video opened in ${opened.elapsedMilliseconds} ms, ${formatPlaybackTime(player.state.duration)} long',
      );
      final at = startAt ?? await _savedPosition();
      if (_stale(generation)) return;
      if (at != null && at > Duration.zero) {
        log.add('Resuming at ${formatPlaybackTime(at)}');
        await player.seek(at);
      }
      final paired = choice.pairedAudio;
      if (paired != null) {
        await player.setAudioTrack(
          AudioTrack.uri(
            paired.url,
            title: paired.label,
            language: paired.language,
          ),
        );
        log.add('Sound: ${paired.label}');
      }
      await player.play();
      log.add('Playing');
      _setPhase(PlayerPhase.ready);
      if (startAt == null) {
        unawaited(_applyStartPreferences(choice, generation));
      }
    } on TimeoutException {
      if (!_stale(generation)) {
        log.add(
          'The video gave no length within ${_startTimeout.inSeconds} s, so it did not start',
          problem: true,
        );
        _fail(const PlayerFailure(PlayerFailureKind.didNotStart));
      }
    } catch (error) {
      if (!_stale(generation)) {
        log.add('Playback failed: $error', problem: true);
        _fail(PlayerFailure(PlayerFailureKind.playback, '$error'));
      }
    }
  }

  Future<void> _applyStartPreferences(MVideo video, int generation) async {
    try {
      if ((preferences.defaultSpeed - 1).abs() > 0.001 &&
          player.state.rate == 1.0) {
        await player.setRate(preferences.defaultSpeed);
        log.add('Speed ${preferences.defaultSpeed}x');
      }
      if (!preferences.subtitlesOn) {
        await player.setSubtitleTrack(SubtitleTrack.no());
        log.add('Subtitles off, as set');
        return;
      }
      for (var i = 0; i < 6 && video.subtitles.isEmpty; i++) {
        if (player.state.tracks.subtitle.any(
          (t) => t.id != 'auto' && t.id != 'no',
        )) {
          break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 500));
        if (_stale(generation)) return;
      }
      if (_stale(generation)) return;
      final choice = pickAlwaysOnSubtitle(
        embedded: [
          for (final t in player.state.tracks.subtitle)
            if (t.id != 'auto' && t.id != 'no') t,
        ],
        external: video.subtitles,
        language: preferences.subtitleLanguage,
      );
      if (choice == null) {
        log.add('This episode has no subtitles');
        return;
      }
      final track = choice.track;
      final subtitle = choice.subtitle;
      if (track != null) {
        await player.setSubtitleTrack(track);
        log.add('Subtitles: ${track.title ?? track.language ?? track.id}');
      } else if (subtitle != null) {
        await player.setSubtitleTrack(
          SubtitleTrack.uri(
            subtitle.url,
            title: subtitle.label,
            language: subtitle.language,
          ),
        );
        log.add('Subtitles: ${subtitle.label}');
      }
    } catch (error) {
      // Preferences are a nicety: failing to apply one never stops the episode.
      log.add('Could not apply a player setting: $error', problem: true);
    }
  }

  Future<MVideo?> _localVideo() async {
    final id = libraryEntryId;
    if (id == null) return null;
    final path = await library
        .watchChapterLocalPath(libraryEntryId: id, chapterUrl: episode.url)
        .first;
    return path == null ? null : localEpisodeVideo(path);
  }

  Future<Duration?> _savedPosition() async {
    final id = libraryEntryId;
    if (id == null) return null;
    final stored = await library.getChapterProgress(
      libraryEntryId: id,
      chapterUrl: episode.url,
    );
    return switch (stored) {
      Ok(:final value) => resumePosition(value, player.state.duration),
      Err() => null,
    };
  }

  Future<void> _saveProgress() async {
    final id = libraryEntryId;
    if (id == null || isIncognito() || _phase != PlayerPhase.ready) return;
    final fraction = progressFraction(_position, _duration);
    if (fraction == null) return;
    _lastSave = DateTime.now();
    final chapterUrl = episode.url;
    await library.updateChapterProgress(
      libraryEntryId: id,
      chapterUrl: chapterUrl,
      progressPosition: fraction,
    );
    if (!_sessionRecorded && _position >= _countsAsWatchingAfter) {
      _sessionRecorded = true;
      await library.recordChapterSession(
        libraryEntryId: id,
        chapterUrl: chapterUrl,
      );
    }
    if (isWatched(fraction) && !_markedWatched) {
      _markedWatched = true;
      // Finishing logs its own session, unless this sitting already logged one.
      if (_sessionRecorded) {
        await library.markChaptersConsumed(
          libraryEntryId: id,
          chapterUrls: [chapterUrl],
          consumed: true,
        );
      } else {
        _sessionRecorded = true;
        await library.markChapterConsumed(
          libraryEntryId: id,
          chapterUrl: chapterUrl,
        );
      }
    }
  }

  Future<void> _onCompleted() async {
    _position = _duration;
    log.add('Reached the end');
    await _saveProgress();
    if (autoPlayNext() && hasNext) {
      log.add('Starting the next episode');
      await nextEpisode();
    }
  }

  bool _stale(int generation) => _disposed || generation != _generation;

  void _fail(PlayerFailure failure) {
    _failure = failure;
    _setPhase(PlayerPhase.failed);
  }

  void _setPhase(PlayerPhase phase) {
    _phase = phase;
    if (!_disposed) notifyListeners();
  }

  @override
  Future<void> dispose() async {
    log.dispose();
    _generation++;
    try {
      await _saveProgress();
    } catch (_) {
      // Failing to save the place must not leave the engine and its memory running for good.
    }
    _disposed = true;
    try {
      for (final subscription in _subscriptions) {
        await subscription.cancel();
      }
    } finally {
      await player.dispose();
      super.dispose();
    }
  }
}
