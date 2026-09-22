import 'dart:async';

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';

import 'package:sumizuri/features/player/models/player_gestures.dart';
import 'package:sumizuri/features/player/models/playback_progress.dart';

class _Hud {
  const _Hud(this.icon, this.text);

  final IconData icon;
  final String text;
}

class PlayerGestureLayer extends StatefulWidget {
  const PlayerGestureLayer({
    super.key,
    required this.player,
    required this.touch,
    required this.onTap,
    required this.onDoubleTap,
    this.holdSpeed = 2.0,
  });

  final double holdSpeed;

  final Player player;

  final bool touch;

  final VoidCallback onTap;

  final ValueChanged<double> onDoubleTap;

  @override
  State<PlayerGestureLayer> createState() => _PlayerGestureLayerState();
}

class _PlayerGestureLayerState extends State<PlayerGestureLayer> {
  Timer? _hudTimer;
  _Hud? _hud;

  double _doubleTapShare = 0.5;

  Duration _seekFrom = Duration.zero;
  Duration _seekTarget = Duration.zero;
  double _seekDx = 0;

  double? _volumeFrom;
  double _volumeDy = 0;

  double _rateBefore = 1;

  Player get _player => widget.player;

  @override
  void dispose() {
    _hudTimer?.cancel();
    super.dispose();
  }

  void _showHud(_Hud hud, {bool keep = false}) {
    _hudTimer?.cancel();
    setState(() => _hud = hud);
    if (!keep) {
      _hudTimer = Timer(const Duration(milliseconds: 650), () {
        if (mounted) setState(() => _hud = null);
      });
    }
  }

  void _hideHudSoon() {
    _hudTimer?.cancel();
    _hudTimer = Timer(const Duration(milliseconds: 450), () {
      if (mounted) setState(() => _hud = null);
    });
  }

  void _seekStart() {
    _seekFrom = _player.state.position;
    _seekTarget = _seekFrom;
    _seekDx = 0;
  }

  void _seekUpdate(DragUpdateDetails details, double width) {
    _seekDx += details.delta.dx;
    _seekTarget = clampPosition(
      _seekFrom + dragSeekDelta(_seekDx, width),
      _player.state.duration,
    );
    _showHud(
      _Hud(
        _seekDx >= 0 ? Icons.fast_forward_rounded : Icons.fast_rewind_rounded,
        '${formatPlaybackTime(_seekTarget)}   ${seekHint(_seekTarget, _seekFrom)}',
      ),
      keep: true,
    );
  }

  void _seekEnd() {
    _player.seek(_seekTarget);
    _hideHudSoon();
  }

  void _volumeStart(DragStartDetails details, double width) {
    _volumeFrom = details.localPosition.dx > width / 2
        ? _player.state.volume
        : null;
    _volumeDy = 0;
  }

  void _volumeUpdate(DragUpdateDetails details, double height) {
    final from = _volumeFrom;
    if (from == null) return;
    _volumeDy += details.delta.dy;
    final volume = dragVolume(from, _volumeDy, height);
    _player.setVolume(volume);
    _showHud(
      _Hud(
        volume <= 0
            ? Icons.volume_off_rounded
            : volume < 50
            ? Icons.volume_down_rounded
            : Icons.volume_up_rounded,
        '${volume.round()}%',
      ),
      keep: true,
    );
  }

  void _holdStart() {
    _rateBefore = _player.state.rate;
    _player.setRate(widget.holdSpeed);
    _showHud(
      _Hud(Icons.fast_forward_rounded, '${_speedLabel(widget.holdSpeed)}×'),
      keep: true,
    );
  }

  void _holdEnd() {
    _player.setRate(_rateBefore);
    _hideHudSoon();
  }

  @override
  Widget build(BuildContext context) {
    final touch = widget.touch;
    return LayoutBuilder(
      builder: (context, box) {
        final size = box.biggest;
        return Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onTap,
              onDoubleTapDown: (details) {
                _doubleTapShare = size.width <= 0
                    ? 0.5
                    : details.localPosition.dx / size.width;
                widget.onDoubleTap(_doubleTapShare);
              },
              onDoubleTap: () {},
              onHorizontalDragStart: touch ? (_) => _seekStart() : null,
              onHorizontalDragUpdate: touch
                  ? (details) => _seekUpdate(details, size.width)
                  : null,
              onHorizontalDragEnd: touch ? (_) => _seekEnd() : null,
              onVerticalDragStart: touch
                  ? (details) => _volumeStart(details, size.width)
                  : null,
              onVerticalDragUpdate: touch
                  ? (details) => _volumeUpdate(details, size.height)
                  : null,
              onVerticalDragEnd: touch ? (_) => _hideHudSoon() : null,
              onLongPressStart: touch ? (_) => _holdStart() : null,
              onLongPressEnd: touch ? (_) => _holdEnd() : null,
            ),
            if (_hud != null)
              IgnorePointer(
                child: Center(child: _HudPill(hud: _hud!)),
              ),
          ],
        );
      },
    );
  }
}

String _speedLabel(double speed) => speed == speed.roundToDouble()
    ? speed.toInt().toString()
    : speed.toStringAsFixed(1);

class _HudPill extends StatelessWidget {
  const _HudPill({required this.hud});

  final _Hud hud;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(28),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(hud.icon, color: Colors.white, size: 28),
          const SizedBox(width: 10),
          Text(
            hud.text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    ),
  );
}
