import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:sumizuri/core/utils/formatting/timestamps.dart';
import 'package:sumizuri/bootstrap/logging/log_preferences.dart';
import 'package:sumizuri/bootstrap/logging/logger_provider.dart';
import 'package:sumizuri/bootstrap/monitoring/memory_watchdog.dart';
import 'package:sumizuri/core/utils/files/file_export_helper.dart';
import 'package:sumizuri/features/settings/models/log_entry.dart';
import 'package:sumizuri/features/settings/providers/settings_providers.dart';

const _textTypeGroup = XTypeGroup(label: 'Text', extensions: ['txt']);
const _recentLogLimit = 200;

Future<String> buildDiagnosticReport(WidgetRef ref) async {
  final buffer = StringBuffer('Sumizuri diagnostic report')
    ..writeln()
    ..writeln('Created ${clockStamp(DateTime.now())}')
    ..writeln();

  try {
    final info = await PackageInfo.fromPlatform();
    buffer.writeln('App: ${info.appName} ${info.version}+${info.buildNumber}');
  } catch (_) {
    buffer.writeln('App: (version unavailable)');
  }
  final mode = kReleaseMode ? 'release' : (kProfileMode ? 'profile' : 'debug');
  buffer
    ..writeln('Build mode: $mode')
    ..writeln(
      'OS: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
    )
    ..writeln('Dart: ${Platform.version.split(' ').first}')
    ..writeln('Locale: ${PlatformDispatcher.instance.locale}');
  final view = PlatformDispatcher.instance.views.firstOrNull;
  if (view != null) {
    final size = view.physicalSize / view.devicePixelRatio;
    buffer.writeln(
      'Screen: ${size.width.round()}x${size.height.round()} '
      '@${view.devicePixelRatio}x, ${view.display.refreshRate.round()}Hz',
    );
  }

  buffer
    ..writeln()
    ..writeln('Settings')
    ..writeln('  theme: ${ref.read(themeSchemeProvider).value}')
    ..writeln(
      '  dark mode: ${ref.read(darkModePreferenceProvider).value?.name}',
    )
    ..writeln('  amoled: ${ref.read(amoledDarkProvider).value}')
    ..writeln('  reduce motion: ${ref.read(reduceMotionProvider).value}');

  final cache = PaintingBinding.instance.imageCache;
  buffer
    ..writeln()
    ..writeln('Memory')
    ..writeln('  process: ${ProcessInfo.currentRss ~/ (1024 * 1024)}MB')
    ..writeln(
      '  image cache: ${cache.currentSize} images, '
      '${(cache.currentSizeBytes / (1024 * 1024)).toStringAsFixed(1)}MB',
    )
    ..writeln()
    ..writeln('Recent routes: ${memoryBreadcrumbs.recent.join(' | ')}');

  final off = ref.read(appLoggerProvider).disabledCategories;
  buffer
    ..writeln(
      'Log categories switched off: ${off.isEmpty ? 'none' : off.join(', ')}',
    )
    ..writeln('  (available: ${logCategories.join(', ')})')
    ..writeln()
    ..writeln('Last $_recentLogLimit log entries (newest first)');

  try {
    final entries = await ref
        .read(logRepositoryProvider)
        .watchRecent(limit: _recentLogLimit)
        .first;
    if (entries.isEmpty) buffer.writeln('  (none)');
    for (final AppLogEntry e in entries) {
      buffer.writeln(
        '${clockStamp(e.timestamp)} [${e.level.name}] ${e.tag}: ${e.message}',
      );
      if (e.stackTrace != null) buffer.writeln(e.stackTrace);
    }
  } catch (error) {
    buffer.writeln('  (could not read logs: $error)');
  }
  return buffer.toString();
}

Future<String?> exportDiagnosticReport(WidgetRef ref) async {
  final report = await buildDiagnosticReport(ref);
  final stamp = fileStamp();
  return saveExportedText(
    suggestedName: 'sumizuri_diagnostics_$stamp.txt',
    content: report,
    acceptedTypeGroups: const [_textTypeGroup],
  );
}
