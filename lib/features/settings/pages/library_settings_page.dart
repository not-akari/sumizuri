import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/core/widgets/cards/app_list_row.dart';
import 'package:sumizuri/features/library/providers/library_providers.dart';
import 'package:sumizuri/features/settings/pages/categories_settings_page.dart';
import 'package:sumizuri/features/settings/pages/library_update_settings_page.dart';
import 'package:sumizuri/features/settings/pages/missing_sources_page.dart';
import 'package:sumizuri/features/settings/widgets/library_mode_settings_body.dart';
import 'package:sumizuri/features/settings/widgets/media_types_settings_body.dart';
import 'package:sumizuri/features/settings/widgets/settings_scaffold.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

/// Everything about the library in one place: what it shows, how it is
/// organised, how it keeps itself up to date and what needs fixing.
class LibrarySettingsPage extends ConsumerWidget {
  const LibrarySettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final missing = ref
        .watch(entriesNeedingMigrationProvider)
        .values
        .fold<int>(0, (sum, entries) => sum + entries.length);
    void open(Widget page) =>
        Navigator.of(context)
            .push(MaterialPageRoute<void>(builder: (_) => page));

    return SettingsScaffold(
      title: Text(l10n.settingsSectionLibrary),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 96),
        children: [
          AppSectionLabel(label: l10n.settingsMediaTypesTile),
          const MediaTypesSettingsBody(),
          AppSectionLabel(label: l10n.settingsLibraryModeTile),
          const LibraryModeSettingsBody(),
          AppSectionLabel(label: l10n.libraryManageCategories),
          AppListRow(
            icon: Icons.label_outlined,
            title: l10n.libraryManageCategories,
            onTap: () => open(const CategoriesSettingsPage()),
          ),
          AppSectionLabel(label: l10n.libraryAutoUpdateTitle),
          AppListRow(
            icon: Icons.update_outlined,
            title: l10n.libraryAutoUpdateTitle,
            onTap: () => open(const LibraryUpdateSettingsPage()),
          ),
          if (missing > 0) ...[
            AppSectionLabel(label: l10n.missingSourcesTitle),
            AppListRow(
              icon: Icons.link_off,
              title: l10n.missingSourcesTitle,
              subtitle: l10n.missingSourcesSettingsSubtitle(missing),
              onTap: () => open(const MissingSourcesPage()),
            ),
          ],
        ],
      ),
    );
  }
}
