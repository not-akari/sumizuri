import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/features/settings/providers/settings_providers.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

/// How strong the soft colour washes behind the app are.
class BackgroundLookPanel extends ConsumerWidget {
  const BackgroundLookPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final intensity = ref.watch(effectiveBackgroundIntensityProvider);
    final preview = ref.read(backgroundLookPreviewProvider.notifier);
    final repo = ref.read(settingsRepositoryProvider);
    final changed = (intensity - 1).abs() > 0.01;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 12, 0),
          child: Row(
            children: [
              SizedBox(
                width: 96,
                child: Text(
                  l10n.backgroundIntensity,
                  style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                ),
              ),
              Expanded(
                child: Slider(
                  value: intensity.clamp(
                    backgroundIntensityRange.min,
                    backgroundIntensityRange.max,
                  ),
                  min: backgroundIntensityRange.min,
                  max: backgroundIntensityRange.max,
                  onChanged: preview.setIntensity,
                  onChangeEnd: repo.setBackgroundIntensity,
                ),
              ),
              SizedBox(
                width: 52,
                child: Text(
                  '${(intensity * 100).round()}%',
                  textAlign: TextAlign.end,
                  style: TextStyle(fontSize: 13, color: cs.onSurface),
                ),
              ),
            ],
          ),
        ),
        if (changed)
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton(
                onPressed: () => repo.setBackgroundIntensity(1.0),
                child: Text(l10n.backgroundLookReset),
              ),
            ),
          ),
      ],
    );
  }
}
