import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/bootstrap/logging/app_logger.dart';
import 'package:sumizuri/features/extensions/data/extension_service.dart';
import 'package:sumizuri/features/extensions/providers/extension_providers.dart';
import 'package:sumizuri/features/extensions/models/installed_source.dart';
import 'package:sumizuri/features/extensions/models/m_entry.dart';
import 'package:sumizuri/features/extensions/models/m_source_info.dart';

class SourceResults {
  const SourceResults({required this.source, required this.entries});

  final AppInstalledSource source;
  final List<MEntry> entries;
}

/// How long one source gets to answer before it is skipped.
const _perSourceTimeout = Duration(seconds: 25);

/// Sources searched at the same moment: each one boots its own engine, so
/// starting dozens at once is slow and can starve the ones that would answer.
const _searchConcurrency = 4;

/// Searches every source, handing each source's results over as soon as it
/// answers instead of waiting for the slowest. A source that fails, times
/// out, or finds nothing is simply skipped, so one dead site can never hold
/// the whole search up.
Future<void> searchSourcesStreaming(
  ProviderContainer container,
  AppLogger logger,
  List<AppInstalledSource> sources,
  String query, {
  required void Function(SourceResults results) onResults,
  required void Function(int done, int total) onProgress,
  required bool Function() isCancelled,
}) async {
  var next = 0;
  var done = 0;
  onProgress(0, sources.length);

  Future<void> worker() async {
    while (!isCancelled()) {
      final index = next++;
      if (index >= sources.length) return;
      final source = sources[index];
      try {
        final result = await _searchOne(container, logger, source, query);
        if (isCancelled()) return;
        if (result.entries.isNotEmpty) onResults(result);
      } finally {
        done++;
        if (!isCancelled()) onProgress(done, sources.length);
      }
    }
  }

  final workers = sources.length < _searchConcurrency
      ? sources.length
      : _searchConcurrency;
  await Future.wait([for (var i = 0; i < workers; i++) worker()]);
}

Future<SourceResults> _searchOne(
  ProviderContainer container,
  AppLogger logger,
  AppInstalledSource source,
  String query,
) async {
  final empty = SourceResults(source: source, entries: const []);
  ExtensionService? service;
  try {
    return await Future(() async {
      final loaded = await container.read(sourceLoaderProvider)(
        container,
        MSourceInfo.fromInstalledSource(source),
        source,
        logger: logger,
      );
      service = loaded.valueOrNull;
      if (service == null) return empty;
      final found = await service!.search(query);
      return SourceResults(
        source: source,
        entries: found.valueOrNull ?? const [],
      );
    }).timeout(_perSourceTimeout, onTimeout: () => empty);
  } catch (error) {
    logger.warning(
      'Global search on ${source.name} failed: $error',
      tag: 'global_search',
    );
    return empty;
  } finally {
    // Also frees a source that timed out and is still busy.
    try {
      await service?.dispose();
    } catch (_) {}
  }
}
