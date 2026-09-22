import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/core/widgets/controls/settings_controls.dart';
import 'package:sumizuri/features/settings/models/app_settings_types.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';
import 'package:sumizuri/features/settings/providers/settings_providers.dart';

class LibraryModeSettingsBody extends ConsumerWidget {
  const LibraryModeSettingsBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(libraryModeProvider).value ?? AppLibraryMode.unified;
    final l10n = AppLocalizations.of(context)!;
    final repository = ref.read(settingsRepositoryProvider);

    return Column(
      children: [
        AppOptionRow(
          icon: Icons.collections_bookmark_outlined,
          title: l10n.libraryModeUnifiedTitle,
          subtitle: l10n.libraryModeUnifiedSubtitle,
          selected: mode == AppLibraryMode.unified,
          onTap: () => repository.setLibraryMode(AppLibraryMode.unified),
        ),
        AppOptionRow(
          icon: Icons.view_agenda_outlined,
          title: l10n.libraryModeSplitTitle,
          subtitle: l10n.libraryModeSplitSubtitle,
          selected: mode == AppLibraryMode.splitByType,
          onTap: () => repository.setLibraryMode(AppLibraryMode.splitByType),
        ),
      ],
    );
  }
}
