import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';

import 'package:sumizuri/features/extensions/models/m_video.dart';
import 'package:sumizuri/features/player/models/player_gestures.dart';
import 'package:sumizuri/features/player/models/player_markers.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

class PlayerSkipButton extends StatelessWidget {
  const PlayerSkipButton({
    super.key,
    required this.seconds,
    required this.onPressed,
  });

  final int seconds;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FilledButton.tonalIcon(
      onPressed: onPressed,
      icon: const Icon(Icons.fast_forward_rounded, size: 20),
      label: Text(l10n.playerSkip(seconds)),
      style: FilledButton.styleFrom(
        backgroundColor: Colors.black.withValues(alpha: 0.55),
        foregroundColor: Colors.white,
      ),
    );
  }
}

class PlayerMarkerButton extends StatelessWidget {
  const PlayerMarkerButton({
    super.key,
    required this.player,
    required this.intro,
    required this.outro,
    required this.onSkip,
  });

  final Player player;
  final MTimeRange? intro;
  final MTimeRange? outro;

  final void Function(ActiveMarker marker) onSkip;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return StreamBuilder<Duration>(
      stream: player.stream.position,
      initialData: player.state.position,
      builder: (context, position) {
        final marker = activeMarker(
          position: position.data ?? Duration.zero,
          intro: intro,
          outro: outro,
          length: player.state.duration,
        );
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: marker == null
              ? const SizedBox.shrink(key: ValueKey('no-marker'))
              : FilledButton.tonalIcon(
                  key: ValueKey(marker.kind),
                  onPressed: () => onSkip(marker),
                  icon: const Icon(Icons.fast_forward_rounded, size: 20),
                  label: Text(
                    marker.kind == MarkerKind.intro
                        ? l10n.playerSkipIntro
                        : l10n.playerSkipEnding,
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.black.withValues(alpha: 0.6),
                    foregroundColor: Colors.white,
                  ),
                ),
        );
      },
    );
  }
}

class PlayerUpNextButton extends StatelessWidget {
  const PlayerUpNextButton({
    super.key,
    required this.player,
    required this.hasNext,
    required this.onPressed,
  });

  final Player player;
  final bool hasNext;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return StreamBuilder<Duration>(
      stream: player.stream.position,
      initialData: player.state.position,
      builder: (context, position) {
        final show = showUpNext(
          hasNext: hasNext,
          position: position.data ?? Duration.zero,
          length: player.state.duration,
        );
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: show
              ? FilledButton.icon(
                  key: const ValueKey('up-next'),
                  onPressed: onPressed,
                  icon: const Icon(Icons.skip_next_rounded),
                  label: Text(l10n.playerUpNext),
                )
              : const SizedBox.shrink(key: ValueKey('no-up-next')),
        );
      },
    );
  }
}

class PlayerLockedOverlay extends StatelessWidget {
  const PlayerLockedOverlay({
    super.key,
    required this.hintVisible,
    required this.onTap,
    required this.onUnlock,
  });

  final bool hintVisible;
  final VoidCallback onTap;
  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTap),
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 24),
            child: AnimatedOpacity(
              opacity: hintVisible ? 1 : 0,
              duration: const Duration(milliseconds: 160),
              child: IgnorePointer(
                ignoring: !hintVisible,
                child: IconButton.filledTonal(
                  tooltip: l10n.playerUnlock,
                  onPressed: onUnlock,
                  icon: const Icon(Icons.lock_open_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withValues(alpha: 0.6),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
