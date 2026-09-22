import 'package:flutter/material.dart';

import 'package:sumizuri/core/widgets/ambient/ambient_scaffold.dart';
import 'package:sumizuri/core/widgets/cards/app_list_row.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';
import 'package:sumizuri/features/settings/widgets/library_mode_settings_body.dart';
import 'package:sumizuri/features/settings/widgets/media_types_settings_body.dart';

class LibrarySettingsPage extends StatelessWidget {
  const LibrarySettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AmbientScaffold(
      maxContentWidth: 720,
      title: Text(l10n.settingsSectionLibrary),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 96),
        children: [
          AppSectionLabel(label: l10n.settingsMediaTypesTile),
          const MediaTypesSettingsBody(),
          AppSectionLabel(label: l10n.settingsLibraryModeTile),
          const LibraryModeSettingsBody(),
        ],
      ),
    );
  }
}
