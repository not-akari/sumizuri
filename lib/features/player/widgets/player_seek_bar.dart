import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';

import 'package:sumizuri/features/player/models/playback_progress.dart';

class PlayerSeekBar extends StatefulWidget {
  const PlayerSeekBar({
    super.key,
    required this.player,
    this.onScrubStart,
    this.onScrubEnd,
  });

  final Player player;

  /// Told when a drag starts and ends, so the controls do not hide under the viewer's finger.
  final VoidCallback? onScrubStart;
  final VoidCallback? onScrubEnd;

  @override
  State<PlayerSeekBar> createState() => _PlayerSeekBarState();
}

class _PlayerSeekBarState extends State<PlayerSeekBar> {
  double? _drag;

  @override
  Widget build(BuildContext context) {
    final player = widget.player;
    final cs = Theme.of(context).colorScheme;
    return StreamBuilder<Duration>(
      stream: player.stream.duration,
      initialData: player.state.duration,
      builder: (context, length) {
        final total = length.data ?? Duration.zero;
        return StreamBuilder<Duration>(
          stream: player.stream.position,
          initialData: player.state.position,
          builder: (context, position) {
            return StreamBuilder<Duration>(
              stream: player.stream.buffer,
              initialData: player.state.buffer,
              builder: (context, buffer) {
                final known = total > Duration.zero;
                double share(Duration? value) => known
                    ? ((value ?? Duration.zero).inMilliseconds /
                              total.inMilliseconds)
                          .clamp(0.0, 1.0)
                    : 0.0;
                final played = _drag ?? share(position.data);
                final shown = _drag == null
                    ? position.data ?? Duration.zero
                    : Duration(
                        milliseconds: (_drag! * total.inMilliseconds).round(),
                      );
                return SeekBarLayout(
                  elapsed: formatPlaybackTime(shown),
                  length: formatPlaybackTime(total),
                  slider: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3,
                      activeTrackColor: cs.primary,
                      inactiveTrackColor: Colors.white24,
                      secondaryActiveTrackColor: Colors.white38,
                      thumbColor: cs.primary,
                      overlayColor: cs.primary.withValues(alpha: 0.18),
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6,
                      ),
                    ),
                    child: Slider(
                      value: played,
                      secondaryTrackValue: share(buffer.data),
                      onChangeStart: known
                          ? (_) => widget.onScrubStart?.call()
                          : null,
                      onChanged: known
                          ? (value) => setState(() => _drag = value)
                          : null,
                      onChangeEnd: known
                          ? (value) {
                              player.seek(
                                Duration(
                                  milliseconds: (value * total.inMilliseconds)
                                      .round(),
                                ),
                              );
                              setState(() => _drag = null);
                              widget.onScrubEnd?.call();
                            }
                          : null,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

const seekBarHeight = 44.0;

class SeekBarLayout extends StatelessWidget {
  const SeekBarLayout({
    super.key,
    required this.elapsed,
    required this.length,
    required this.slider,
  });

  final String elapsed;
  final String length;
  final Widget slider;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: seekBarHeight,
    child: Row(
      children: [
        _Time(text: elapsed),
        Expanded(child: slider),
        _Time(text: length),
      ],
    ),
  );
}

class _Time extends StatelessWidget {
  const _Time({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 52,
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12.5,
        fontFeatures: [FontFeature.tabularFigures()],
      ),
    ),
  );
}
