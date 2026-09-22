// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'anilist_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(aniListApiClient)
final aniListApiClientProvider = AniListApiClientProvider._();

final class AniListApiClientProvider
    extends
        $FunctionalProvider<
          AniListApiClient,
          AniListApiClient,
          AniListApiClient
        >
    with $Provider<AniListApiClient> {
  AniListApiClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'aniListApiClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$aniListApiClientHash();

  @$internal
  @override
  $ProviderElement<AniListApiClient> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AniListApiClient create(Ref ref) {
    return aniListApiClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AniListApiClient value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AniListApiClient>(value),
    );
  }
}

String _$aniListApiClientHash() => r'6b73e655bc2d134be4d86947744fb4e8e43cb8e9';

@ProviderFor(aniListRepository)
final aniListRepositoryProvider = AniListRepositoryProvider._();

final class AniListRepositoryProvider
    extends
        $FunctionalProvider<
          AniListRepository,
          AniListRepository,
          AniListRepository
        >
    with $Provider<AniListRepository> {
  AniListRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'aniListRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$aniListRepositoryHash();

  @$internal
  @override
  $ProviderElement<AniListRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AniListRepository create(Ref ref) {
    return aniListRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AniListRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AniListRepository>(value),
    );
  }
}

String _$aniListRepositoryHash() => r'2a803d07b527a79e38ed892b56d5707a88153008';

@ProviderFor(trackerStore)
final trackerStoreProvider = TrackerStoreProvider._();

final class TrackerStoreProvider
    extends $FunctionalProvider<TrackerStore, TrackerStore, TrackerStore>
    with $Provider<TrackerStore> {
  TrackerStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'trackerStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$trackerStoreHash();

  @$internal
  @override
  $ProviderElement<TrackerStore> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TrackerStore create(Ref ref) {
    return trackerStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TrackerStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TrackerStore>(value),
    );
  }
}

String _$trackerStoreHash() => r'ed5db9f3b29357d3b62a8fac9f53897872aa5855';

@ProviderFor(aniListSyncService)
final aniListSyncServiceProvider = AniListSyncServiceProvider._();

final class AniListSyncServiceProvider
    extends
        $FunctionalProvider<
          AniListSyncService,
          AniListSyncService,
          AniListSyncService
        >
    with $Provider<AniListSyncService> {
  AniListSyncServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'aniListSyncServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$aniListSyncServiceHash();

  @$internal
  @override
  $ProviderElement<AniListSyncService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AniListSyncService create(Ref ref) {
    return aniListSyncService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AniListSyncService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AniListSyncService>(value),
    );
  }
}

String _$aniListSyncServiceHash() =>
    r'28e36b054ed925ef6652d8dce92297cae3c9233e';

@ProviderFor(AniListAccountNotifier)
final aniListAccountProvider = AniListAccountNotifierProvider._();

final class AniListAccountNotifierProvider
    extends $AsyncNotifierProvider<AniListAccountNotifier, AniListAccount?> {
  AniListAccountNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'aniListAccountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$aniListAccountNotifierHash();

  @$internal
  @override
  AniListAccountNotifier create() => AniListAccountNotifier();
}

String _$aniListAccountNotifierHash() =>
    r'92db98668996cd9f0fce952ffcbd0173fb4dbb29';

abstract class _$AniListAccountNotifier
    extends $AsyncNotifier<AniListAccount?> {
  FutureOr<AniListAccount?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<AniListAccount?>, AniListAccount?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<AniListAccount?>, AniListAccount?>,
              AsyncValue<AniListAccount?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
