import 'dart:async';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/gestures.dart' show GestureBinding;
import 'package:flutter/material.dart';

// ignore: depend_on_referenced_packages
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/core/platform/link_registration.dart';
import 'package:sumizuri/core/navigation/shortcut_link.dart';
import 'package:sumizuri/features/repos/flows/repo_link.dart';
import 'package:sumizuri/bootstrap/startup/startup_problem_app.dart';
import 'package:sumizuri/bootstrap/startup/startup_timer.dart';
import 'package:sumizuri/features/settings/registry/settings_catalog.dart';
import 'package:sumizuri/core/platform/refresh_rate.dart';
import 'package:sumizuri/core/theming/theme_shapes.dart';
import 'package:sumizuri/features/theme_editor/data/custom_font_store.dart';
import 'package:sumizuri/features/library/flows/download_queue.dart';
import 'package:sumizuri/bootstrap/logging/app_logger.dart';
import 'package:sumizuri/features/extensions/data/engines/js/js_extension_service.dart';
import 'package:sumizuri/bootstrap/logging/logger_provider.dart';
import 'package:sumizuri/bootstrap/monitoring/run_heartbeat.dart';
import 'package:sumizuri/bootstrap/background/auto_backup_runner.dart';
import 'package:sumizuri/bootstrap/monitoring/frame_watchdog.dart';
import 'package:sumizuri/bootstrap/startup/update_startup_check.dart';
import 'package:sumizuri/bootstrap/monitoring/memory_watchdog.dart';
import 'package:sumizuri/core/theming/app_scroll_behavior.dart';
import 'package:sumizuri/core/navigation/snack_bar_hero_guard.dart';
import 'package:sumizuri/core/theming/ambient_scope.dart';
import 'package:sumizuri/core/theming/app_theme.dart';
import 'package:sumizuri/core/widgets/feedback/performance_hud.dart';
import 'package:sumizuri/core/widgets/feedback/startup_debug_log.dart';
import 'package:sumizuri/core/window/back_navigation_shortcuts.dart';
import 'package:sumizuri/core/window/native_title_bar.dart';

import 'package:sumizuri/features/extensions/data/engines/json/json_engine_prelude.dart';
import 'package:sumizuri/features/extensions/render/render_broker.dart';
import 'package:sumizuri/features/settings/models/app_settings_types.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';
import 'package:sumizuri/bootstrap/database/db_migration_gate.dart';
import 'package:sumizuri/bootstrap/storage/app_paths.dart';
import 'package:sumizuri/bootstrap/startup/data_location_app.dart';
import 'package:sumizuri/bootstrap/database/db_recovery_app.dart';
import 'package:sumizuri/bootstrap/database/db_upgrade_check.dart';
import 'package:sumizuri/features/settings/data/db_file_backup.dart';
import 'package:sumizuri/core/navigation/app_lock_gate.dart';
import 'package:sumizuri/bootstrap/background/auto_library_update_scheduler.dart';
import 'package:sumizuri/features/sync/background/auto_sync_runner.dart';
import 'package:sumizuri/features/trackers/background/tracker_flush_runner.dart';
import 'package:sumizuri/features/sync/background/background_sync.dart';
import 'package:sumizuri/core/widgets/feedback/loading_screen.dart';
import 'package:sumizuri/core/navigation/app_shell.dart';
import 'package:sumizuri/features/onboarding/pages/onboarding_screen.dart';
import 'package:sumizuri/features/settings/providers/settings_providers.dart';
import 'package:sumizuri/features/theme_editor/data/theme_editor_providers.dart';
import 'package:sumizuri/features/translations/data/dynamic_localizations.dart';
import 'package:sumizuri/features/translations/providers/translation_providers.dart';

Timer? _slowStartTimer;
bool _settingsReadyMarked = false;

// If start-up is not done after this long, a page shows where it is stuck.
void _watchForSlowStart() {
  _slowStartTimer?.cancel();
  _slowStartTimer = Timer(const Duration(seconds: 15), () {
    if (StartupTimer.instance.finished) return;
    FlutterNativeSplash.remove();
    runApp(StartupProblemApp.slow(details: StartupTimer.instance.progress));
  });
}

// Runs a way of starting the app and shows the reason if it throws, not a forever splash.
Future<void> _launch(Future<void> Function() start) async {
  _watchForSlowStart();
  try {
    await start();
  } on Object catch (error, stack) {
    _slowStartTimer?.cancel();
    FlutterNativeSplash.remove();
    runApp(
      StartupProblemApp.failed(
        details: '$error\n\n$stack\n\n${StartupTimer.instance.progress}',
        onRetry: () => unawaited(_launch(start)),
      ),
    );
  }
}

// What the program was started with. A link that starts the desktop app arrives here.
List<String> _launchArguments = const [];

