import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/features/library/providers/library_providers.dart';
import 'package:sumizuri/features/settings/registry/settings_catalog.dart';
import 'package:sumizuri/features/settings/providers/settings_providers.dart';

Future<bool> hasUnmeteredConnection() async {
  final results = await Connectivity().checkConnectivity();
  return results.any(
    (result) =>
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.ethernet,
  );
}

Future<bool> canAutoDownloadNow(ProviderContainer container) async {
  final wifiOnly = container.read(downloadsWifiOnlyProvider).value ?? true;
  if (!wifiOnly) return true;
  return hasUnmeteredConnection();
}

/// Keeps only as many chapters as the series may download alone, its own limit first.
Future<List<T>> capAutoDownloadChapters<T>(
  List<T> chapters,
  ProviderContainer container, {
  required int libraryEntryId,
}) async {
  final overrides = await container
      .read(libraryRepositoryProvider)
      .watchEntryOverrides(libraryEntryId)
      .first;
  final limit = overrides.resolve(
    Settings.autoDownloadChapterLimit,
    container.read(autoDownloadChapterLimitProvider).value ?? 0,
  );
  if (limit <= 0 || chapters.length <= limit) return chapters;
  return chapters.take(limit).toList();
}
