part of 'settings_repository_impl.dart';

mixin DriftKvSettingsMethods {
  AppDatabase get _db;
  AppLogger get _logger;
  int get profileId;

  int _scopeOf(SettingDef<Object?> def) => settingScopeId(def, profileId);

  Stream<T> watchSetting<T>(SettingDef<T> def) =>
      _db.watchSettingRow(def, profileId: profileId);

  Future<Result<void, AppFailure>> putSetting<T>(SettingDef<T> def, T value) {
    return guardFailure(_logger, DriftSettingsRepository._tag, () {
      return _db.writeSettingRow(def, value, profileId: profileId);
    });
  }

  Future<T> _read<T>(SettingDef<T> def) => watchSetting(def).first;

  Stream<int> watchNetworkTimeoutSeconds() =>
      watchSetting(Settings.networkTimeoutSeconds);
  Future<Result<void, AppFailure>> setNetworkTimeoutSeconds(int value) =>
      putSetting(Settings.networkTimeoutSeconds, value);

  Stream<bool> watchCheckForUpdatesOnStartup() =>
      watchSetting(Settings.checkForUpdatesOnStartup);
  Future<Result<void, AppFailure>> setCheckForUpdatesOnStartup(bool value) =>
      putSetting(Settings.checkForUpdatesOnStartup, value);

  Stream<bool> watchReduceMotion() => watchSetting(Settings.reduceMotion);
  Future<Result<void, AppFailure>> setReduceMotion(bool value) =>
      putSetting(Settings.reduceMotion, value);

  Stream<bool> watchAutoLibraryUpdateWifiOnly() =>
      watchSetting(Settings.autoLibraryUpdateWifiOnly);
  Future<Result<void, AppFailure>> setAutoLibraryUpdateWifiOnly(bool value) =>
      putSetting(Settings.autoLibraryUpdateWifiOnly, value);

  Stream<bool> watchAppLockEnabled() => watchSetting(Settings.appLockEnabled);
  Future<Result<void, AppFailure>> setAppLockEnabled(bool value) =>
      putSetting(Settings.appLockEnabled, value);

  Stream<bool> watchAppLockUseBiometric() =>
      watchSetting(Settings.appLockUseBiometric);
  Future<Result<void, AppFailure>> setAppLockUseBiometric(bool value) =>
      putSetting(Settings.appLockUseBiometric, value);

  Stream<int> watchAppLockGracePeriodMinutes() =>
      watchSetting(Settings.appLockGracePeriodMinutes);
  Future<Result<void, AppFailure>> setAppLockGracePeriodMinutes(int value) =>
      putSetting(Settings.appLockGracePeriodMinutes, value);

  Stream<bool> watchNotificationsEnabled() =>
      watchSetting(Settings.notificationsEnabled);
  Future<Result<void, AppFailure>> setNotificationsEnabled(bool value) =>
      putSetting(Settings.notificationsEnabled, value);

  Stream<bool> watchShowPerformanceOverlay() =>
      watchSetting(Settings.showPerformanceOverlay);
  Future<Result<void, AppFailure>> setShowPerformanceOverlay(bool value) =>
      putSetting(Settings.showPerformanceOverlay, value);

  Stream<bool> watchIncognito() => watchSetting(Settings.incognito);
  Future<Result<void, AppFailure>> setIncognito(bool value) =>
      putSetting(Settings.incognito, value);

  Stream<int> watchLibraryUpdateSkip() =>
      watchSetting(Settings.libraryUpdateSkip);
  Future<Result<void, AppFailure>> setLibraryUpdateSkip(int value) =>
      putSetting(Settings.libraryUpdateSkip, value);

  Stream<AppDarkModePreference> watchDarkModePreference() =>
      watchSetting(Settings.darkModePreference);
  Future<Result<void, AppFailure>> setDarkModePreference(
    AppDarkModePreference value,
  ) => putSetting(Settings.darkModePreference, value);

  Stream<bool> watchAmoledDark() => watchSetting(Settings.amoledDark);
  Future<Result<void, AppFailure>> setAmoledDark(bool value) =>
      putSetting(Settings.amoledDark, value);

  Stream<ColorIntensity> watchColorIntensity() =>
      watchSetting(Settings.colorIntensity);
  Future<Result<void, AppFailure>> setColorIntensity(ColorIntensity value) =>
      putSetting(Settings.colorIntensity, value);

  Stream<List<NavDestinationKind>> watchNavDestinations() =>
      watchSetting(Settings.navDestinations);
  Future<Result<void, AppFailure>> setNavDestinations(
    List<NavDestinationKind> value,
  ) => putSetting(Settings.navDestinations, value);

  Stream<List<DashboardSectionKind>> watchDashboardSectionOrder() =>
      watchSetting(Settings.dashboardSectionOrder);
  Future<Result<void, AppFailure>> setDashboardSectionOrder(
    List<DashboardSectionKind> value,
  ) => putSetting(Settings.dashboardSectionOrder, value);

  Stream<ReaderMode> watchReaderMode() => watchSetting(Settings.readerMode);
  Future<Result<void, AppFailure>> setReaderMode(ReaderMode value) =>
      putSetting(Settings.readerMode, value);

  Stream<ReaderScaleType> watchReaderScaleType() =>
      watchSetting(Settings.readerScaleType);
  Future<Result<void, AppFailure>> setReaderScaleType(ReaderScaleType value) =>
      putSetting(Settings.readerScaleType, value);

  Stream<ReaderBackground> watchReaderBackground() =>
      watchSetting(Settings.readerBackground);
  Future<Result<void, AppFailure>> setReaderBackground(
    ReaderBackground value,
  ) => putSetting(Settings.readerBackground, value);

  Stream<ReaderPageGap> watchReaderPageGap() =>
      watchSetting(Settings.readerPageGap);
  Future<Result<void, AppFailure>> setReaderPageGap(ReaderPageGap value) =>
      putSetting(Settings.readerPageGap, value);

  Stream<bool> watchReaderInvertTaps() =>
      watchSetting(Settings.readerInvertTaps);
  Future<Result<void, AppFailure>> setReaderInvertTaps(bool value) =>
      putSetting(Settings.readerInvertTaps, value);

  Stream<ReaderDualPageMode> watchReaderDualPageMode() =>
      watchSetting(Settings.readerDualPageMode);
  Future<Result<void, AppFailure>> setReaderDualPageMode(
    ReaderDualPageMode value,
  ) => putSetting(Settings.readerDualPageMode, value);

  Stream<ReaderColumnWidth> watchReaderColumnWidth() =>
      watchSetting(Settings.readerColumnWidth);
  Future<Result<void, AppFailure>> setReaderColumnWidth(
    ReaderColumnWidth value,
  ) => putSetting(Settings.readerColumnWidth, value);

  Stream<ReaderImageQuality> watchReaderImageQuality() =>
      watchSetting(Settings.readerImageQuality);
  Future<Result<void, AppFailure>> setReaderImageQuality(
    ReaderImageQuality value,
  ) => putSetting(Settings.readerImageQuality, value);

  Stream<LibraryGridTileSize> watchLibraryGridTileSize() =>
      watchSetting(Settings.libraryGridTileSize);
  Future<Result<void, AppFailure>> setLibraryGridTileSize(
    LibraryGridTileSize value,
  ) => putSetting(Settings.libraryGridTileSize, value);

  Stream<ReaderFontFamily> watchNovelFontFamily() =>
      watchSetting(Settings.novelFontFamily);
  Future<Result<void, AppFailure>> setNovelFontFamily(ReaderFontFamily value) =>
      putSetting(Settings.novelFontFamily, value);

  Stream<double> watchNovelFontSize() => watchSetting(Settings.novelFontSize);
  Future<Result<void, AppFailure>> setNovelFontSize(double value) =>
      putSetting(Settings.novelFontSize, value);

  Stream<double> watchNovelLineHeight() =>
      watchSetting(Settings.novelLineHeight);
  Future<Result<void, AppFailure>> setNovelLineHeight(double value) =>
      putSetting(Settings.novelLineHeight, value);

  Stream<double> watchNovelParagraphSpacing() =>
      watchSetting(Settings.novelParagraphSpacing);
  Future<Result<void, AppFailure>> setNovelParagraphSpacing(double value) =>
      putSetting(Settings.novelParagraphSpacing, value);

  Stream<bool> watchChapterSortAscending() =>
      watchSetting(Settings.chapterSortAscending);
  Future<Result<void, AppFailure>> setChapterSortAscending(bool value) =>
      putSetting(Settings.chapterSortAscending, value);

  Stream<bool> watchHideAllCategoryChip() =>
      watchSetting(Settings.hideAllCategoryChip);
  Future<Result<void, AppFailure>> setHideAllCategoryChip(bool value) =>
      putSetting(Settings.hideAllCategoryChip, value);

  Stream<bool> watchHideUncategorizedCategoryChip() =>
      watchSetting(Settings.hideUncategorizedCategoryChip);
  Future<Result<void, AppFailure>> setHideUncategorizedCategoryChip(
    bool value,
  ) => putSetting(Settings.hideUncategorizedCategoryChip, value);

  Stream<bool> watchCategoriesEnabled() =>
      watchSetting(Settings.categoriesEnabled);
  Future<Result<void, AppFailure>> setCategoriesEnabled(bool value) =>
      putSetting(Settings.categoriesEnabled, value);

  Stream<CategorySortField> watchLibrarySortField() =>
      watchSetting(Settings.librarySortField);
  Future<Result<void, AppFailure>> setLibrarySortField(
    CategorySortField value,
  ) => putSetting(Settings.librarySortField, value);

  Stream<bool> watchLibrarySortAscending() =>
      watchSetting(Settings.librarySortAscending);
  Future<Result<void, AppFailure>> setLibrarySortAscending(bool value) =>
      putSetting(Settings.librarySortAscending, value);

  Stream<bool> watchDownloadsWifiOnly() =>
      watchSetting(Settings.downloadsWifiOnly);
  Future<Result<void, AppFailure>> setDownloadsWifiOnly(bool value) =>
      putSetting(Settings.downloadsWifiOnly, value);

  Stream<int> watchAutoDownloadChapterLimit() =>
      watchSetting(Settings.autoDownloadChapterLimit);
  Future<Result<void, AppFailure>> setAutoDownloadChapterLimit(int value) =>
      putSetting(Settings.autoDownloadChapterLimit, value);

  Stream<int> watchKeepDownloadsBehind() =>
      watchSetting(Settings.keepDownloadsBehind);
  Future<Result<void, AppFailure>> setKeepDownloadsBehind(int value) =>
      putSetting(Settings.keepDownloadsBehind, value);

  Stream<int> watchDownloadDelaySeconds() =>
      watchSetting(Settings.downloadDelaySeconds);
  Future<Result<void, AppFailure>> setDownloadDelaySeconds(int value) =>
      putSetting(Settings.downloadDelaySeconds, value);

  Stream<bool> watchAutoDownloadOnLibraryUpdate() =>
      watchSetting(Settings.autoDownloadOnLibraryUpdate);
  Future<Result<void, AppFailure>> setAutoDownloadOnLibraryUpdate(bool value) =>
      putSetting(Settings.autoDownloadOnLibraryUpdate, value);

  Stream<bool> watchAutoDownloadOnAddToLibrary() =>
      watchSetting(Settings.autoDownloadOnAddToLibrary);
  Future<Result<void, AppFailure>> setAutoDownloadOnAddToLibrary(bool value) =>
      putSetting(Settings.autoDownloadOnAddToLibrary, value);

  Stream<AppNavStyle> watchNavStyle() => watchSetting(Settings.navStyle);
  Future<Result<void, AppFailure>> setNavStyle(AppNavStyle value) =>
      putSetting(Settings.navStyle, value);

  Stream<ChapterListLayout> watchChapterListLayout() =>
      watchSetting(Settings.chapterListLayout);
  Future<Result<void, AppFailure>> setChapterListLayout(
    ChapterListLayout value,
  ) => putSetting(Settings.chapterListLayout, value);

  Stream<int> watchAutoLibraryUpdateIntervalHours() =>
      watchSetting(Settings.autoLibraryUpdateIntervalHours);
  Future<Result<void, AppFailure>> setAutoLibraryUpdateIntervalHours(
    int value,
  ) => putSetting(Settings.autoLibraryUpdateIntervalHours, value);

  Stream<bool> watchReaderKeepScreenOn() =>
      watchSetting(Settings.readerKeepScreenOn);
  Future<Result<void, AppFailure>> setReaderKeepScreenOn(bool value) =>
      putSetting(Settings.readerKeepScreenOn, value);

  Stream<bool> watchReaderVolumeKeys() =>
      watchSetting(Settings.readerVolumeKeys);
  Future<Result<void, AppFailure>> setReaderVolumeKeys(bool value) =>
      putSetting(Settings.readerVolumeKeys, value);

  Stream<bool> watchReaderVerticalNavigator() =>
      watchSetting(Settings.readerVerticalNavigator);
  Future<Result<void, AppFailure>> setReaderVerticalNavigator(bool value) =>
      putSetting(Settings.readerVerticalNavigator, value);

  Stream<bool> watchOnboardingCompleted() =>
      watchSetting(Settings.onboardingCompleted);
  Future<Result<void, AppFailure>> completeOnboarding() =>
      putSetting(Settings.onboardingCompleted, true);
  Future<Result<void, AppFailure>> resetOnboarding() =>
      putSetting(Settings.onboardingCompleted, false);

  Stream<String?> watchDownloadDirectoryPath() =>
      watchSetting(Settings.downloadDirectory).map((v) => v.isEmpty ? null : v);
  Future<Result<void, AppFailure>> setDownloadDirectoryPath(String? path) =>
      putSetting(Settings.downloadDirectory, path ?? '');

  Stream<String?> watchNetworkUserAgent() =>
      watchSetting(Settings.networkUserAgent).map((v) => v.isEmpty ? null : v);
  Future<Result<void, AppFailure>> setNetworkUserAgent(String? userAgent) =>
      putSetting(Settings.networkUserAgent, userAgent ?? '');

  Stream<String> watchThemeScheme() => watchSetting(Settings.themeScheme);
  Future<Result<void, AppFailure>> setThemeScheme(String schemeName) =>
      putSetting(Settings.themeScheme, schemeName);

  Stream<double> watchBackgroundIntensity() =>
      watchSetting(Settings.backgroundIntensity);
  Future<Result<void, AppFailure>> setBackgroundIntensity(double value) =>
      putSetting(Settings.backgroundIntensity, value);

  Stream<Set<AppColorScheme>> watchHiddenThemePresets() =>
      watchSetting(Settings.themeHiddenPresets).map((v) => v.toSet());
  Future<Result<void, AppFailure>> setHiddenThemePresets(
    Set<AppColorScheme> presets,
  ) => putSetting(Settings.themeHiddenPresets, presets.toList());

  Stream<String?> watchReaderControls() =>
      watchSetting(Settings.readerControls).map((v) => v.isEmpty ? null : v);
  Future<Result<void, AppFailure>> setReaderControls(String? json) =>
      putSetting(Settings.readerControls, json ?? '');

  Stream<String?> watchAppGestures() =>
      watchSetting(Settings.appGestures).map((v) => v.isEmpty ? null : v);
  Future<Result<void, AppFailure>> setAppGestures(String? json) =>
      putSetting(Settings.appGestures, json ?? '');

  Stream<Set<MediaType>> watchEnabledMediaTypes() =>
      watchSetting(Settings.enabledMediaTypes)
          .map((types) => reconcileEnabledMediaTypes(types.toSet()));
  Future<Result<void, AppFailure>> setEnabledMediaTypes(Set<MediaType> types) =>
      putSetting(
        Settings.enabledMediaTypes,
        reconcileEnabledMediaTypes(types).toList(),
      );

  Stream<AppLibraryMode> watchLibraryMode() {
    return _db.select(_db.settingValues).watch().map((rows) {
      String? valueOf(SettingDef<Object?> def) {
        for (final row in rows) {
          if (row.profileId == _scopeOf(def) && row.settingId == def.id) {
            return row.value;
          }
        }
        return null;
      }

      final types = reconcileEnabledMediaTypes(
        Settings.enabledMediaTypes
            .decode(valueOf(Settings.enabledMediaTypes))
            .toSet(),
      );
      if (types.length < 2) return AppLibraryMode.unified;
      return Settings.libraryMode.decode(valueOf(Settings.libraryMode));
    }).distinct();
  }

  Future<Result<void, AppFailure>> setLibraryMode(AppLibraryMode mode) =>
      putSetting(Settings.libraryMode, mode);

  // A moment is milliseconds in the store and a DateTime to the callers. Never is null.
  Future<DateTime?> getLastAutoLibraryUpdateAt() async {
    final ms = await _read(Settings.lastAutoLibraryUpdateAt);
    return ms == 0 ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<Result<void, AppFailure>> setLastAutoLibraryUpdateAt(DateTime? at) =>
      putSetting(
        Settings.lastAutoLibraryUpdateAt,
        at?.millisecondsSinceEpoch ?? 0,
      );

  Future<int> getBackgroundUpdateCursor() =>
      _read(Settings.backgroundUpdateCursor);

  Future<Result<void, AppFailure>> setBackgroundUpdateCursor(int value) =>
      putSetting(Settings.backgroundUpdateCursor, value);

  Future<BackupPreferences> backupPreferences() async {
    final lastMs = await _read(Settings.autoBackupLastAt);
    return BackupPreferences(
      enabled: await _read(Settings.autoBackupEnabled),
      intervalDays: (await _read(Settings.autoBackupIntervalDays)).clamp(1, 30),
      keep: (await _read(Settings.autoBackupKeep)).clamp(1, 30),
      lastAt: lastMs == 0 ? null : DateTime.fromMillisecondsSinceEpoch(lastMs),
    );
  }

  Future<Result<void, AppFailure>> setBackupPreferences(
    BackupPreferences preferences,
  ) {
    return guardFailure(_logger, DriftSettingsRepository._tag, () async {
      await putSetting(Settings.autoBackupEnabled, preferences.enabled);
      await putSetting(
        Settings.autoBackupIntervalDays,
        preferences.intervalDays,
      );
      await putSetting(Settings.autoBackupKeep, preferences.keep);
      await putSetting(
        Settings.autoBackupLastAt,
        preferences.lastAt?.millisecondsSinceEpoch ?? 0,
      );
    });
  }
}
