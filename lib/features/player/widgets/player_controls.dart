import 'dart:async';
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:flutter_chrome_cast/entities.dart' show GoogleCastDevice;

import 'package:sumizuri/features/player/widgets/cast_overlay.dart';
import 'package:sumizuri/core/platform/local_media_server.dart';
import 'package:sumizuri/core/platform/cast_service.dart';
import 'package:sumizuri/core/platform/picture_in_picture.dart';
import 'package:sumizuri/features/player/models/player_gestures.dart';
import 'package:sumizuri/features/player/models/player_markers.dart';
import 'package:sumizuri/features/player/models/player_preferences.dart';
import 'package:sumizuri/features/player/models/player_session.dart';
import 'package:sumizuri/features/player/widgets/player_extra_controls.dart';
import 'package:sumizuri/features/player/widgets/player_gesture_layer.dart';
import 'package:sumizuri/features/player/widgets/player_log_panel.dart';
import 'package:sumizuri/features/player/widgets/player_pickers.dart';
import 'package:sumizuri/features/player/widgets/player_seek_bar.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

const _smallJump = Duration(seconds: 5);
const _fits = [BoxFit.contain, BoxFit.cover, BoxFit.fill];

bool get _isDesktop =>
    Platform.isWindows || Platform.isLinux || Platform.isMacOS;

class PlayerControls extends StatefulWidget {
  const PlayerControls({
    super.key,
    required this.session,
    required this.videoState,
    required this.onClose,
    this.preferences = const PlayerPreferences(),
  });

  final PlayerPreferences preferences;

  final PlayerSession session;

  final VideoState videoState;

  final VoidCallback onClose;

  @override
  State<PlayerControls> createState() => _PlayerControlsState();
}

class _PlayerControlsState extends State<PlayerControls> {
  final FocusNode _focus = FocusNode();
  Timer? _hideTimer;
  Timer? _flashTimer;
  bool _visible = true;
  bool _scrubbing = false;
  int _fit = 0;

  late bool _logShown = widget.preferences.showLog;

  Duration get _jump => Duration(seconds: widget.preferences.doubleTapSeconds);

  bool _locked = false;
  bool _unlockShown = false;
  Timer? _unlockTimer;

  IconData? _flashIcon;
  Alignment _flashAlign = Alignment.center;

  PlayerSession get _session => widget.session;

  @override
  void initState() {
    super.initState();
    _scheduleHide();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _flashTimer?.cancel();
    _unlockTimer?.cancel();
    _focus.dispose();
    unawaited(_castServer?.close());
    super.dispose();
  }

  LocalMediaServer? _castServer;

  String _contentTypeOf(String url) {
    final path = Uri.tryParse(url)?.path ?? url;
    if (path.endsWith('.webm')) return 'video/webm';
    if (path.endsWith('.ts')) return 'video/mp2t';
    if (path.endsWith('.mkv')) return 'video/x-matroska';
    return 'video/mp4';
  }

  Future<void> _startCasting(GoogleCastDevice device) async {
    final cast = CastService.instance;
    if (!await cast.connect(device)) return;
    final video = _session.currentVideo;
    if (video == null || !mounted) return;
    _session.player.pause();
    final contentType = _contentTypeOf(video.url);
    final isRemote =
        video.url.startsWith('http://') || video.url.startsWith('https://');
    String url;
    if (isRemote) {
      url = video.url;
    } else {
      final server = await LocalMediaServer.serve(
        File(video.url),
        contentType: contentType,
      );
      if (server == null || !mounted) return;
      unawaited(_castServer?.close());
      _castServer = server;
      url = server.url.toString();
    }
    if (!mounted) return;
    await cast.load(
      url: url,
      contentType: contentType,
      title: _session.episode.title,
    );
  }

  Future<void> _stopCasting() async {
    await CastService.instance.disconnect();
    await _castServer?.close();
    _castServer = null;
  }

