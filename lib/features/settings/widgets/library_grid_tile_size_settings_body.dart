import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/core/widgets/controls/app_choice.dart';
import 'package:sumizuri/core/widgets/controls/settings_controls.dart';
import 'package:sumizuri/features/settings/registry/settings_catalog.dart';
import 'package:sumizuri/features/settings/models/app_settings_types.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';
import 'package:sumizuri/features/settings/providers/settings_providers.dart';

String _labelFor(LibraryGridTileSize size, AppLocalizations l10n) =>
    switch (size) {
      LibraryGridTileSize.small => l10n.gridTileSizeSmall,
      LibraryGridTileSize.medium => l10n.gridTileSizeMedium,
      LibraryGridTileSize.large => l10n.gridTileSizeLarge,
    };

IconData _iconFor(LibraryGridTileSize size) => switch (size) {
  LibraryGridTileSize.small => Icons.grid_view_outlined,
  LibraryGridTileSize.medium => Icons.grid_on_outlined,
  LibraryGridTileSize.large => Icons.window_outlined,
};

class LibraryGridTileSizeSettingsBody extends ConsumerWidget {
  const LibraryGridTileSizeSettingsBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final size =
        ref.watch(libraryGridTileSizeProvider).value ??
        LibraryGridTileSize.medium;
    final repository = ref.read(settingsRepositoryProvider);

    final showUnread =
        ref.watch(boolSettingProvider(Settings.libraryShowUnreadBadge)).value ??
        true;
    final showDownloads =
        ref
            .watch(boolSettingProvider(Settings.libraryShowDownloadBadge))
            .value ??
        false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppChoice<LibraryGridTileSize>.of(
          style: AppChoiceStyle.pills,
          values: LibraryGridTileSize.values,
          label: (size) => _labelFor(size, l10n),
          icon: _iconFor,
          value: size,
          onChanged: repository.setLibraryGridTileSize,
        ),
        AppSwitchRow(
          icon: Icons.mark_chat_unread_outlined,
          title: l10n.libraryBadgeUnread,
          value: showUnread,
          onChanged: (on) =>
              repository.putSetting(Settings.libraryShowUnreadBadge, on),
        ),
        AppSwitchRow(
          icon: Icons.download_done_outlined,
          title: l10n.libraryBadgeDownloaded,
          value: showDownloads,
          onChanged: (on) =>
              repository.putSetting(Settings.libraryShowDownloadBadge, on),
        ),
      ],
    );
  }
}
