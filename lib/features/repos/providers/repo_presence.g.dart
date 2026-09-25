// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repo_presence.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// What each repo listed (source id -> version) the last time its index was
/// fetched this session, keyed by normalized repo url. A repo that has not
/// been fetched (or could not be, such as offline) has no entry, so nothing
/// installed from it is judged gone or outdated.

@ProviderFor(RepoPresence)
final repoPresenceProvider = RepoPresenceProvider._();

/// What each repo listed (source id -> version) the last time its index was
/// fetched this session, keyed by normalized repo url. A repo that has not
/// been fetched (or could not be, such as offline) has no entry, so nothing
/// installed from it is judged gone or outdated.
final class RepoPresenceProvider
    extends $NotifierProvider<RepoPresence, Map<String, Map<String, int>>> {
  /// What each repo listed (source id -> version) the last time its index was
  /// fetched this session, keyed by normalized repo url. A repo that has not
  /// been fetched (or could not be, such as offline) has no entry, so nothing
  /// installed from it is judged gone or outdated.
  RepoPresenceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'repoPresenceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$repoPresenceHash();

  @$internal
  @override
  RepoPresence create() => RepoPresence();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, Map<String, int>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, Map<String, int>>>(
        value,
      ),
    );
  }
}

String _$repoPresenceHash() => r'cad31f814eea266c7ea8ccbfc7a6a7f2b3d62876';

/// What each repo listed (source id -> version) the last time its index was
/// fetched this session, keyed by normalized repo url. A repo that has not
/// been fetched (or could not be, such as offline) has no entry, so nothing
/// installed from it is judged gone or outdated.

abstract class _$RepoPresence extends $Notifier<Map<String, Map<String, int>>> {
  Map<String, Map<String, int>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              Map<String, Map<String, int>>,
              Map<String, Map<String, int>>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                Map<String, Map<String, int>>,
                Map<String, Map<String, int>>
              >,
              Map<String, Map<String, int>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Installed sources whose repo no longer lists them.

@ProviderFor(obsoleteSourceIds)
final obsoleteSourceIdsProvider = ObsoleteSourceIdsProvider._();

/// Installed sources whose repo no longer lists them.

final class ObsoleteSourceIdsProvider
    extends $FunctionalProvider<Set<int>, Set<int>, Set<int>>
    with $Provider<Set<int>> {
  /// Installed sources whose repo no longer lists them.
  ObsoleteSourceIdsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'obsoleteSourceIdsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$obsoleteSourceIdsHash();

  @$internal
  @override
  $ProviderElement<Set<int>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Set<int> create(Ref ref) {
    return obsoleteSourceIds(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<int> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<int>>(value),
    );
  }
}

String _$obsoleteSourceIdsHash() => r'e79388b10c6dff15eacebc80dde280cf6d47892e';

/// Installed sources whose repo now lists a newer version.

@ProviderFor(updatableSourceIds)
final updatableSourceIdsProvider = UpdatableSourceIdsProvider._();

/// Installed sources whose repo now lists a newer version.

final class UpdatableSourceIdsProvider
    extends $FunctionalProvider<Set<int>, Set<int>, Set<int>>
    with $Provider<Set<int>> {
  /// Installed sources whose repo now lists a newer version.
  UpdatableSourceIdsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'updatableSourceIdsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$updatableSourceIdsHash();

  @$internal
  @override
  $ProviderElement<Set<int>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Set<int> create(Ref ref) {
    return updatableSourceIds(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<int> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<int>>(value),
    );
  }
}

String _$updatableSourceIdsHash() =>
    r'aa0313d4cc21ee8540acf21c2078966578ee960b';

/// How many extra copies of a source are installed: the same repo source
/// installed more than once counts as one copy too many per repeat.

@ProviderFor(duplicateSourceCount)
final duplicateSourceCountProvider = DuplicateSourceCountProvider._();

/// How many extra copies of a source are installed: the same repo source
/// installed more than once counts as one copy too many per repeat.

final class DuplicateSourceCountProvider
    extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  /// How many extra copies of a source are installed: the same repo source
  /// installed more than once counts as one copy too many per repeat.
  DuplicateSourceCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'duplicateSourceCountProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$duplicateSourceCountHash();

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    return duplicateSourceCount(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$duplicateSourceCountHash() =>
    r'581b1aea863c19e7a1fe5b4d5ee9edc29670d510';
