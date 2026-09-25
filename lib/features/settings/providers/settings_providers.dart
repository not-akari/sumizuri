import 'package:flutter_riverpod/flutter_riverpod.dart' show StreamProvider;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:sumizuri/core/theming/app_theme.dart' show AppColorScheme;
import 'package:sumizuri/bootstrap/database/db_provider.dart';
import 'package:sumizuri/bootstrap/logging/logger_provider.dart';
import 'package:sumizuri/features/settings/data/settings_repository_impl.dart';
import 'package:sumizuri/features/library/models/library_types.dart';
import 'package:sumizuri/core/navigation/nav_destination_kind.dart';
import 'package:sumizuri/core/gestures/app_gestures.dart';
import 'package:sumizuri/features/reader/models/reader_controls.dart';
import 'package:sumizuri/features/reader/models/reader_settings_types.dart';
import 'package:sumizuri/features/settings/models/app_settings_types.dart';
import 'package:sumizuri/features/settings/registry/setting_def.dart';
import 'package:sumizuri/features/settings/registry/settings_catalog.dart';
import 'package:sumizuri/features/settings/data/settings_repository.dart';

import 'package:sumizuri/features/profile/providers/profile_providers.dart';

export 'package:sumizuri/features/settings/providers/library_settings_providers.dart';

part 'settings_providers.g.dart';

@Riverpod(keepAlive: true)
SettingsRepository settingsRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  final logger = ref.watch(appLoggerProvider);
  final profileId = ref.watch(currentProfileIdProvider);
  return DriftSettingsRepository(db, logger, profileId: profileId);
}

@riverpod
Stream<bool> onboardingCompleted(Ref ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return repository.watchOnboardingCompleted();
}

@riverpod
Stream<AppLibraryMode> libraryMode(Ref ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return repository.watchLibraryMode();
}

@riverpod
Stream<double> backgroundIntensity(Ref ref) {
  return ref.watch(settingsRepositoryProvider).watchBackgroundIntensity();
}

/// The strength being tried while its slider is dragged, before it is saved.
class BackgroundLookDraft {
  const BackgroundLookDraft({this.intensity});

  final double? intensity;
}

@riverpod
class BackgroundLookPreview extends _$BackgroundLookPreview {
  @override
  BackgroundLookDraft build() {
    // A saved value replaces the draft.
    ref.listen(backgroundIntensityProvider, (_, next) {
      if (next.hasValue) state = const BackgroundLookDraft();
    });
    return const BackgroundLookDraft();
  }

  void setIntensity(double? value) =>
      state = BackgroundLookDraft(intensity: value);
}

/// How list rows are drawn. Not code-generated: a plain stream of the setting.
final listStyleProvider = StreamProvider<AppListStyle>(
  (ref) =>
      ref.watch(settingsRepositoryProvider).watchSetting(Settings.listStyle),
);

/// How titles are laid out in the library and in tracker lists.
final libraryDisplayStyleProvider = StreamProvider<LibraryDisplayStyle>(
  (ref) => ref
      .watch(settingsRepositoryProvider)
      .watchSetting(Settings.libraryDisplayStyle),
);

/// How each list of titles is laid out, one setting for each place it shows.
final updatesDisplayStyleProvider = StreamProvider<LibraryDisplayStyle>(
  (ref) => ref
      .watch(settingsRepositoryProvider)
      .watchSetting(Settings.updatesDisplayStyle),
);

final historyDisplayStyleProvider = StreamProvider<LibraryDisplayStyle>(
  (ref) => ref
      .watch(settingsRepositoryProvider)
      .watchSetting(Settings.historyDisplayStyle),
);

final homeContinueStyleProvider = StreamProvider<DashboardShelfStyle>(
  (ref) => ref
      .watch(settingsRepositoryProvider)
      .watchSetting(Settings.homeContinueStyle),
);

final homeUpdatesStyleProvider = StreamProvider<DashboardShelfStyle>(
  (ref) => ref
      .watch(settingsRepositoryProvider)
      .watchSetting(Settings.homeUpdatesStyle),
);

final homeHistoryStyleProvider = StreamProvider<DashboardShelfStyle>(
  (ref) => ref
      .watch(settingsRepositoryProvider)
      .watchSetting(Settings.homeHistoryStyle),
);

const backgroundIntensityRange = (min: 0.0, max: 1.5);

@riverpod
double effectiveBackgroundIntensity(Ref ref) {
  final value =
      ref.watch(backgroundLookPreviewProvider).intensity ??
      ref.watch(backgroundIntensityProvider).value ??
      1.0;
  return value.clamp(
    backgroundIntensityRange.min,
    backgroundIntensityRange.max,
  );
}

@riverpod
Stream<Set<AppColorScheme>> hiddenThemePresets(Ref ref) {
  return ref.watch(settingsRepositoryProvider).watchHiddenThemePresets();
}

@riverpod
Stream<String> themeScheme(Ref ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return repository.watchThemeScheme();
}

@riverpod
Stream<AppDarkModePreference> darkModePreference(Ref ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return repository.watchDarkModePreference();
}

@riverpod
Stream<bool> amoledDark(Ref ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return repository.watchAmoledDark();
}

