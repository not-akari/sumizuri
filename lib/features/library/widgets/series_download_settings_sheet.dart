import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/core/theming/app_layout.dart';
import 'package:sumizuri/core/widgets/overlays/app_sheet.dart';
import 'package:sumizuri/features/library/providers/library_providers.dart';
import 'package:sumizuri/features/library/models/series_overrides.dart';
import 'package:sumizuri/features/reader/providers/reader_providers.dart';
import 'package:sumizuri/features/settings/registry/setting_def.dart';
import 'package:sumizuri/features/settings/registry/settings_catalog.dart';
import 'package:sumizuri/features/settings/providers/settings_providers.dart';
import 'package:sumizuri/features/settings/widgets/auto_download_limits.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

/// The download limits of one series. What it does not set follows Settings > Downloads.
Future<void> showSeriesDownloadSettings(
  BuildContext context,
  int libraryEntryId,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _SeriesDownloadSettings(libraryEntryId: libraryEntryId),
  );
}

class _SeriesDownloadSettings extends ConsumerWidget {
  const _SeriesDownloadSettings({required this.libraryEntryId});

  final int libraryEntryId;

  static const _defs = <SettingDef<int>>[
    Settings.autoDownloadChapterLimit,
    Settings.keepDownloadsBehind,
    Settings.downloadAheadCount,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final overrides =
        ref.watch(entryOverridesProvider(libraryEntryId)).value ??
        const SeriesOverrides();
    final library = ref.read(libraryRepositoryProvider);

    int value(SettingDef<int> def, int? global) =>
        overrides.resolve(def, global ?? def.defaultValue);
    void save(SeriesOverrides next) =>
        library.updateEntryOverrides(entryId: libraryEntryId, overrides: next);

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSheetHeader(title: l10n.seriesDownloadSettingsTitle),
            Padding(
              padding: EdgeInsets.fromLTRB(
                context.layout.gutter,
                4,
                context.layout.gutter,
                0,
              ),
              child: Text(
                l10n.seriesDownloadSettingsHint,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ),
            AutoDownloadLimitsSection(
              autoLimit: value(
                Settings.autoDownloadChapterLimit,
                ref.watch(autoDownloadChapterLimitProvider).value,
              ),
              keepBehind: value(
                Settings.keepDownloadsBehind,
                ref.watch(keepDownloadsBehindProvider).value,
              ),
              downloadAhead: value(
                Settings.downloadAheadCount,
                ref
                    .watch(intSettingProvider(Settings.downloadAheadCount))
                    .value,
              ),
              onAutoLimitChanged: (v) =>
                  save(overrides.set(Settings.autoDownloadChapterLimit, v)),
              onKeepBehindChanged: (v) =>
                  save(overrides.set(Settings.keepDownloadsBehind, v)),
              onDownloadAheadChanged: (v) =>
                  save(overrides.set(Settings.downloadAheadCount, v)),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: EdgeInsets.fromLTRB(0, 8, context.layout.gutter, 16),
                child: TextButton(
                  onPressed: _defs.any(overrides.has)
                      ? () => save(overrides.without(_defs))
                      : null,
                  child: Text(l10n.seriesDownloadSettingsUseApp),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
