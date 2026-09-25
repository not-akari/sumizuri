import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/features/settings/models/app_settings_types.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';
import 'package:sumizuri/features/security/pages/security_settings_page.dart';
import 'package:sumizuri/features/settings/pages/advanced_settings_page.dart';
import 'package:sumizuri/features/settings/pages/appearance_settings_page.dart';
import 'package:sumizuri/features/settings/pages/backup_restore_page.dart';
import 'package:sumizuri/features/settings/pages/categories_settings_page.dart';
import 'package:sumizuri/features/settings/pages/downloads_page.dart';
import 'package:sumizuri/features/settings/pages/player_settings_page.dart';
import 'package:sumizuri/features/library/providers/library_providers.dart';
import 'package:sumizuri/features/settings/pages/library_settings_page.dart';
import 'package:sumizuri/features/settings/pages/library_update_settings_page.dart';
import 'package:sumizuri/features/settings/pages/missing_sources_page.dart';
import 'package:sumizuri/features/settings/pages/notifications_settings_page.dart';
import 'package:sumizuri/core/window/native_title_bar.dart';
import 'package:sumizuri/features/profile/pages/profile_page.dart';
import 'package:sumizuri/features/settings/pages/reader_controls_page.dart';
import 'package:sumizuri/features/settings/pages/storage_page.dart';
import 'package:sumizuri/features/settings/pages/reader_settings_page.dart';
import 'package:sumizuri/features/settings/models/settings_models.dart';
import 'package:sumizuri/features/settings/pages/settings_sections_support.dart';

void _openAppearance(BuildContext context, [AppearanceSection? highlight]) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => AppearanceSettingsPage(highlight: highlight),
    ),
  );
}

/// Null (no subtitle line) once nothing needs it, so the entry doesn't nag forever.
String? _missingSourcesSubtitle(WidgetRef ref, AppLocalizations l10n) {
  final total = ref
      .watch(entriesNeedingMigrationProvider)
      .values
      .fold<int>(0, (sum, entries) => sum + entries.length);
  return total == 0 ? null : l10n.missingSourcesSettingsSubtitle(total);
}

