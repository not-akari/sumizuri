import 'package:sumizuri/core/navigation/nav_destination_kind.dart';
import 'package:sumizuri/core/theming/app_theme.dart' show AppColorScheme;
import 'package:sumizuri/features/library/models/category_smart_rule.dart';
import 'package:sumizuri/features/library/models/dashboard_section_kind.dart';
import 'package:sumizuri/features/library/models/library_types.dart';
import 'package:sumizuri/features/reader/models/reader_settings_types.dart';
import 'package:sumizuri/features/settings/models/app_settings_types.dart';
import 'package:sumizuri/features/settings/registry/setting_def.dart';

abstract final class Settings {
  static const onboardingCompleted = SettingDef<bool>(
    'onboarding.completed',
    false,
    scope: SettingScope.app,
    sync: false,
  );
  static const downloadDirectory = SettingDef<String>(
    'downloads.directory',
    '',
    scope: SettingScope.app,
    sync: false,
  );
  static const networkTimeoutSeconds = SettingDef<int>(
    'network.timeoutSeconds',
    30,
    scope: SettingScope.app,
  );
  static const networkUserAgent = SettingDef<String>(
    'network.userAgent',
    '',
    scope: SettingScope.app,
  );
  static const checkForUpdatesOnStartup = SettingDef<bool>(
    'updates.checkOnStartup',
    true,
    scope: SettingScope.app,
  );
  static const reduceMotion = SettingDef<bool>(
    'ui.reduceMotion',
    false,
    scope: SettingScope.app,
  );
  static const autoLibraryUpdateWifiOnly = SettingDef<bool>(
    'library.updateWifiOnly',
    true,
    scope: SettingScope.app,
  );
  static const lastAutoLibraryUpdateAt = EpochSetting(
    'library.lastAutoUpdateAt',
    scope: SettingScope.app,
    sync: false,
  );
  static const backgroundUpdateCursor = SettingDef<int>(
    'library.backgroundUpdateCursor',
    0,
    scope: SettingScope.app,
    sync: false,
  );
  static const appLockEnabled = SettingDef<bool>(
    'lock.enabled',
    false,
    scope: SettingScope.app,
    sync: false,
  );
  static const appLockUseBiometric = SettingDef<bool>(
    'lock.useBiometric',
    false,
    scope: SettingScope.app,
    sync: false,
  );
  static const appLockGracePeriodMinutes = SettingDef<int>(
    'lock.graceMinutes',
    0,
    scope: SettingScope.app,
    sync: false,
  );
  static const notificationsEnabled = SettingDef<bool>(
    'notifications.enabled',
    true,
    scope: SettingScope.app,
  );
  // Phones only: the viewer said yes to notifications here and the system allowed it.
  static const notificationsPhoneOptIn = SettingDef<bool>(
    'notifications.phoneOptIn',
    false,
    scope: SettingScope.app,
    sync: false,
  );
  static const notificationsHideWhileInApp = SettingDef<bool>(
    'notifications.hideWhileInApp',
    true,
    scope: SettingScope.app,
    sync: false,
  );
  static const showPerformanceOverlay = SettingDef<bool>(
    'debug.performanceOverlay',
    false,
    scope: SettingScope.app,
  );
  static const disabledLogCategories = SettingDef<String>(
    'logs.disabledCategories',
    '',
    scope: SettingScope.app,
  );
  static const autoBackupEnabled = SettingDef<bool>(
    'backup.autoEnabled',
    false,
    scope: SettingScope.app,
  );
  static const autoBackupIntervalDays = SettingDef<int>(
    'backup.intervalDays',
    1,
    scope: SettingScope.app,
  );
  static const autoBackupKeep = SettingDef<int>(
    'backup.keep',
    5,
    scope: SettingScope.app,
  );
  static const autoBackupLastAt = EpochSetting(
    'backup.lastAt',
    scope: SettingScope.app,
    sync: false,
  );
  static const incognito = SettingDef<bool>(
    'incognito',
    false,
    scope: SettingScope.app,
    sync: false,
  );
  static const libraryUpdateSkip = SettingDef<int>(
    'library.updateSkip',
    0,
    scope: SettingScope.app,
  );
  static const libraryMode = EnumSetting<AppLibraryMode>(
    'library.mode',
    AppLibraryMode.values,
    AppLibraryMode.unified,
  );
  static const enabledMediaTypes = EnumListSetting<MediaType>(
    'library.enabledMediaTypes',
    MediaType.values,
    [MediaType.manga],
  );
  static const themeScheme = SettingDef<String>('theme.scheme', 'sumizuriInk');
  static const themeHiddenPresets = EnumListSetting<AppColorScheme>(
    'theme.hiddenPresets',
    AppColorScheme.values,
    [],
  );
  // Speed, style and motion belonged to the removed animated background. Ids stay reserved.
  static const backgroundMotion = EnumSetting<AppBackgroundMotion>(
    'theme.backgroundMotion',
    AppBackgroundMotion.values,
    AppBackgroundMotion.auto,
    scope: SettingScope.app,
    sync: false,
  );
  static const backgroundSpeed = SettingDef<double>(
    'theme.backgroundSpeed',
    1.0,
    scope: SettingScope.app,
    sync: false,
  );
  static const backgroundStyle = SettingDef<String>(
    'theme.backgroundStyle',
    '',
    scope: SettingScope.app,
    sync: false,
  );
  static const backgroundIntensity = SettingDef<double>(
    'theme.backgroundIntensity',
    1.0,
    scope: SettingScope.app,
    sync: false,
  );
  static const darkModePreference = EnumSetting<AppDarkModePreference>(
    'theme.darkMode',
    AppDarkModePreference.values,
    AppDarkModePreference.system,
  );
  static const amoledDark = SettingDef<bool>('theme.amoled', false);
  static const colorIntensity = EnumSetting<ColorIntensity>(
    'theme.colorIntensity',
    ColorIntensity.values,
    ColorIntensity.medium,
  );
  static const navDestinations = EnumListSetting<NavDestinationKind>(
    'nav.destinations',
    NavDestinationKind.values,
    [
      NavDestinationKind.library,
      NavDestinationKind.browse,
      NavDestinationKind.settings,
    ],
  );
  static const dashboardSectionOrder = EnumListSetting<DashboardSectionKind>(
    'dashboard.sectionOrder',
    DashboardSectionKind.values,
    [
      DashboardSectionKind.updates,
      DashboardSectionKind.history,
      DashboardSectionKind.library,
    ],
  );
  static const readerMode = EnumSetting<ReaderMode>(
    'reader.mode',
    ReaderMode.values,
    ReaderMode.rightToLeft,
  );
  static const readerScaleType = EnumSetting<ReaderScaleType>(
    'reader.scaleType',
    ReaderScaleType.values,
    ReaderScaleType.fitWidth,
  );
  static const readerBackground = EnumSetting<ReaderBackground>(
    'reader.background',
    ReaderBackground.values,
    ReaderBackground.black,
  );
  static const readerPageGap = EnumSetting<ReaderPageGap>(
    'reader.pageGap',
    ReaderPageGap.values,
    ReaderPageGap.none,
  );
  static const readerInvertTaps = SettingDef<bool>('reader.invertTaps', false);
  static const readerDualPageMode = EnumSetting<ReaderDualPageMode>(
    'reader.dualPageMode',
    ReaderDualPageMode.values,
    ReaderDualPageMode.off,
  );
  static const readerColumnWidth = EnumSetting<ReaderColumnWidth>(
    'reader.columnWidth',
    ReaderColumnWidth.values,
    ReaderColumnWidth.fullWidth,
  );
  static const readerImageQuality = EnumSetting<ReaderImageQuality>(
    'reader.imageQuality',
    ReaderImageQuality.values,
    ReaderImageQuality.balanced,
  );
  static const libraryShowUnreadBadge = SettingDef<bool>(
    'library.showUnreadBadge',
    true,
  );
  static const libraryShowDownloadBadge = SettingDef<bool>(
    'library.showDownloadBadge',
    false,
  );
  static const libraryGridTileSize = EnumSetting<LibraryGridTileSize>(
    'library.gridTileSize',
    LibraryGridTileSize.values,
    LibraryGridTileSize.medium,
  );
  static const novelFontFamily = EnumSetting<ReaderFontFamily>(
    'novel.fontFamily',
    ReaderFontFamily.values,
    ReaderFontFamily.systemDefault,
  );
  static const novelFontSize = SettingDef<double>('novel.fontSize', 18.0);
  static const novelLineHeight = SettingDef<double>('novel.lineHeight', 1.5);
  static const novelParagraphSpacing = SettingDef<double>(
    'novel.paragraphSpacing',
    12.0,
  );
  static const chapterSortAscending = SettingDef<bool>(
    'chapters.sortAscending',
    false,
  );
  static const hideAllCategoryChip = SettingDef<bool>(
    'library.hideAllChip',
    false,
  );
  static const hideUncategorizedCategoryChip = SettingDef<bool>(
    'library.hideUncategorizedChip',
    false,
  );
  static const categoriesEnabled = SettingDef<bool>(
    'library.categoriesEnabled',
    true,
  );
  static const librarySortField = EnumSetting<CategorySortField>(
    'library.sortField',
    CategorySortField.values,
    CategorySortField.lastUpdatedAt,
  );
  static const librarySortAscending = SettingDef<bool>(
    'library.sortAscending',
    false,
  );
  static const downloadsWifiOnly = SettingDef<bool>('downloads.wifiOnly', true);
  static const playerAutoPlayNext = SettingDef<bool>(
    'player.autoPlayNext',
    true,
  );
  static const playerAutoPip = SettingDef<bool>(
    'player.autoPictureInPicture',
    false,
    scope: SettingScope.app,
    sync: false,
  );
  static const playerSkipSeconds = SettingDef<int>('player.skipSeconds', 30);
  static const playerSubtitleSize = SettingDef<int>('player.subtitleSize', 1);
  static const playerSubtitleColor = SettingDef<int>('player.subtitleColor', 0);
  static const playerSubtitleBackground = SettingDef<int>(
    'player.subtitleBackground',
    1,
  );
  static const playerSubtitleBold = SettingDef<bool>(
    'player.subtitleBold',
    false,
  );
  static const playerSubtitleRaise = SettingDef<int>('player.subtitleRaise', 1);
  static const playerSubtitleLanguage = SettingDef<String>(
    'player.subtitleLanguage',
    '',
  );
  static const playerSubtitlesOn = SettingDef<bool>('player.subtitlesOn', true);
  static const playerQualityMode = SettingDef<int>('player.qualityMode', 0);
  static const playerAudioPreference = SettingDef<int>(
    'player.audioPreference',
    0,
  );
  static const playerDoubleTapSeconds = SettingDef<int>(
    'player.doubleTapSeconds',
    5,
  );
  static const playerHideControlsSeconds = SettingDef<int>(
    'player.hideControlsSeconds',
    3,
  );
  static const playerDefaultSpeed = SettingDef<int>('player.defaultSpeed', 100);
  static const playerSwipeGestures = SettingDef<bool>(
    'player.swipeGestures',
    true,
  );
  static const playerHoldSpeed = SettingDef<int>('player.holdSpeed', 200);
  static const playerShowLog = SettingDef<bool>('player.showLog', false);
  static const playerPreferredQuality = SettingDef<String>(
    'player.preferredQuality',
    '',
  );
  static const autoDownloadChapterLimit = SettingDef<int>(
    'downloads.autoChapterLimit',
    0,
  );
  static const keepDownloadsBehind = SettingDef<int>(
    'downloads.keepBehind',
    -1,
  );