void main(List<String> arguments) {
  _launchArguments = arguments;
  runZonedGuarded(
    () async {
      StartupTimer.instance.start();
      final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
      // Touches arrive faster than frames, so they are resampled to the frame time.
      GestureBinding.instance.resamplingEnabled = true;
      FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

      final firstRun = await isFirstRun();
      StartupTimer.instance.mark('first run check');
      if (firstRun) {
        FlutterNativeSplash.remove();
        _slowStartTimer?.cancel();
        runApp(
          DataLocationApp(
            onDone: (downloads) => unawaited(
              _launch(() async {
                // A folder with data from an older version is checked and backed up before it opens.
                final recovery = await _recoveryScreen();
                if (recovery != null) {
                  _slowStartTimer?.cancel();
                  FlutterNativeSplash.remove();
                  runApp(recovery);
                } else {
                  await _startApp(downloadsPath: downloads);
                }
              }),
            ),
          ),
        );
      } else {
        _watchForSlowStart();
        final recovery = await _recoveryScreen();
        StartupTimer.instance.mark('database check');
        if (recovery != null) {
          _slowStartTimer?.cancel();
          FlutterNativeSplash.remove();
          runApp(recovery);
        } else {
          await _launch(_startApp);
        }
      }
      if (isDesktopWindowPlatform) {
        doWhenWindowReady(() {
          appWindow.minSize = const Size(480, 360);
          appWindow.size = const Size(1280, 720);
          appWindow.alignment = Alignment.center;
          appWindow.title = 'Sumizuri';
          appWindow.show();
        });
      }
    },
    (error, stackTrace) {
      debugPrint('Uncaught zone error: $error\n$stackTrace');
    },
  );
}

Future<Widget?> _recoveryScreen() async {
  Widget screen(int version, [Object? error]) => DbRecoveryApp(
    version: version,
    error: error == null ? null : '$error',
    onReset: _startApp,
  );

  final tooOld = await unsupportedDatabaseVersion();
  if (tooOld != null) return screen(tooOld);

  final pending = await pendingMigrationFromVersion();
  if (pending == null) return null;
  final failure = await upgradeDatabaseNow();
  return failure == null ? null : screen(pending, failure);
}

// Says so in the log if the last run stopped without closing, such as when the system ended it.
Future<void> _watchForUncleanExit(AppLogger logger) async {
  try {
    final heartbeat = RunHeartbeat(
      file: await runStateFile(),
      routes: () => memoryBreadcrumbs.recent,
      engines: () => JsExtensionService.liveCount,
    );
    final report = describePreviousRun(
      await heartbeat.readPrevious(),
      debugBuild: kDebugMode,
    );
    // A warning either way: only warnings and errors are kept in the log.
    if (report != null) logger.warning(report.message, tag: 'crash');
    await heartbeat.start();
  } catch (_) {
    // Only a note. Never a reason not to start.
  }
}

Future<void> _startApp({String? downloadsPath}) async {
  final container = ProviderContainer();
  final logger = container.read(appLoggerProvider);

  // Ordered startup steps timed between splash and first frame.
  await runStartupSteps([
    StartupStep('services', () async {
      if (downloadsPath != null) {
        await container
            .read(settingsRepositoryProvider)
            .setDownloadDirectoryPath(downloadsPath);
      }
      container.read(memoryWatchdogProvider).start();
      container.read(frameWatchdogProvider).start();
    }),
    StartupStep('previous run check', () async {
      await _watchForUncleanExit(logger).timeout(
        const Duration(seconds: 5),
        onTimeout: () => logger.warning(
          'The check of the previous run took too long and was skipped.',
          tag: 'startup',
        ),
      );
    }),
    StartupStep('source engine files', () async {
      FlutterError.onError = (details) {
        logger.error(
          'Uncaught Flutter error',
          error: details.exception,
          stackTrace: details.stack,
        );
        FlutterError.presentError(details);
      };
      await loadJsonEnginePrelude();
    }),
    StartupStep('background sync', () async {
      RenderBroker.instance.start();
      // Background work setup can be slow on some phones, and the app does not need it to open.
      try {
        await initializeBackgroundSync().timeout(const Duration(seconds: 6));
      } on Object catch (error) {
        logger.warning('Background sync did not start: $error', tag: 'startup');
      }
    }),
  ]);

  runApp(
    UncontrolledProviderScope(container: container, child: const SumizuriApp()),
  );
  container.listen(boolSettingProvider(Settings.displayHighRefreshRate), (
    _,
    next,
  ) async {
    final report = await setHighRefreshRate(next.value ?? true);
    if (report != null) logger.info(report, tag: 'display');
  }, fireImmediately: true);
  unawaited(registerLinkHandler());
  // Downloads that were still going when the app was closed come back.
  unawaited(container.read(downloadQueueProvider.notifier).restore());
}

final _navigatorKey = GlobalKey<NavigatorState>();

