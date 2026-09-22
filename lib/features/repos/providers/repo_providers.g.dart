// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repo_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(repoRepository)
final repoRepositoryProvider = RepoRepositoryProvider._();

final class RepoRepositoryProvider
    extends $FunctionalProvider<RepoRepository, RepoRepository, RepoRepository>
    with $Provider<RepoRepository> {
  RepoRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'repoRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$repoRepositoryHash();

  @$internal
  @override
  $ProviderElement<RepoRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RepoRepository create(Ref ref) {
    return repoRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RepoRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RepoRepository>(value),
    );
  }
}

String _$repoRepositoryHash() => r'fa38bf224c13fe8a9a322dc03c1fe9c680bd2301';

@ProviderFor(repos)
final reposProvider = ReposProvider._();

final class ReposProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Repo>>,
          List<Repo>,
          Stream<List<Repo>>
        >
    with $FutureModifier<List<Repo>>, $StreamProvider<List<Repo>> {
  ReposProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reposProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reposHash();

  @$internal
  @override
  $StreamProviderElement<List<Repo>> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<List<Repo>> create(Ref ref) {
    return repos(ref);
  }
}

String _$reposHash() => r'91a6ee02a93d3f0ff8296bbc41f64aef7dd30899';