  // The queue survives closing the app. It stays on this device, so it is not synced.
  static const downloadQueue = SettingDef<String>(
    'downloads.queue',
    '',
    scope: SettingScope.app,
    sync: false,
  );
  static const downloadAheadCount = SettingDef<int>('downloads.aheadCount', 0);
  static const downloadDelaySeconds = SettingDef<int>(
    'downloads.delaySeconds',
    1,
  );
  static const autoDownloadOnLibraryUpdate = SettingDef<bool>(
    'downloads.autoOnUpdate',
    false,
  );
  static const autoDownloadOnAddToLibrary = SettingDef<bool>(
    'downloads.autoOnAdd',
    false,
  );

  static const displayHighRefreshRate = SettingDef<bool>(
    'display.highRefreshRate',
    true,
    scope: SettingScope.app,
    sync: false,
  );
  static const downloadsSkipDuplicateRead = SettingDef<bool>(
    'downloads.skipDuplicateRead',
    false,
  );
  static const navStyle = EnumSetting<AppNavStyle>(
    'nav.style',
    AppNavStyle.values,
    AppNavStyle.auto,
  );
  static const chapterListLayout = EnumSetting<ChapterListLayout>(
    'chapters.listLayout',
    ChapterListLayout.values,
    ChapterListLayout.list,
  );
  static const autoLibraryUpdateIntervalHours = SettingDef<int>(
    'library.autoUpdateIntervalHours',
    0,
  );
  static const readerKeepScreenOn = SettingDef<bool>(
    'reader.keepScreenOn',
    true,
  );
  // Percent of black laid over the reader, and of warm light for night reading.
  static const readerScreenDim = SettingDef<int>(
    'reader.screenDim',
    0,
    scope: SettingScope.app,
    sync: false,
  );
  static const readerScreenWarmth = SettingDef<int>(
    'reader.screenWarmth',
    0,
    scope: SettingScope.app,
    sync: false,
  );
  static const readerHideSystemBars = SettingDef<bool>(
    'reader.hideSystemBars',
    true,
    scope: SettingScope.app,
    sync: false,
  );
  static const readerVolumeKeys = SettingDef<bool>('reader.volumeKeys', false);
  static const readerVerticalNavigator = SettingDef<bool>(
    'reader.verticalNavigator',
    false,
  );
  static const readerControls = SettingDef<String>('reader.controls', '');
  static const appGestures = SettingDef<String>('app.gestures', '');