class SumizuriApp extends ConsumerWidget {
  const SumizuriApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schemeName = ref.watch(themeSchemeProvider).value;
    final customTheme = ref.watch(activeCustomThemeProvider);
    ref.watch(customFontsProvider);
    final scheme = AppColorScheme.values.firstWhere(
      (s) => s.name == schemeName,
      orElse: () => AppColorScheme.sumizuriInk,
    );
    final darkModePreference =
        ref.watch(darkModePreferenceProvider).value ??
        AppDarkModePreference.system;
    final amoled = ref.watch(amoledDarkProvider).value ?? false;
    final intensity =
        ref.watch(colorIntensityProvider).value ?? ColorIntensity.medium;
    final darkVariant = amoled ? DarkVariant.amoled : DarkVariant.standard;
    final reduceMotion = ref.watch(reduceMotionProvider).value ?? false;
    final backgroundIntensity = ref.watch(effectiveBackgroundIntensityProvider);
    final showPerformanceOverlay =
        ref.watch(showPerformanceOverlayProvider).value ?? false;

    final activeLocaleCode = ref.watch(appLocaleProvider).value;
    final activeLocale = activeLocaleCode != null
        ? parseLocale(activeLocaleCode)
        : null;
    final sumizuriDelegate = ref.watch(sumizuriLocalizationsDelegateProvider);

    return MaterialApp(
      navigatorKey: _navigatorKey,
      navigatorObservers: [memoryBreadcrumbs, SnackBarHeroGuard()],
      title: 'Sumizuri',
      scrollBehavior: AppScrollBehavior(),
      locale: activeLocale,
      localizationsDelegates: [
        sumizuriDelegate,
        ...AppLocalizations.localizationsDelegates,
      ],
      supportedLocales: [...AppLocalizations.supportedLocales, ?activeLocale],
      theme: customTheme == null
          ? AppTheme.light(scheme, intensity: intensity)
          : AppTheme.custom(
              customTheme,
              brightness: Brightness.light,
              intensity: intensity,
            ),
      darkTheme: customTheme == null
          ? AppTheme.dark(scheme, darkVariant, intensity: intensity)
          : AppTheme.custom(
              customTheme,
              brightness: Brightness.dark,
              variant: darkVariant,
              intensity: intensity,
            ),
      themeAnimationDuration: Duration.zero,
      themeMode: switch (darkModePreference) {
        AppDarkModePreference.system => ThemeMode.system,
        AppDarkModePreference.light => ThemeMode.light,
        AppDarkModePreference.dark => ThemeMode.dark,
      },
      debugShowCheckedModeBanner: false,

      builder: (context, child) {
        if (isDesktopWindowPlatform) {
          final isDark = switch (darkModePreference) {
            AppDarkModePreference.dark => true,
            AppDarkModePreference.light => false,
            AppDarkModePreference.system =>
              WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                  Brightness.dark,
          };
          unawaited(setDarkTitleBar(isDark));
        }

        final mediaQuery = MediaQuery.of(context);
        final textScale = context.options.typography.textScale;
        return MediaQuery(
          data: mediaQuery.copyWith(
            disableAnimations: reduceMotion || mediaQuery.disableAnimations,
            textScaler: textScale == 1
                ? mediaQuery.textScaler
                : TextScaler.linear(mediaQuery.textScaler.scale(1) * textScale),
          ),
          child: AmbientScope(
            intensity: backgroundIntensity,
            child: StartupDebugLog(
              enabled: kDebugMode,
              child: PerformanceHud(
                enabled: showPerformanceOverlay,
                child: BackNavigationShortcuts(
                  navigatorKey: _navigatorKey,
                  // Overlays the lock screen above current route at any depth.
                  child: AppLockGate(child: child!),
                ),
              ),
            ),
          ),
        );
      },
      home: const DbMigrationGate(child: _AppHome()),
    );
  }
}

class _AppHome extends ConsumerWidget {
  const _AppHome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingCompleted = ref.watch(onboardingCompletedProvider);

    final child = onboardingCompleted.when(
      loading: () => const LoadingScreen(),
      error: (error, stackTrace) {
        FlutterNativeSplash.remove();
        return Scaffold(
          body: Center(
            child: Text(
              AppLocalizations.of(context)!.settingsLoadFailed(error),
            ),
          ),
        );
      },
      data: (completed) {
        // Marks the transition from database initialization to widget tree build.
        if (!_settingsReadyMarked) {
          _settingsReadyMarked = true;
          StartupTimer.instance.mark('settings ready');
        }
        FlutterNativeSplash.remove();
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => StartupTimer.instance.finish(ref.read(appLoggerProvider)),
        );
        return completed
            ? const RepoLinkPrompt(
                child: UpdateStartupCheck(
                  child: AutoBackupRunner(
                    child: AutoSyncRunner(
                      child: TrackerFlushRunner(
                        child: AutoLibraryUpdateScheduler(child: AppShell()),
                      ),
                    ),
                  ),
                ),
              )
            : const OnboardingScreen();
      },
    );

    return RepoLinkCatcher(
      launchArguments: _launchArguments,
      child: ShortcutLinkCatcher(
        launchArguments: _launchArguments,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) =>
              FadeTransition(opacity: animation, child: child),
          child: KeyedSubtree(
            key: ValueKey(onboardingCompleted.value),
            child: child,
          ),
        ),
      ),
    );
  }
}