  void _show() {
    if (!_visible) setState(() => _visible = true);
    _lift(true);
    _scheduleHide();
  }

  void _toggle() {
    if (_visible) {
      _hideTimer?.cancel();
      setState(() => _visible = false);
      _lift(false);
    } else {
      _show();
    }
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    final after = widget.preferences.hideControlsAfter;
    if (after == null) return;
    _hideTimer = Timer(after, () {
      if (!mounted || _scrubbing || !_session.player.state.playing) return;
      setState(() => _visible = false);
      _lift(false);
    });
  }

  // Subtitles sit higher while the bar is showing, so it never covers them.
  void _lift(bool controlsShown) => widget.videoState.setSubtitleViewPadding(
    widget.preferences.subtitlePadding(controlsShown: controlsShown),
  );

  void _flash(IconData icon, Alignment align) {
    _flashTimer?.cancel();
    setState(() {
      _flashIcon = icon;
      _flashAlign = align;
    });
    _flashTimer = Timer(const Duration(milliseconds: 550), () {
      if (mounted) setState(() => _flashIcon = null);
    });
  }

  void _seekBy(Duration delta) {
    final player = _session.player;
    player.seek(
      clampPosition(player.state.position + delta, player.state.duration),
    );
  }

  void _skip(bool forward) {
    _seekBy(forward ? _jump : -_jump);
    _flash(
      _jumpIcon(forward),
      forward ? Alignment.centerRight : Alignment.centerLeft,
    );
  }

  IconData _jumpIcon(bool forward) =>
      switch (widget.preferences.doubleTapSeconds) {
        5 => forward ? Icons.forward_5 : Icons.replay_5,
        10 => forward ? Icons.forward_10 : Icons.replay_10,
        30 => forward ? Icons.forward_30 : Icons.replay_30,
        _ => forward ? Icons.fast_forward_rounded : Icons.fast_rewind_rounded,
      };

  void _volumeBy(double delta) => _session.player.setVolume(
    (_session.player.state.volume + delta).clamp(0.0, 100.0),
  );

  void _cycleFit() {
    _fit = (_fit + 1) % _fits.length;
    widget.videoState.update(fit: _fits[_fit]);
    _show();
  }

  Future<void> _toggleFullscreen() async {
    await widget.videoState.toggleFullscreen();
    _show();
  }

  void _doubleTap(double share) {
    if (_isDesktop) {
      _toggleFullscreen();
    } else if (share < 0.4) {
      _skip(false);
    } else if (share > 0.6) {
      _skip(true);
    } else {
      _session.player.playOrPause();
    }
  }

  Map<ShortcutActivator, VoidCallback> _keys() => {
    const SingleActivator(LogicalKeyboardKey.space): _playPause,
    const SingleActivator(LogicalKeyboardKey.keyK): _playPause,
    const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
        _seekBy(-_smallJump),
    const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
        _seekBy(_smallJump),
    const SingleActivator(LogicalKeyboardKey.keyJ): () => _skip(false),
    const SingleActivator(LogicalKeyboardKey.keyL): () => _skip(true),
    const SingleActivator(LogicalKeyboardKey.arrowUp): () => _volumeBy(5),
    const SingleActivator(LogicalKeyboardKey.arrowDown): () => _volumeBy(-5),
    const SingleActivator(LogicalKeyboardKey.keyM): () =>
        _session.player.setVolume(_session.player.state.volume > 0 ? 0 : 100),
    const SingleActivator(LogicalKeyboardKey.keyF): _toggleFullscreen,
    const SingleActivator(LogicalKeyboardKey.keyN): () {
      if (_session.hasNext) _session.nextEpisode();
    },
    const SingleActivator(LogicalKeyboardKey.keyP): () {
      if (_session.hasPrevious) _session.previousEpisode();
    },
    const SingleActivator(LogicalKeyboardKey.escape): () {
      if (widget.videoState.isFullscreen()) {
        widget.videoState.exitFullscreen();
      } else {
        widget.onClose();
      }
    },
  };