  static const List<SettingDef<Object?>> all = [
    onboardingCompleted,
    downloadDirectory,
    networkTimeoutSeconds,
    networkUserAgent,
    checkForUpdatesOnStartup,
    reduceMotion,
    autoLibraryUpdateWifiOnly,
    lastAutoLibraryUpdateAt,
    backgroundUpdateCursor,
    appLockEnabled,
    appLockUseBiometric,
    appLockGracePeriodMinutes,
    notificationsEnabled,
    notificationsHideWhileInApp,
    notificationsPhoneOptIn,
    showPerformanceOverlay,
    disabledLogCategories,
    autoBackupEnabled,
    autoBackupIntervalDays,
    autoBackupKeep,
    autoBackupLastAt,
    incognito,
    libraryUpdateSkip,
    libraryMode,
    enabledMediaTypes,
    themeScheme,
    themeHiddenPresets,
    backgroundMotion,
    backgroundSpeed,
    backgroundIntensity,
    backgroundStyle,
    darkModePreference,
    amoledDark,
    colorIntensity,
    navDestinations,
    dashboardSectionOrder,
    readerMode,
    readerScaleType,
    readerBackground,
    readerPageGap,
    readerInvertTaps,
    readerDualPageMode,
    readerColumnWidth,
    readerImageQuality,
    libraryShowUnreadBadge,
    libraryShowDownloadBadge,
    libraryGridTileSize,
    novelFontFamily,
    novelFontSize,
    novelLineHeight,
    novelParagraphSpacing,
    chapterSortAscending,
    hideAllCategoryChip,
    hideUncategorizedCategoryChip,
    categoriesEnabled,
    librarySortField,
    librarySortAscending,
    downloadsWifiOnly,
    playerAutoPlayNext,
    playerAutoPip,
    playerSkipSeconds,
    playerSubtitleSize,
    playerSubtitleColor,
    playerSubtitleBackground,
    playerSubtitleBold,
    playerSubtitleRaise,
    playerSubtitleLanguage,
    playerSubtitlesOn,
    playerQualityMode,
    playerAudioPreference,
    playerDoubleTapSeconds,
    playerHideControlsSeconds,
    playerDefaultSpeed,
    playerSwipeGestures,
    playerHoldSpeed,
    playerShowLog,
    playerPreferredQuality,
    autoDownloadChapterLimit,
    keepDownloadsBehind,
    downloadAheadCount,
    downloadDelaySeconds,
    downloadQueue,
    autoDownloadOnLibraryUpdate,
    autoDownloadOnAddToLibrary,
    downloadsSkipDuplicateRead,
    displayHighRefreshRate,
    navStyle,
    chapterListLayout,
    autoLibraryUpdateIntervalHours,
    readerKeepScreenOn,
    readerHideSystemBars,
    readerScreenDim,
    readerScreenWarmth,
    readerVolumeKeys,
    readerVerticalNavigator,
    readerControls,
    appGestures,
  ];

