import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/bootstrap/logging/app_logger.dart';
import 'package:sumizuri/features/extensions/providers/extension_providers.dart';
import 'package:sumizuri/features/extensions/models/installed_source.dart';
import 'package:sumizuri/features/extensions/models/m_entry.dart';
import 'package:sumizuri/features/extensions/models/m_source_info.dart';

class SourceResults {
  const SourceResults({required this.source, required this.entries});

  final AppInstalledSource source;
  final List<MEntry> entries;
}

/// Searches every source at once. A source that fails gives no results.
Future<List<SourceResults>> searchSources(
  ProviderContainer container,
  AppLogger logger,
  List<AppInstalledSource> sources,
  String query,
) async {
  final results = await Future.wait(
    sources.map((source) async {
      final loaded = await container.read(sourceLoaderProvider)(
        container,
        MSourceInfo.fromInstalledSource(source),
        source,
        logger: logger,
      );
      final service = loaded.valueOrNull;
      if (service == null) {
        return SourceResults(source: source, entries: const []);
      }
      try {
        final found = await service.search(query);
        return SourceResults(
          source: source,
          entries: found.valueOrNull ?? const [],
        );
      } finally {
        await service.dispose();
      }
    }),
  );
  return [
    for (final result in results)
      if (result.entries.isNotEmpty) result,
  ];
}
