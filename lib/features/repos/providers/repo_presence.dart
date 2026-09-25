import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:sumizuri/features/extensions/providers/extension_providers.dart';
import 'package:sumizuri/features/repos/data/repo_url.dart';
import 'package:sumizuri/features/repos/models/repo_source.dart';
import 'package:sumizuri/features/repos/providers/repo_providers.dart';

part 'repo_presence.g.dart';

/// What each repo listed (source id -> version) the last time its index was
/// fetched this session, keyed by normalized repo url. A repo that has not
/// been fetched (or could not be, such as offline) has no entry, so nothing
/// installed from it is judged gone or outdated.
@Riverpod(keepAlive: true)
class RepoPresence extends _$RepoPresence {
  @override
  Map<String, Map<String, int>> build() => const {};

  /// An empty index is ignored: a repo that failed to serve its list would
  /// otherwise mark every source installed from it as removed.
  void record(String repoUrl, Iterable<RepoSource> sources) {
    final listed = {for (final s in sources) s.id: s.version};
    if (listed.isEmpty) return;
    state = {...state, normalizeRepoUrl(repoUrl): listed};
  }

  /// Fetches every saved repo's index once, skipping ones already checked.
  Future<void> checkAll({bool force = false}) async {
    // Straight from the repository: reposProvider is auto-dispose, and with
    // nothing listening it can be torn down before it emits.
    final repository = ref.read(repoRepositoryProvider);
    try {
      final repos = await repository.watchAll().first;
      await Future.wait([
        for (final repo in repos)
          if (force || !state.containsKey(normalizeRepoUrl(repo.url)))
            () async {
              final index = (await repository.fetchIndex(repo.url)).valueOrNull;
              if (index != null) record(repo.url, index.sources);
            }(),
      ]);
    } catch (_) {
      // A background check: a failure just leaves things unchecked.
    }
  }
}

/// Installed sources whose repo no longer lists them.
@Riverpod(keepAlive: true)
Set<int> obsoleteSourceIds(Ref ref) {
  final presence = ref.watch(repoPresenceProvider);
  final installed = ref.watch(installedSourcesProvider).value ?? const [];
  return {
    for (final source in installed)
      if (source.repoUrl != null && source.repoSourceId != null)
        if (presence[normalizeRepoUrl(source.repoUrl!)] case final listed?)
          if (!listed.containsKey(source.repoSourceId)) source.id,
  };
}

/// Installed sources whose repo now lists a newer version.
@Riverpod(keepAlive: true)
Set<int> updatableSourceIds(Ref ref) {
  final presence = ref.watch(repoPresenceProvider);
  final installed = ref.watch(installedSourcesProvider).value ?? const [];
  return {
    for (final source in installed)
      if (source.repoUrl != null && source.repoSourceId != null)
        if (presence[normalizeRepoUrl(source.repoUrl!)]?[source.repoSourceId]
            case final latest?)
          if (latest > source.version) source.id,
  };
}

/// How many extra copies of a source are installed: the same repo source
/// installed more than once counts as one copy too many per repeat.
@Riverpod(keepAlive: true)
int duplicateSourceCount(Ref ref) {
  final installed = ref.watch(installedSourcesProvider).value ?? const [];
  final counts = <String, int>{};
  for (final source in installed) {
    final repoUrl = source.repoUrl;
    final repoSourceId = source.repoSourceId;
    if (repoUrl == null || repoSourceId == null) continue;
    final key = '${normalizeRepoUrl(repoUrl)}\n$repoSourceId';
    counts[key] = (counts[key] ?? 0) + 1;
  }
  return counts.values.fold(0, (sum, n) => n > 1 ? sum + n - 1 : sum);
}