List<SettingsSection> buildSettingsSections({
  required WidgetRef ref,
  required AppLocalizations l10n,
  required AppLibraryMode mode,
  required String? appVersion,
}) => [
  SettingsSection(
    title: l10n.settingsSectionAppearance,
    group: SettingsGroup.general,
    entries: [
      SettingsEntry(
        icon: Icons.palette_outlined,
        title: l10n.settingsSectionAppearance,
        subtitle: l10n.settingsAppearanceSubtitle,
        onTap: (context, ref) => _openAppearance(context),
      ),
      SettingsEntry(
        searchOnly: true,
        icon: Icons.palette_outlined,
        title: l10n.settingsThemeTile,
        subtitle: l10n.settingsThemeSubtitle,
        keywords: const [
          'dark mode',
          'light mode',
          'amoled',
          'color',
          'scheme',
        ],
        onTap: (context, ref) =>
            _openAppearance(context, AppearanceSection.theme),
      ),
      SettingsEntry(
        searchOnly: true,
        icon: Icons.visibility_off_outlined,
        title: l10n.incognitoTitle,
        subtitle: l10n.incognitoHint,
        keywords: const ['private', 'history', 'hide', 'tracking', 'reading'],
        onTap: (context, ref) => Navigator.of(context)
            .push(MaterialPageRoute<void>(builder: (_) => const ProfilePage())),
      ),
      SettingsEntry(
        searchOnly: true,
        icon: Icons.grid_view_outlined,
        title: l10n.settingsGridTileSizeTile,
        subtitle: l10n.settingsGridTileSizeSubtitle,
        keywords: const [
          'grid',
          'covers',
          'tile',
          'size',
          'small',
          'medium',
          'large',
        ],
        onTap: (context, ref) =>
            _openAppearance(context, AppearanceSection.gridTileSize),
      ),
      SettingsEntry(
        searchOnly: true,
        icon: Icons.dock_outlined,
        title: l10n.navCustomizationTitle,
        keywords: const ['nav bar', 'destinations', 'reorder', 'nav style'],
        onTap: (context, ref) =>
            _openAppearance(context, AppearanceSection.navigation),
      ),
      SettingsEntry(
        searchOnly: true,
        icon: Icons.dashboard_outlined,
        title: l10n.homeScreenOrderTitle,
        keywords: const ['updates', 'history', 'dashboard', 'sections'],
        onTap: (context, ref) =>
            _openAppearance(context, AppearanceSection.homeScreenOrder),
      ),
      SettingsEntry(
        searchOnly: true,
        icon: Icons.blur_on_outlined,
        title: l10n.backgroundTitle,
        keywords: const ['background', 'wash', 'colour', 'color', 'intensity'],
        onTap: (context, ref) =>
            _openAppearance(context, AppearanceSection.background),
      ),
      SettingsEntry(
        searchOnly: true,
        icon: Icons.motion_photos_off_outlined,
        title: l10n.settingsReduceMotionTile,
        keywords: const [
          'motion',
          'animation',
          'accessibility',
          'vestibular',
          'transitions',
        ],
        onTap: (context, ref) =>
            _openAppearance(context, AppearanceSection.motion),
      ),
    ],
  ),
  SettingsSection(
    title: l10n.settingsSectionLibrary,
    group: SettingsGroup.content,
    entries: [
      SettingsEntry(
        icon: Icons.auto_stories_outlined,
        title: l10n.settingsSectionLibrary,
        subtitle: l10n.settingsLibrarySettingsSubtitle,
        keywords: const ['manga', 'novel', 'anime', 'unified', 'split'],
        onTap: (context, ref) => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const LibrarySettingsPage())),
      ),
      SettingsEntry(
        searchOnly: true,
        icon: Icons.label_outlined,
        title: l10n.libraryManageCategories,
        keywords: const ['categories', 'update', 'exclude'],
        onTap: (context, ref) => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CategoriesSettingsPage()),
        ),
      ),
      SettingsEntry(
        searchOnly: true,
        icon: Icons.update_outlined,
        title: l10n.libraryAutoUpdateTitle,
        keywords: const [
          'auto',
          'update',
          'background',
          'interval',
          'schedule',
        ],
        onTap: (context, ref) => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const LibraryUpdateSettingsPage()),
        ),
      ),
      SettingsEntry(
        searchOnly: true,
        icon: Icons.link_off,
        title: l10n.missingSourcesTitle,
        subtitle: _missingSourcesSubtitle(ref, l10n),
        keywords: const [
          'migrate',
          'migration',
          'source',
          'missing',
          'imported',
        ],
        onTap: (context, ref) => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const MissingSourcesPage())),
      ),
    ],
  ),
  SettingsSection(
    title: l10n.settingsSectionReader,
    group: SettingsGroup.content,
    entries: [
      SettingsEntry(
        icon: Icons.chrome_reader_mode_outlined,
        title: l10n.readerSettingsTitle,
        keywords: const [
          'paged',
          'webtoon',
          'scale',
          'page gap',
          'novel',
          'font',
        ],
        onTap: (context, ref) => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const GlobalReaderSettingsPage()),
        ),
      ),
      SettingsEntry(
        icon: Icons.smart_display_outlined,
        title: l10n.playerSettingsTitle,
        keywords: const ['anime', 'video', 'episode', 'autoplay', 'quality'],
        onTap: (context, ref) => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const PlayerSettingsPage())),
      ),
      SettingsEntry(
        searchOnly: true,
        icon: Icons.subtitles_outlined,
        title: l10n.playerSectionSubtitles,
        keywords: const [
          'anime',
          'video',
          'captions',
          'language',
          'size',
          'colour',
          'color',
        ],
        onTap: (context, ref) => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const SubtitleSettingsPage())),
      ),
      SettingsEntry(
        searchOnly: true,
        icon: Icons.keyboard_outlined,
        title: isDesktopWindowPlatform
            ? l10n.readerControlsTitle
            : l10n.readerGesturesTitle,
        subtitle: isDesktopWindowPlatform
            ? l10n.readerControlsSubtitle
            : l10n.readerGesturesSubtitle,
        keywords: const [
          'keyboard',
          'shortcut',
          'key',
          'gesture',
          'tap',
          'zone',
          'preset',
        ],
        onTap: (context, ref) => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const ReaderControlsPage())),
      ),
    ],
  ),
  SettingsSection(
    title: l10n.settingsSectionDownloads,
    group: SettingsGroup.data,
    entries: [
      SettingsEntry(
        icon: Icons.download_outlined,
        title: l10n.settingsDownloadsAndStorage,
        subtitle: l10n.downloadsSubtitle,
        keywords: const [
          'downloads',
          'chapters',
          'folder',
          'offline',
          'auto-download',
          'wifi',
          'mobile data',
        ],
        onTap: (context, ref) =>
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const DownloadsPage())),
      ),
      SettingsEntry(
        searchOnly: true,
        icon: Icons.pie_chart_outline,
        title: l10n.storagePageTitle,
        subtitle: l10n.storagePageSubtitle,
        keywords: const ['storage', 'space', 'disk', 'cache', 'clear', 'size'],
        onTap: (context, ref) =>
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const StoragePage())),
      ),
    ],
  ),
  SettingsSection(
    title: l10n.settingsSectionNotifications,
    group: SettingsGroup.general,
    entries: [
      SettingsEntry(
        icon: Icons.notifications_outlined,
        title: l10n.settingsSectionNotifications,
        subtitle: l10n.notificationsEnabledHint,
        keywords: const ['notifications', 'alerts', 'push'],
        onTap: (context, ref) => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const NotificationsSettingsPage()),
        ),
      ),
    ],
  ),
  SettingsSection(
    title: l10n.settingsSectionBackup,
    group: SettingsGroup.data,
    entries: [
      SettingsEntry(
        icon: Icons.backup_outlined,
        title: l10n.settingsSectionBackup,
        subtitle: l10n.storageSubtitle,
        keywords: const [
          'export',
          'save',
          'import',
          'load',
          'rollback',
          'migration',
          'corrupted',
          'undo',
          'backup',
          'restore',
        ],
        onTap: (context, ref) => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const BackupRestorePage())),
      ),
    ],
  ),
  SettingsSection(
    title: l10n.settingsSectionSecurity,
    group: SettingsGroup.general,
    entries: [
      SettingsEntry(
        icon: Icons.lock_outline,
        title: l10n.settingsSectionSecurity,
        subtitle: l10n.securityAppLockHint,
        keywords: const [
          'lock',
          'pin',
          'biometric',
          'fingerprint',
          'password',
          'privacy',
        ],
        onTap: (context, ref) => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const SecuritySettingsPage())),
      ),
    ],
  ),
  SettingsSection(
    title: l10n.settingsSectionAdvanced,
    group: SettingsGroup.help,
    entries: [
      SettingsEntry(
        icon: Icons.speed_outlined,
        title: l10n.settingsSectionAdvanced,
        subtitle: l10n.advancedPerformanceOverlayTile,
        keywords: const [
          'fps',
          'ram',
          'performance',
          'overlay',
          'debug',
          'timeout',
          'user-agent',
          'network',
        ],
        onTap: (context, ref) => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const AdvancedSettingsPage())),
      ),
    ],
  ),
  buildSupportSection(ref: ref, l10n: l10n, appVersion: appVersion),
];