  void _playPause() {
    _session.player.playOrPause();
    _show();
  }

  void _lock() {
    _hideTimer?.cancel();
    setState(() {
      _locked = true;
      _visible = false;
      _unlockShown = false;
    });
    _lift(false);
  }

  void _unlock() {
    _unlockTimer?.cancel();
    setState(() {
      _locked = false;
      _unlockShown = false;
    });
    _show();
  }

  void _showUnlock() {
    _unlockTimer?.cancel();
    setState(() => _unlockShown = true);
    _unlockTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _unlockShown = false);
    });
  }

  void _skipMarker(ActiveMarker marker) {
    if (marker.endsEpisode && _session.hasNext) {
      _session.nextEpisode();
    } else {
      _session.player.seek(marker.skipTo);
      _flash(Icons.fast_forward_rounded, Alignment.center);
    }
    _show();
  }

  void _skipAhead() {
    _seekBy(Duration(seconds: widget.preferences.skipSeconds));
    _flash(Icons.fast_forward_rounded, Alignment.center);
    _show();
  }

  @override
  Widget build(BuildContext context) {
    // In the small window the controls would only cover the picture.
    return ValueListenableBuilder<bool>(
      valueListenable: PictureInPicture.instance.active,
      builder: (context, inPip, _) => inPip
          ? const SizedBox.shrink()
          : Stack(
              children: [
                _controls(context),
                if (CastService.instance.supported)
                  ValueListenableBuilder<CastPlaybackState?>(
                    valueListenable: CastService.instance.state,
                    builder: (context, cast, _) => cast == null
                        ? const SizedBox.shrink()
                        : Positioned.fill(
                            child: CastOverlay(
                              state: cast,
                              onStop: () => unawaited(_stopCasting()),
                            ),
                          ),
                  ),
              ],
            ),
    );
  }

  Widget _controls(BuildContext context) {
    return ListenableBuilder(
      listenable: _session,
      builder: (context, _) {
        final failed = _session.phase == PlayerPhase.failed;
        return CallbackShortcuts(
          bindings: _keys(),
          child: Focus(
            focusNode: _focus,
            autofocus: true,
            child: MouseRegion(
              cursor: _visible || failed
                  ? SystemMouseCursors.basic
                  : SystemMouseCursors.none,
              onHover: (_) => _show(),
              child: Listener(
                onPointerSignal: (event) {
                  if (event is PointerScrollEvent) {
                    _volumeBy(event.scrollDelta.dy < 0 ? 5 : -5);
                  }
                },
                child: _locked && !failed
                    ? PlayerLockedOverlay(
                        hintVisible: _unlockShown,
                        onTap: _showUnlock,
                        onUnlock: _unlock,
                      )
                    : Stack(
                        fit: StackFit.expand,
                        children: [
                          _gestures(),
                          if (_flashIcon != null) _flashHint(),
                          if (failed)
                            _FailureView(
                              session: _session,
                              onClose: widget.onClose,
                            )
                          else
                            AnimatedOpacity(
                              opacity: _visible ? 1 : 0,
                              duration: const Duration(milliseconds: 180),
                              child: IgnorePointer(
                                ignoring: !_visible,
                                child: _overlay(context),
                              ),
                            ),
                          if (_logShown && (failed || _visible)) _log(),
                          if (!failed) _markers(),
                          if (!failed) _upNext(),
                          if (_session.phase == PlayerPhase.loading)
                            const Center(child: CircularProgressIndicator())
                          else if (!failed)
                            _bufferingSpinner(),
                        ],
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _log() => Positioned(
    left: 12,
    right: 12,
    top: 0,
    child: SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.only(top: 56),
        child: PlayerLogPanel(
          log: _session.log,
          heading: _session.episode.title,
          startOpen: false,
        ),
      ),
    ),
  );

  Widget _gestures() => PlayerGestureLayer(
    player: _session.player,
    touch: !_isDesktop && widget.preferences.swipeGestures,
    holdSpeed: widget.preferences.holdSpeed,
    onTap: _toggle,
    onDoubleTap: _doubleTap,
  );

  Widget _markers() {
    final video = _session.currentVideo;
    if (video == null || (video.intro == null && video.outro == null)) {
      return const SizedBox.shrink();
    }
    return Positioned(
      left: 20,
      bottom: 76,
      child: PlayerMarkerButton(
        player: _session.player,
        intro: video.intro,
        outro: video.outro,
        onSkip: _skipMarker,
      ),
    );
  }

  Widget _upNext() => Positioned(
    right: 20,
    bottom: 76,
    child: PlayerUpNextButton(
      player: _session.player,
      hasNext: _session.hasNext,
      onPressed: _session.nextEpisode,
    ),
  );

  Widget _bufferingSpinner() => IgnorePointer(
    child: Center(
      child: StreamBuilder<bool>(
        stream: _session.player.stream.buffering,
        initialData: _session.player.state.buffering,
        builder: (context, buffering) => (buffering.data ?? false)
            ? const CircularProgressIndicator()
            : const SizedBox.shrink(),
      ),
    ),
  );

  Widget _flashHint() => IgnorePointer(
    child: Align(
      alignment: _flashAlign,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: Icon(_flashIcon, size: 56, color: Colors.white),
      ),
    ),
  );

  Widget _overlay(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final player = _session.player;
    return Stack(
      fit: StackFit.expand,
      children: [
        _scrim(top: true),
        _scrim(top: false),
        Align(alignment: Alignment.topCenter, child: _topBar(context, l10n)),
        Center(child: _transport(l10n)),
        if (_session.currentVideo?.intro == null)
          Positioned(
            left: 20,
            bottom: 76,
            child: PlayerSkipButton(
              seconds: widget.preferences.skipSeconds,
              onPressed: _skipAhead,
            ),
          ),
        Align(
          alignment: Alignment.bottomCenter,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: PlayerSeekBar(
                player: player,
                onScrubStart: () {
                  _scrubbing = true;
                  _hideTimer?.cancel();
                },
                onScrubEnd: () {
                  _scrubbing = false;
                  _scheduleHide();
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _scrim({required bool top}) => IgnorePointer(
    child: Align(
      alignment: top ? Alignment.topCenter : Alignment.bottomCenter,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: top ? Alignment.topCenter : Alignment.bottomCenter,
            end: top ? Alignment.bottomCenter : Alignment.topCenter,
            colors: const [Colors.black87, Colors.transparent],
          ),
        ),
      ),
    ),
  );

  Widget _topBar(BuildContext context, AppLocalizations l10n) {
    final player = _session.player;
    final video = _session.currentVideo;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
        child: Row(
          children: [
            _IconAction(
              icon: Icons.arrow_back,
              tooltip: l10n.playerClose,
              onPressed: widget.onClose,
            ),
            Expanded(
              child: Text(
                _session.episode.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            _IconAction(
              icon: Icons.terminal,
              tooltip: _logShown ? l10n.playerLogHide : l10n.playerLogShow,
              onPressed: () => setState(() => _logShown = !_logShown),
            ),
            if (_session.videos.length > 1)
              _IconAction(
                icon: Icons.high_quality_outlined,
                tooltip: l10n.playerQuality,
                onPressed: () => showQualityPicker(context, _session),
              ),
            if (hasSubtitleChoices(player, video))
              _IconAction(
                icon: Icons.subtitles_outlined,
                tooltip: l10n.playerSubtitles,
                onPressed: () => showSubtitlePicker(context, player, video),
              ),
            if (hasAudioChoices(player, video))
              _IconAction(
                icon: Icons.audiotrack_outlined,
                tooltip: l10n.playerAudio,
                onPressed: () => showAudioPicker(context, player, video),
              ),
            if (PictureInPicture.instance.supported)
              _IconAction(
                icon: Icons.picture_in_picture_alt_outlined,
                tooltip: l10n.playerPictureInPicture,
                onPressed: () => unawaited(PictureInPicture.instance.enter()),
              ),
            if (CastService.instance.supported)
              ValueListenableBuilder<CastPlaybackState?>(
                valueListenable: CastService.instance.state,
                builder: (context, cast, _) => _IconAction(
                  icon: cast == null ? Icons.cast : Icons.cast_connected,
                  tooltip: l10n.playerCast,
                  onPressed: cast == null
                      ? () => showCastDevicePicker(
                          context,
                          onSelected: _startCasting,
                        )
                      : () => unawaited(_stopCasting()),
                ),
              ),
            StreamBuilder<double>(
              stream: player.stream.rate,
              initialData: player.state.rate,
              builder: (context, rate) => TextButton(
                onPressed: () => showSpeedPicker(context, player),
                child: Text(
                  formatSpeed(rate.data ?? 1),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
            _IconAction(
              icon: Icons.aspect_ratio,
              tooltip: l10n.playerFitScreen,
              onPressed: _cycleFit,
            ),
            if (!_isDesktop)
              _IconAction(
                icon: Icons.lock_outline_rounded,
                tooltip: l10n.playerLock,
                onPressed: _lock,
              ),
            if (_isDesktop)
              _IconAction(
                icon: widget.videoState.isFullscreen()
                    ? Icons.fullscreen_exit
                    : Icons.fullscreen,
                tooltip: widget.videoState.isFullscreen()
                    ? l10n.playerExitFullscreen
                    : l10n.playerFullscreen,
                onPressed: _toggleFullscreen,
              ),
          ],
        ),
      ),
    );
  }

  Widget _transport(AppLocalizations l10n) {
    final player = _session.player;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _IconAction(
          icon: Icons.skip_previous,
          size: 36,
          tooltip: l10n.playerPreviousEpisode,
          onPressed: _session.hasPrevious ? _session.previousEpisode : null,
        ),
        const SizedBox(width: 20),
        StreamBuilder<bool>(
          stream: player.stream.playing,
          initialData: player.state.playing,
          builder: (context, playing) => _IconAction(
            icon: (playing.data ?? false) ? Icons.pause : Icons.play_arrow,
            size: 56,
            onPressed: _playPause,
          ),
        ),
        const SizedBox(width: 20),
        _IconAction(
          icon: Icons.skip_next,
          size: 36,
          tooltip: l10n.playerNextEpisode,
          onPressed: _session.hasNext ? _session.nextEpisode : null,
        ),
      ],
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.size = 26,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double size;

  @override
  Widget build(BuildContext context) => IconButton(
    icon: Icon(icon, size: size),
    color: Colors.white,
    disabledColor: Colors.white30,
    tooltip: tooltip,
    onPressed: onPressed,
  );
}

class _FailureView extends StatelessWidget {
  const _FailureView({required this.session, required this.onClose});

  final PlayerSession session;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final failure = session.failure;
    final reason = switch (failure?.kind) {
      PlayerFailureKind.source => l10n.playerFailureSource,
      PlayerFailureKind.noVideos => l10n.playerFailureNoVideos,
      PlayerFailureKind.didNotStart => l10n.playerFailureDidNotStart,
      PlayerFailureKind.network => l10n.playerFailureNetwork,
      _ => l10n.playerFailurePlayback,
    };
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(24),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 44,
                  color: Colors.white70,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.playerFailedTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  reason,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
                if (failure?.detail case final detail?) ...[
                  const SizedBox(height: 10),
                  SelectableText(
                    detail,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 24),
                if (session.hasAnotherVideo)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: session.tryAnotherVideo,
                      child: Text(l10n.playerTryAnother),
                    ),
                  ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: session.retry,
                    child: Text(l10n.playerRetry),
                  ),
                ),
                TextButton(onPressed: onClose, child: Text(l10n.playerClose)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
