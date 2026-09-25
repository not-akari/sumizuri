import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/core/widgets/cards/app_list_row.dart';
import 'package:sumizuri/core/widgets/controls/app_choice.dart';
import 'package:sumizuri/core/widgets/controls/pick_row.dart';
import 'package:sumizuri/core/widgets/controls/settings_controls.dart';
import 'package:sumizuri/features/settings/registry/setting_def.dart';
import 'package:sumizuri/features/settings/registry/settings_catalog.dart';
import 'package:sumizuri/features/settings/models/app_settings_types.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';
import 'package:sumizuri/features/settings/providers/settings_providers.dart';

String gridTileSizeLabel(LibraryGridTileSize size, AppLocalizations l10n) =>
    switch (size) {
      LibraryGridTileSize.small => l10n.gridTileSizeSmall,
      LibraryGridTileSize.medium => l10n.gridTileSizeMedium,
      LibraryGridTileSize.large => l10n.gridTileSizeLarge,
    };

IconData gridTileSizeIcon(LibraryGridTileSize size) => switch (size) {
  LibraryGridTileSize.small => Icons.grid_view_outlined,
  LibraryGridTileSize.medium => Icons.grid_on_outlined,
  LibraryGridTileSize.large => Icons.window_outlined,
};

String libraryDisplayStyleLabel(
  LibraryDisplayStyle style,
  AppLocalizations l10n,
) => switch (style) {
  LibraryDisplayStyle.comfortableGrid => l10n.libraryDisplayComfortableGrid,
  LibraryDisplayStyle.compactGrid => l10n.libraryDisplayCompactGrid,
  LibraryDisplayStyle.coverGrid => l10n.libraryDisplayCoverGrid,
  LibraryDisplayStyle.list => l10n.libraryDisplayList,
  LibraryDisplayStyle.compactList => l10n.libraryDisplayCompactList,
};

IconData libraryDisplayStyleIcon(LibraryDisplayStyle style) => switch (style) {
  LibraryDisplayStyle.comfortableGrid => Icons.grid_view_rounded,
  LibraryDisplayStyle.compactGrid => Icons.view_module_rounded,
  LibraryDisplayStyle.coverGrid => Icons.image_outlined,
  LibraryDisplayStyle.list => Icons.view_list_rounded,
  LibraryDisplayStyle.compactList => Icons.format_list_bulleted_rounded,
};

/// How the library is laid out: grid or list, how big the covers are, and
/// which badges they carry.
class LibraryDisplaySettingsBody extends ConsumerWidget {
  const LibraryDisplaySettingsBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final style =
        ref.watch(libraryDisplayStyleProvider).value ??
        LibraryDisplayStyle.comfortableGrid;
    final size =
        ref.watch(libraryGridTileSizeProvider).value ??
        LibraryGridTileSize.medium;
    final repository = ref.read(settingsRepositoryProvider);
    final showProgress =
        ref.watch(boolSettingProvider(Settings.libraryShowProgress)).value ??
        false;

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
        AppChoice<LibraryDisplayStyle>.of(
          style: AppChoiceStyle.pills,
          values: LibraryDisplayStyle.values,
          label: (style) => libraryDisplayStyleLabel(style, l10n),
          icon: libraryDisplayStyleIcon,
          value: style,
          onChanged: (value) =>
              repository.putSetting(Settings.libraryDisplayStyle, value),
        ),
        if (style.isGrid) ...[
          const SizedBox(height: 10),
          AppChoice<LibraryGridTileSize>.of(
            style: AppChoiceStyle.pills,
            values: LibraryGridTileSize.values,
            label: (size) => gridTileSizeLabel(size, l10n),
            icon: gridTileSizeIcon,
            value: size,
            onChanged: repository.setLibraryGridTileSize,
          ),
        ],
        const SizedBox(height: 10),
        AppSwitchRow(
          icon: Icons.mark_chat_unread_outlined,
          title: l10n.libraryBadgeUnread,
          value: showUnread,
          onChanged: (on) =>
              repository.putSetting(Settings.libraryShowUnreadBadge, on),
        ),
        AppSwitchRow(
          icon: Icons.linear_scale_rounded,
          title: l10n.libraryShowProgress,
          subtitle: l10n.libraryShowProgressHint,
          value: showProgress,
          onChanged: (on) =>
              repository.putSetting(Settings.libraryShowProgress, on),
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

String _shelfLabel(DashboardShelfStyle style, AppLocalizations l10n) =>
    switch (style) {
      DashboardShelfStyle.shelf => l10n.shelfStyleShelf,
      DashboardShelfStyle.grid => l10n.shelfStyleGrid,
      DashboardShelfStyle.list => l10n.shelfStyleList,
    };

IconData _shelfIcon(DashboardShelfStyle style) => switch (style) {
  DashboardShelfStyle.shelf => Icons.view_carousel_outlined,
  DashboardShelfStyle.grid => Icons.grid_view_rounded,
  DashboardShelfStyle.list => Icons.view_list_rounded,
};

/// How the other places that list titles are laid out: the sections of the
/// home page and the updates and history pages.
class LibraryDisplayPlacesBody extends ConsumerWidget {
  const LibraryDisplayPlacesBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final repository = ref.read(settingsRepositoryProvider);

    PickRow<DashboardShelfStyle> shelfRow(
      IconData icon,
      String title,
      EnumSetting<DashboardShelfStyle> setting,
      StreamProvider<DashboardShelfStyle> provider,
    ) => PickRow<DashboardShelfStyle>(
      icon: icon,
      title: title,
      value: ref.watch(provider).value ?? setting.defaultValue,
      values: DashboardShelfStyle.values,
      labelOf: (v) => _shelfLabel(v, l10n),
      iconOf: _shelfIcon,
      onChanged: (v) => repository.putSetting(setting, v),
    );

    PickRow<LibraryDisplayStyle> pageRow(
      String title,
      EnumSetting<LibraryDisplayStyle> setting,
      StreamProvider<LibraryDisplayStyle> provider,
    ) => PickRow<LibraryDisplayStyle>(
      icon: Icons.dashboard_customize_outlined,
      title: title,
      value: ref.watch(provider).value ?? setting.defaultValue,
      values: LibraryDisplayStyle.values,
      labelOf: (v) => libraryDisplayStyleLabel(v, l10n),
      iconOf: libraryDisplayStyleIcon,
      onChanged: (v) => repository.putSetting(setting, v),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionLabel(label: l10n.libraryDisplayHomeTitle),
        shelfRow(
          Icons.play_circle_outline_rounded,
          l10n.libraryDisplayHomeContinue,
          Settings.homeContinueStyle,
          homeContinueStyleProvider,
        ),
        shelfRow(
          Icons.new_releases_outlined,
          l10n.libraryDisplayHomeUpdates,
          Settings.homeUpdatesStyle,
          homeUpdatesStyleProvider,
        ),
        shelfRow(
          Icons.history_rounded,
          l10n.libraryDisplayHomeHistory,
          Settings.homeHistoryStyle,
          homeHistoryStyleProvider,
        ),
        pageRow(
          l10n.libraryDisplayUpdatesPage,
          Settings.updatesDisplayStyle,
          updatesDisplayStyleProvider,
        ),
        pageRow(
          l10n.libraryDisplayHistoryPage,
          Settings.historyDisplayStyle,
          historyDisplayStyleProvider,
        ),
      ],
    );
  }
}
