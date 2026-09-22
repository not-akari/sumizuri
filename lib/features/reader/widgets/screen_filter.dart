import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/features/settings/registry/setting_def.dart';
import 'package:sumizuri/core/widgets/controls/settings_controls.dart';
import 'package:sumizuri/features/settings/providers/settings_providers.dart';
import 'package:sumizuri/features/settings/registry/settings_catalog.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

// The most the screen can be dimmed, so it never goes black by accident.
const maxScreenDim = 70;

/// A dark and a warm layer over the reader for night reading. Touches pass through.
class ScreenFilterOverlay extends ConsumerWidget {
  const ScreenFilterOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dim =
        ref.watch(intSettingProvider(Settings.readerScreenDim)).value ?? 0;
    final warmth =
        ref.watch(intSettingProvider(Settings.readerScreenWarmth)).value ?? 0;
    if (dim <= 0 && warmth <= 0) return const SizedBox.shrink();
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (warmth > 0)
            ColoredBox(
              color: const Color(0xFFFF9329)
                  .withValues(alpha: warmth / 100 * 0.35),
            ),
          if (dim > 0)
            ColoredBox(
              color: Colors.black.withValues(
                alpha: dim.clamp(0, maxScreenDim) / 100,
              ),
            ),
        ],
      ),
    );
  }
}

/// The two sliders that set the screen filter. A value is kept when the slider is let go.
class ScreenFilterSliders extends ConsumerStatefulWidget {
  const ScreenFilterSliders({super.key});

  @override
  ConsumerState<ScreenFilterSliders> createState() =>
      _ScreenFilterSlidersState();
}

class _ScreenFilterSlidersState extends ConsumerState<ScreenFilterSliders> {
  // What is being dragged, before it is saved.
  final _dragging = <SettingDef<int>, double>{};

  Widget _slider(SettingDef<int> def, String title, int max, int saved) {
    final value = (_dragging[def] ?? saved.toDouble()).clamp(0, max).toDouble();
    return AppLabelled(
      title: '$title  ${value.round()}%',
      child: Slider(
        value: value,
        max: max.toDouble(),
        divisions: max ~/ 5,
        onChanged: (v) => setState(() => _dragging[def] = v),
        onChangeEnd: (v) async {
          await ref.read(settingsRepositoryProvider).putSetting(def, v.round());
          if (mounted) setState(() => _dragging.remove(def));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dim =
        ref.watch(intSettingProvider(Settings.readerScreenDim)).value ?? 0;
    final warmth =
        ref.watch(intSettingProvider(Settings.readerScreenWarmth)).value ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _slider(
          Settings.readerScreenDim,
          l10n.readerScreenDim,
          maxScreenDim,
          dim,
        ),
        _slider(
          Settings.readerScreenWarmth,
          l10n.readerScreenWarmth,
          100,
          warmth,
        ),
      ],
    );
  }
}