@riverpod
Stream<ColorIntensity> colorIntensity(Ref ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return repository.watchColorIntensity();
}

@riverpod
Stream<List<NavDestinationKind>> navDestinations(Ref ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  final mode = ref.watch(libraryModeProvider).value ?? AppLibraryMode.unified;
  final enabledTypes = ref.watch(enabledMediaTypesProvider).orMangaOnly;
  return repository.watchNavDestinations().map(
    (stored) => reconcileNavDestinations(stored, mode, enabledTypes),
  );
}

@riverpod
Stream<Set<MediaType>> enabledMediaTypes(Ref ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return repository.watchEnabledMediaTypes();
}

/// Fallback returning manga-only if stream has not emitted or failed.
extension EnabledMediaTypesFallback on AsyncValue<Set<MediaType>> {
  Set<MediaType> get orMangaOnly => value ?? const {MediaType.manga};
}

@riverpod
Stream<ReaderMode> globalReaderMode(Ref ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return repository.watchReaderMode();
}

@riverpod
Stream<ReaderScaleType> globalReaderScaleType(Ref ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return repository.watchReaderScaleType();
}

@riverpod
Stream<ReaderBackground> globalReaderBackground(Ref ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return repository.watchReaderBackground();
}

@riverpod
Stream<ReaderPageGap> globalReaderPageGap(Ref ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return repository.watchReaderPageGap();
}

@riverpod
Stream<bool> readerKeepScreenOn(Ref ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return repository.watchReaderKeepScreenOn();
}

@riverpod
Stream<bool> readerVolumeKeys(Ref ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return repository.watchReaderVolumeKeys();
}

@riverpod
Stream<bool> readerVerticalNavigator(Ref ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return repository.watchReaderVerticalNavigator();
}

@riverpod
Stream<bool> boolSetting(Ref ref, SettingDef<bool> def) =>
    ref.watch(settingsRepositoryProvider).watchSetting(def);

@riverpod
Stream<int> intSetting(Ref ref, SettingDef<int> def) =>
    ref.watch(settingsRepositoryProvider).watchSetting(def);

@riverpod
Stream<String> stringSetting(Ref ref, SettingDef<String> def) =>
    ref.watch(settingsRepositoryProvider).watchSetting(def);

@riverpod
Stream<AppGestures> appGestures(Ref ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return repository.watchAppGestures().map(AppGestures.fromJsonString);
}

@riverpod
Stream<ReaderControls> readerControls(Ref ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return repository.watchReaderControls().map(ReaderControls.fromJsonString);
}

@riverpod
Stream<bool> globalReaderInvertTaps(Ref ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return repository.watchReaderInvertTaps();
}

@riverpod
Stream<AppNavStyle> navStyle(Ref ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return repository.watchNavStyle();
}

@riverpod
Stream<bool> incognitoMode(Ref ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return repository.watchIncognito();
}

@riverpod
Stream<int> libraryUpdateSkip(Ref ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return repository.watchLibraryUpdateSkip();
}

@riverpod
Stream<bool> autoLibraryUpdateWifiOnly(Ref ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return repository.watchAutoLibraryUpdateWifiOnly();
}

@riverpod
Stream<bool> appLockEnabled(Ref ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return repository.watchAppLockEnabled();
}

@riverpod
Stream<bool> appLockUseBiometric(Ref ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return repository.watchAppLockUseBiometric();
}

@riverpod
Stream<int> appLockGracePeriodMinutes(Ref ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return repository.watchAppLockGracePeriodMinutes();
}

@riverpod
Stream<bool> notificationsEnabled(Ref ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return repository.watchNotificationsEnabled();
}

@riverpod
Stream<bool> reduceMotion(Ref ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return repository.watchReduceMotion();
}

@riverpod
Stream<ReaderDualPageMode> globalReaderDualPageMode(Ref ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return repository.watchReaderDualPageMode();
}

@riverpod
Stream<String?> downloadDirectoryPath(Ref ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return repository.watchDownloadDirectoryPath();
}

@riverpod
Stream<int> networkTimeoutSeconds(Ref ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return repository.watchNetworkTimeoutSeconds();
}

@riverpod
Stream<String?> networkUserAgent(Ref ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return repository.watchNetworkUserAgent();
}

@riverpod
Stream<ReaderFontFamily> novelFontFamily(Ref ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return repository.watchNovelFontFamily();
}

@riverpod
Stream<double> novelFontSize(Ref ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return repository.watchNovelFontSize();
}

@riverpod
Stream<double> novelLineHeight(Ref ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return repository.watchNovelLineHeight();
}

@riverpod
Stream<double> novelParagraphSpacing(Ref ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return repository.watchNovelParagraphSpacing();
}

@riverpod
Stream<bool> checkForUpdatesOnStartup(Ref ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return repository.watchCheckForUpdatesOnStartup();
}

@riverpod
Stream<ReaderColumnWidth> globalReaderColumnWidth(Ref ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return repository.watchReaderColumnWidth();
}

@riverpod
Stream<ReaderImageQuality> globalReaderImageQuality(Ref ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return repository.watchReaderImageQuality();
}

@riverpod
Stream<bool> showPerformanceOverlay(Ref ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return repository.watchShowPerformanceOverlay();
}
