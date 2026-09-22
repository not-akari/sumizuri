import 'package:sumizuri/core/theming/app_theme.dart' show AppColorScheme;
import 'package:sumizuri/features/settings/models/backup_preferences.dart';
import 'package:sumizuri/core/errors/app_failure.dart';
import 'package:sumizuri/core/errors/result.dart';
import 'package:sumizuri/features/library/models/category_smart_rule.dart';
import 'package:sumizuri/features/library/models/dashboard_section_kind.dart';
import 'package:sumizuri/features/library/models/library_types.dart';
import 'package:sumizuri/core/navigation/nav_destination_kind.dart';
import 'package:sumizuri/features/reader/models/reader_settings_types.dart';
import 'package:sumizuri/features/settings/models/app_settings_types.dart';
import 'package:sumizuri/features/settings/registry/setting_def.dart';

abstract interface class SettingsRepository {
  Stream<bool> watchOnboardingCompleted();

  Future<Result<void, AppFailure>> completeOnboarding();

  Future<Result<void, AppFailure>> resetOnboarding();

  Stream<AppLibraryMode> watchLibraryMode();

  Future<Result<void, AppFailure>> setLibraryMode(AppLibraryMode mode);

  Stream<Set<MediaType>> watchEnabledMediaTypes();

  Future<Result<void, AppFailure>> setEnabledMediaTypes(Set<MediaType> types);

  Stream<String> watchThemeScheme();

  Future<Result<void, AppFailure>> setThemeScheme(String schemeName);

  Stream<Set<AppColorScheme>> watchHiddenThemePresets();

  Future<Result<void, AppFailure>> setHiddenThemePresets(
    Set<AppColorScheme> presets,
  );

  Stream<double> watchBackgroundIntensity();

  Future<Result<void, AppFailure>> setBackgroundIntensity(double value);

  Stream<AppDarkModePreference> watchDarkModePreference();

  Future<Result<void, AppFailure>> setDarkModePreference(
    AppDarkModePreference preference,
  );

  Stream<bool> watchAmoledDark();

  Future<Result<void, AppFailure>> setAmoledDark(bool enabled);

  Stream<ColorIntensity> watchColorIntensity();

  Future<Result<void, AppFailure>> setColorIntensity(ColorIntensity intensity);

  Stream<List<NavDestinationKind>> watchNavDestinations();

  Future<Result<void, AppFailure>> setNavDestinations(
    List<NavDestinationKind> destinations,
  );

  Stream<List<DashboardSectionKind>> watchDashboardSectionOrder();

  Future<Result<void, AppFailure>> setDashboardSectionOrder(
    List<DashboardSectionKind> order,
  );

  Stream<ReaderMode> watchReaderMode();

  Future<Result<void, AppFailure>> setReaderMode(ReaderMode mode);

  Stream<ReaderScaleType> watchReaderScaleType();

  Future<Result<void, AppFailure>> setReaderScaleType(
    ReaderScaleType scaleType,
  );

  Stream<ReaderBackground> watchReaderBackground();

  Future<Result<void, AppFailure>> setReaderBackground(
    ReaderBackground background,
  );

  Stream<ReaderPageGap> watchReaderPageGap();

  Future<Result<void, AppFailure>> setReaderPageGap(ReaderPageGap gap);

  Stream<bool> watchReaderKeepScreenOn();

  Future<Result<void, AppFailure>> setReaderKeepScreenOn(bool enabled);

  Stream<bool> watchReaderVolumeKeys();

  Future<Result<void, AppFailure>> setReaderVolumeKeys(bool enabled);

  Stream<bool> watchReaderVerticalNavigator();

  Future<Result<void, AppFailure>> setReaderVerticalNavigator(bool enabled);

  Stream<String?> watchAppGestures();

  Future<Result<void, AppFailure>> setAppGestures(String? json);

  Stream<String?> watchReaderControls();

  Future<Result<void, AppFailure>> setReaderControls(String? json);

  Stream<bool> watchReaderInvertTaps();

  Future<Result<void, AppFailure>> setReaderInvertTaps(bool invert);

  Stream<bool> watchChapterSortAscending();

  Future<Result<void, AppFailure>> setChapterSortAscending(bool ascending);

  Stream<bool> watchHideAllCategoryChip();

  Future<Result<void, AppFailure>> setHideAllCategoryChip(bool hide);

  Stream<bool> watchHideUncategorizedCategoryChip();

  Future<Result<void, AppFailure>> setHideUncategorizedCategoryChip(bool hide);

  Stream<CategorySortField> watchLibrarySortField();

  Future<Result<void, AppFailure>> setLibrarySortField(CategorySortField field);

  Stream<bool> watchLibrarySortAscending();

  Future<Result<void, AppFailure>> setLibrarySortAscending(bool ascending);

  Stream<bool> watchDownloadsWifiOnly();

  Future<Result<void, AppFailure>> setDownloadsWifiOnly(bool wifiOnly);

  Stream<int> watchAutoDownloadChapterLimit();

  Future<Result<void, AppFailure>> setAutoDownloadChapterLimit(int limit);

