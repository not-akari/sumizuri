// Automatically attaches freshly imported titles to installed sources if details match.
import 'dart:async';

import 'package:sumizuri/core/utils/downloads/jittered_delay.dart';
import 'package:sumizuri/features/extensions/data/extension_service.dart';
import 'package:sumizuri/features/extensions/models/installed_source.dart';
import 'package:sumizuri/features/extensions/models/m_entry.dart';
import 'package:sumizuri/features/library/data/library_repository.dart';
import 'package:sumizuri/features/library/migration/migration_controller.dart'
    show MigrationSourceLoader;
import 'package:sumizuri/features/library/models/library_types.dart';

/// A freshly imported title candidate for automatic source matching.
class AutoMatchCandidate {
  const AutoMatchCandidate({
    required this.entryId,
    required this.mediaType,
    required this.url,
    this.sourceName,
  });

  final int entryId;
  final MediaType mediaType;

  /// The page address the backup recorded for this title.
  final String url;

  /// The source name the backup recorded for this title, if it had one.
  final String? sourceName;
}

class AutoSourceMatchResult {
  const AutoSourceMatchResult({required this.matched, required this.left});

  /// Titles attached straight to an installed source.
  final int matched;

  /// Titles left unchanged without a verified matching source.
  final int left;
}

String? _hostOf(String url) {
  final uri = Uri.tryParse(url);
  return uri != null && uri.hasScheme && uri.host.isNotEmpty ? uri.host : null;
}

String _withoutWww(String host) =>
    host.toLowerCase().startsWith('www.') ? host.substring(4) : host.toLowerCase();

/// Returns installed sources matching candidate by host domain or source name.
List<AppInstalledSource> _sourcesToTry(
  AutoMatchCandidate candidate,
  List<AppInstalledSource> installed,
) {
  final host = _hostOf(candidate.url);
  final byHost = <AppInstalledSource>[];
  final byName = <AppInstalledSource>[];
  for (final source in installed) {
    if (!source.enabled || source.mediaType != candidate.mediaType) continue;
    final sourceHost = _hostOf(source.baseUrl);
    if (host != null && sourceHost != null && _withoutWww(host) == _withoutWww(sourceHost)) {
      byHost.add(source);
    } else if (candidate.sourceName != null &&
        source.name.toLowerCase() == candidate.sourceName!.toLowerCase()) {
      byName.add(source);
    }
  }
  return [...byHost, ...byName];
}

Future<void> _pause(ExtensionService service) async {
  final ms = service.rateLimitMs ?? 300;
  if (ms > 0) await Future<void>.delayed(jitteredDelay(ms));
}

/// Runs source matching for all candidates, reusing active source connections.
Future<AutoSourceMatchResult> autoMatchInstalledSources({
  required LibraryRepository library,
  required MigrationSourceLoader loadSource,
  required List<AppInstalledSource> installedSources,
  required List<AutoMatchCandidate> candidates,
  void Function(int done, int total)? onProgress,
}) async {
  var matched = 0;
  final services = <int, ExtensionService?>{};
  try {
    for (var i = 0; i < candidates.length; i++) {
      final candidate = candidates[i];
      for (final source in _sourcesToTry(candidate, installedSources)) {
        final service =
            services.containsKey(source.id) ? services[source.id] : null;
        final loaded = service ?? await loadSource(source);
        services[source.id] = loaded;
        if (loaded == null) continue;

        final probe = MEntry(url: candidate.url, title: '');
        final details = await loaded.getDetails(probe);
        await _pause(loaded);
        final data = details.valueOrNull;
        if (data == null) continue;

        // Only migrate source metadata; preserve original backup chapters.
        final result = await library.migrateLibraryEntry(
          entryId: candidate.entryId,
          sourceId: '${source.id}',
          externalId: candidate.url,
          mediaType: candidate.mediaType,
          coverUrl: data.coverUrl,
          status: data.status,
        );
        if (result.isOk) {
          matched++;
          break;
        }
      }
      onProgress?.call(i + 1, candidates.length);
    }
  } finally {
    for (final service in services.values) {
      await service?.dispose();
    }
  }
  return AutoSourceMatchResult(matched: matched, left: candidates.length - matched);
}