  static const Map<String, SettingDef<Object?>> legacyAppColumns = {
    'onboarding_completed': Settings.onboardingCompleted,
    'download_directory_path': Settings.downloadDirectory,
    'network_timeout_seconds': Settings.networkTimeoutSeconds,
    'network_user_agent': Settings.networkUserAgent,
    'check_for_updates_on_startup': Settings.checkForUpdatesOnStartup,
    'reduce_motion': Settings.reduceMotion,
    'auto_library_update_wifi_only': Settings.autoLibraryUpdateWifiOnly,
    'last_auto_library_update_at': Settings.lastAutoLibraryUpdateAt,
    'app_lock_enabled': Settings.appLockEnabled,
    'app_lock_use_biometric': Settings.appLockUseBiometric,
    'app_lock_grace_period_minutes': Settings.appLockGracePeriodMinutes,
    'notifications_enabled': Settings.notificationsEnabled,
    'show_performance_overlay': Settings.showPerformanceOverlay,
    'disabled_log_categories': Settings.disabledLogCategories,
    'auto_backup_enabled': Settings.autoBackupEnabled,
    'auto_backup_interval_days': Settings.autoBackupIntervalDays,
    'auto_backup_keep': Settings.autoBackupKeep,
    'auto_backup_last_at': Settings.autoBackupLastAt,
    'incognito': Settings.incognito,
    'library_update_skip': Settings.libraryUpdateSkip,
  };

