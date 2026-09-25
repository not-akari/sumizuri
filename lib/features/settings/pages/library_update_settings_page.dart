import 'dart:io';

import 'package:sumizuri/features/settings/widgets/settings_scaffold.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/core/widgets/controls/app_choice.dart';
import 'package:sumizuri/core/theming/app_layout.dart';
import 'package:sumizuri/core/widgets/cards/app_list_row.dart';
import 'package:sumizuri/core/widgets/controls/settings_controls.dart';
import 'package:sumizuri/features/library/models/library_update_rules.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';
import 'package:sumizuri/features/settings/providers/settings_providers.dart';

const _intervalChoicesHours = [0, 1, 3, 6, 12, 24];

class LibraryUpdateSettingsPage extends ConsumerWidget {
  const LibraryUpdateSettingsPage({super.key});

  String _intervalLabel(AppLocalizations l10n, int hours) => switch (hours) {
    0 => l10n.libraryAutoUpdateIntervalNever,
    1 => l10n.libraryAutoUpdateInterval1h,
    3 => l10n.libraryAutoUpdateInterval3h,
    6 => l10n.libraryAutoUpdateInterval6h,
    12 => l10n.libraryAutoUpdateInterval12h,
    _ => l10n.libraryAutoUpdateInterval24h,
  };

  IconData _intervalIcon(int hours) =>
      hours == 0 ? Icons.notifications_off_outlined : Icons.schedule;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final repo = ref.read(settingsRepositoryProvider);
    final intervalHours =
        ref.watch(autoLibraryUpdateIntervalHoursProvider).value ?? 0;
    final updateWifiOnly =
        ref.watch(autoLibraryUpdateWifiOnlyProvider).value ?? true;
    final skipMask = ref.watch(libraryUpdateSkipProvider).value ?? 0;

    return SettingsScaffold(
      title: Text(l10n.libraryAutoUpdateTitle),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 96),
        children: [
          AppSectionLabel(label: l10n.libraryAutoUpdateIntervalLabel),
          AppChoice<int>.of(
            padded: true,
            style: AppChoiceStyle.pills,
            values: _intervalChoicesHours,
            label: (hours) => _intervalLabel(l10n, hours),
            icon: _intervalIcon,
            value: intervalHours,
            onChanged: repo.setAutoLibraryUpdateIntervalHours,
          ),
          if (!kIsWeb && (Platform.isAndroid || Platform.isIOS))
            Padding(
              padding: EdgeInsets.fromLTRB(
                context.layout.gutter,
                4,
                context.layout.gutter,
                0,
              ),
              child: Text(
                l10n.libraryAutoUpdateBackgroundHint,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          AppSwitchRow(
            icon: Icons.wifi_find_outlined,
            title: l10n.libraryAutoUpdateWifiOnly,
            subtitle: l10n.libraryAutoUpdateWifiOnlyHint,
            value: updateWifiOnly,
            onChanged: repo.setAutoLibraryUpdateWifiOnly,
          ),
          for (final rule in [
            (
              LibraryUpdateSkip.completed,
              Icons.check_circle_outline,
              l10n.libraryUpdateSkipCompleted,
              l10n.libraryUpdateSkipCompletedHint,
            ),
            (
              LibraryUpdateSkip.unread,
              Icons.mark_email_unread_outlined,
              l10n.libraryUpdateSkipUnread,
              l10n.libraryUpdateSkipUnreadHint,
            ),
            (
              LibraryUpdateSkip.notStarted,
              Icons.hourglass_empty,
              l10n.libraryUpdateSkipNotStarted,
              l10n.libraryUpdateSkipNotStartedHint,
            ),
          ])
            AppSwitchRow(
              icon: rule.$2,
              title: rule.$3,
              subtitle: rule.$4,
              value: LibraryUpdateSkip.has(skipMask, rule.$1),
              onChanged: (on) => repo.setLibraryUpdateSkip(
                LibraryUpdateSkip.toggled(skipMask, rule.$1, on),
              ),
            ),
        ],
      ),
    );
  }
}
