import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/core/widgets/controls/app_choice.dart';
import 'package:sumizuri/features/settings/models/app_settings_types.dart';
import 'package:sumizuri/features/settings/providers/settings_providers.dart';
import 'package:sumizuri/features/settings/registry/settings_catalog.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

/// Whether lists show their rows as boxed cards or flat and dense.
class ListStyleChooser extends ConsumerWidget {
  const ListStyleChooser({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final style = ref.watch(listStyleProvider).value ?? AppListStyle.auto;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppChoice<AppListStyle>.map(
          options: {
            AppListStyle.auto: l10n.listStyleAuto,
            AppListStyle.cards: l10n.listStyleCards,
            AppListStyle.compact: l10n.listStyleCompact,
          },
          value: style,
          onChanged: (v) => ref
              .read(settingsRepositoryProvider)
              .putSetting(Settings.listStyle, v),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.listStyleHint,
          style: TextStyle(fontSize: 12, height: 1.4, color: cs.outline),
        ),
      ],
    );
  }
}
