// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'download_queue.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(downloadQueueStore)
final downloadQueueStoreProvider = DownloadQueueStoreProvider._();

final class DownloadQueueStoreProvider
    extends
        $FunctionalProvider<
          DownloadQueueStore,
          DownloadQueueStore,
          DownloadQueueStore
        >
    with $Provider<DownloadQueueStore> {
  DownloadQueueStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'downloadQueueStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$downloadQueueStoreHash();

  @$internal
  @override
  $ProviderElement<DownloadQueueStore> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DownloadQueueStore create(Ref ref) {
    return downloadQueueStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DownloadQueueStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DownloadQueueStore>(value),
    );
  }
}

String _$downloadQueueStoreHash() =>
    r'0d27fdcfe3dfe109bfe72e101538ef5ae86f3bd7';

/// Whether downloads from the last run carry on alone, or wait when Wi-Fi only is set.

@ProviderFor(downloadResumeGate)
final downloadResumeGateProvider = DownloadResumeGateProvider._();

/// Whether downloads from the last run carry on alone, or wait when Wi-Fi only is set.

final class DownloadResumeGateProvider
    extends
        $FunctionalProvider<
          Future<bool> Function(),
          Future<bool> Function(),
          Future<bool> Function()
        >
    with $Provider<Future<bool> Function()> {
  /// Whether downloads from the last run carry on alone, or wait when Wi-Fi only is set.
  DownloadResumeGateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'downloadResumeGateProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$downloadResumeGateHash();

  @$internal
  @override
  $ProviderElement<Future<bool> Function()> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Future<bool> Function() create(Ref ref) {
    return downloadResumeGate(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Future<bool> Function() value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Future<bool> Function()>(value),
    );
  }
}

String _$downloadResumeGateHash() =>
    r'beb765970de8e20422bdb7dbe6f35affebc9a378';

@ProviderFor(downloadEngine)
final downloadEngineProvider = DownloadEngineProvider._();

final class DownloadEngineProvider
    extends $FunctionalProvider<DownloadEngine, DownloadEngine, DownloadEngine>
    with $Provider<DownloadEngine> {
  DownloadEngineProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'downloadEngineProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$downloadEngineHash();

  @$internal
  @override
  $ProviderElement<DownloadEngine> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DownloadEngine create(Ref ref) {
    return downloadEngine(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DownloadEngine value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DownloadEngine>(value),
    );
  }
}

String _$downloadEngineHash() => r'329bc4a69d376b11345d1e7ea897902e1e34c59e';

@ProviderFor(DownloadQueue)
final downloadQueueProvider = DownloadQueueProvider._();

final class DownloadQueueProvider
    extends $NotifierProvider<DownloadQueue, List<DownloadItem>> {
  DownloadQueueProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'downloadQueueProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$downloadQueueHash();

  @$internal
  @override
  DownloadQueue create() => DownloadQueue();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<DownloadItem> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<DownloadItem>>(value),
    );
  }
}

String _$downloadQueueHash() => r'7028d5661844f8fbb4a629b0d6164d7c2daf5d0d';

abstract class _$DownloadQueue extends $Notifier<List<DownloadItem>> {
  List<DownloadItem> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<List<DownloadItem>, List<DownloadItem>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<DownloadItem>, List<DownloadItem>>,
              List<DownloadItem>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The chapters that are waiting or running, for the download buttons.

@ProviderFor(downloadingChapters)
final downloadingChaptersProvider = DownloadingChaptersProvider._();

/// The chapters that are waiting or running, for the download buttons.

final class DownloadingChaptersProvider
    extends $FunctionalProvider<Set<String>, Set<String>, Set<String>>
    with $Provider<Set<String>> {
  /// The chapters that are waiting or running, for the download buttons.
  DownloadingChaptersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'downloadingChaptersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$downloadingChaptersHash();

  @$internal
  @override
  $ProviderElement<Set<String>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Set<String> create(Ref ref) {
    return downloadingChapters(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<String>>(value),
    );
  }
}

String _$downloadingChaptersHash() =>
    r'32808399001ca7493e609ff9b0c81c71add38941';

/// How far each running download has got.

@ProviderFor(downloadProgress)
final downloadProgressProvider = DownloadProgressProvider._();

/// How far each running download has got.

final class DownloadProgressProvider
    extends
        $FunctionalProvider<
          Map<String, double>,
          Map<String, double>,
          Map<String, double>
        >
    with $Provider<Map<String, double>> {
  /// How far each running download has got.
  DownloadProgressProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'downloadProgressProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$downloadProgressHash();

  @$internal
  @override
  $ProviderElement<Map<String, double>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Map<String, double> create(Ref ref) {
    return downloadProgress(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, double> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, double>>(value),
    );
  }
}

String _$downloadProgressHash() => r'6c6df74861cf7fd3209002962a1591cfe328db9d';
