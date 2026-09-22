import 'package:flutter/material.dart';

import 'package:sumizuri/core/platform/cast_service.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

/// Shown while an episode is casting: who it is going to, and controls sent to the device.
class CastOverlay extends StatelessWidget {
  const CastOverlay({super.key, required this.state, required this.onStop});

  final CastPlaybackState state;
  final VoidCallback onStop;

  String _time(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return d.inHours > 0
        ? '${d.inHours}:$minutes:$seconds'
        : '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final duration = state.duration;
    return ColoredBox(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cast_connected, color: Colors.white, size: 40),
            const SizedBox(height: 12),
            Text(
              l10n.playerCastingTo(state.deviceName),
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              duration == null
                  ? _time(state.position)
                  : '${_time(state.position)} / ${_time(duration)}',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    state.playing
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_fill,
                    color: Colors.white,
                    size: 44,
                  ),
                  onPressed: () => state.playing
                      ? CastService.instance.pause()
                      : CastService.instance.play(),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: onStop,
                  icon: const Icon(Icons.close, color: Colors.white70),
                  label: Text(
                    l10n.playerCastStop,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