  static const Map<String, SettingDef<Object?>> legacyProfileColumns = {
    'library_mode': Settings.libraryMode,
    'enabled_media_types': Settings.enabledMediaTypes,
    'theme_scheme': Settings.themeScheme,
    'dark_mode_preference': Settings.darkModePreference,
    'amoled_dark': Settings.amoledDark,
    'color_intensity': Settings.colorIntensity,
    'nav_destinations_order': Settings.navDestinations,
    'dashboard_section_order': Settings.dashboardSectionOrder,
    'reader_mode': Settings.readerMode,
    'reader_scale_type': Settings.readerScaleType,
    'reader_background': Settings.readerBackground,
    'reader_page_gap': Settings.readerPageGap,
    'reader_invert_taps': Settings.readerInvertTaps,
    'reader_dual_page_mode': Settings.readerDualPageMode,
    'reader_column_width': Settings.readerColumnWidth,
    'reader_image_quality': Settings.readerImageQuality,
    'library_grid_tile_size': Settings.libraryGridTileSize,
    'novel_font_family': Settings.novelFontFamily,
    'novel_font_size': Settings.novelFontSize,
    'novel_line_height': Settings.novelLineHeight,
    'novel_paragraph_spacing': Settings.novelParagraphSpacing,
    'chapter_sort_ascending': Settings.chapterSortAscending,
    'hide_all_category_chip': Settings.hideAllCategoryChip,
    'hide_uncategorized_category_chip': Settings.hideUncategorizedCategoryChip,
    'categories_enabled': Settings.categoriesEnabled,
    'library_sort_field': Settings.librarySortField,
    'library_sort_ascending': Settings.librarySortAscending,
    'downloads_wifi_only': Settings.downloadsWifiOnly,
    'auto_download_chapter_limit': Settings.autoDownloadChapterLimit,
    'keep_downloads_behind': Settings.keepDownloadsBehind,
    'download_delay_seconds': Settings.downloadDelaySeconds,
    'auto_download_on_library_update': Settings.autoDownloadOnLibraryUpdate,
    'auto_download_on_add_to_library': Settings.autoDownloadOnAddToLibrary,
    'nav_style': Settings.navStyle,
    'chapter_list_layout': Settings.chapterListLayout,
    'auto_library_update_interval_hours':
        Settings.autoLibraryUpdateIntervalHours,
    'reader_keep_screen_on': Settings.readerKeepScreenOn,
    'reader_volume_keys': Settings.readerVolumeKeys,
    'reader_vertical_navigator': Settings.readerVerticalNavigator,
    'reader_controls': Settings.readerControls,
    'app_gestures': Settings.appGestures,
  };
}