  Stream<int> watchKeepDownloadsBehind();

  Future<Result<void, AppFailure>> setKeepDownloadsBehind(int chapters);

  Stream<int> watchDownloadDelaySeconds();

  Future<Result<void, AppFailure>> setDownloadDelaySeconds(int seconds);

  Stream<bool> watchCategoriesEnabled();

  Future<Result<void, AppFailure>> setCategoriesEnabled(bool enabled);

  Stream<bool> watchAutoDownloadOnLibraryUpdate();

  Future<Result<void, AppFailure>> setAutoDownloadOnLibraryUpdate(bool enabled);

  Stream<bool> watchAutoDownloadOnAddToLibrary();

  Future<Result<void, AppFailure>> setAutoDownloadOnAddToLibrary(bool enabled);

  Stream<AppNavStyle> watchNavStyle();

  Future<Result<void, AppFailure>> setNavStyle(AppNavStyle style);

  Stream<ChapterListLayout> watchChapterListLayout();

  Future<Result<void, AppFailure>> setChapterListLayout(
    ChapterListLayout layout,
  );

  Stream<bool> watchReduceMotion();

  Future<Result<void, AppFailure>> setReduceMotion(bool reduce);

  Stream<ReaderDualPageMode> watchReaderDualPageMode();

  Future<Result<void, AppFailure>> setReaderDualPageMode(
    ReaderDualPageMode mode,
  );

  Stream<String?> watchDownloadDirectoryPath();

  Future<Result<void, AppFailure>> setDownloadDirectoryPath(String? path);

  Stream<LibraryGridTileSize> watchLibraryGridTileSize();

  Future<Result<void, AppFailure>> setLibraryGridTileSize(
    LibraryGridTileSize size,
  );

  Stream<int> watchNetworkTimeoutSeconds();

  Future<Result<void, AppFailure>> setNetworkTimeoutSeconds(int seconds);

  Stream<String?> watchNetworkUserAgent();

  Future<Result<void, AppFailure>> setNetworkUserAgent(String? userAgent);

  Stream<ReaderFontFamily> watchNovelFontFamily();

  Future<Result<void, AppFailure>> setNovelFontFamily(ReaderFontFamily family);

  Stream<double> watchNovelFontSize();

  Future<Result<void, AppFailure>> setNovelFontSize(double size);

  Stream<double> watchNovelLineHeight();

  Future<Result<void, AppFailure>> setNovelLineHeight(double height);

  Stream<double> watchNovelParagraphSpacing();

  Future<Result<void, AppFailure>> setNovelParagraphSpacing(double spacing);

  Stream<bool> watchCheckForUpdatesOnStartup();

  Future<Result<void, AppFailure>> setCheckForUpdatesOnStartup(bool enabled);

  Stream<ReaderColumnWidth> watchReaderColumnWidth();

  Future<Result<void, AppFailure>> setReaderColumnWidth(
    ReaderColumnWidth width,
  );

  Stream<ReaderImageQuality> watchReaderImageQuality();

  Future<Result<void, AppFailure>> setReaderImageQuality(
    ReaderImageQuality quality,
  );

  Stream<int> watchAutoLibraryUpdateIntervalHours();

  Future<Result<void, AppFailure>> setAutoLibraryUpdateIntervalHours(int hours);

  Stream<T> watchSetting<T>(SettingDef<T> def);

  Future<Result<void, AppFailure>> putSetting<T>(SettingDef<T> def, T value);

  Stream<bool> watchIncognito();

  Future<Result<void, AppFailure>> setIncognito(bool enabled);

  Stream<int> watchLibraryUpdateSkip();

  Future<Result<void, AppFailure>> setLibraryUpdateSkip(int mask);

  Stream<bool> watchAutoLibraryUpdateWifiOnly();

  Future<Result<void, AppFailure>> setAutoLibraryUpdateWifiOnly(bool wifiOnly);

  Future<DateTime?> getLastAutoLibraryUpdateAt();

  Future<Result<void, AppFailure>> setLastAutoLibraryUpdateAt(DateTime? at);

  Future<int> getBackgroundUpdateCursor();

  Future<Result<void, AppFailure>> setBackgroundUpdateCursor(int value);

  Stream<bool> watchAppLockEnabled();

  Future<Result<void, AppFailure>> setAppLockEnabled(bool enabled);

  Stream<bool> watchAppLockUseBiometric();

  Future<Result<void, AppFailure>> setAppLockUseBiometric(bool enabled);

  Stream<int> watchAppLockGracePeriodMinutes();

  Future<Result<void, AppFailure>> setAppLockGracePeriodMinutes(int minutes);

  Stream<bool> watchNotificationsEnabled();

  Future<Result<void, AppFailure>> setNotificationsEnabled(bool enabled);

  Stream<bool> watchShowPerformanceOverlay();

  Future<Result<void, AppFailure>> setShowPerformanceOverlay(bool enabled);

  Future<BackupPreferences> backupPreferences();

  Future<Result<void, AppFailure>> setBackupPreferences(
    BackupPreferences preferences,
  );
}
