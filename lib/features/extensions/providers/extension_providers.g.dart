// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'extension_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(installedSourceRepository)
final installedSourceRepositoryProvider = InstalledSourceRepositoryProvider._();

final class InstalledSourceRepositoryProvider
    extends
        $FunctionalProvider<
          InstalledSourceRepository,
          InstalledSourceRepository,
          InstalledSourceRepository
        >
    with $Provider<InstalledSourceRepository> {
  InstalledSourceRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'installedSourceRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$installedSourceRepositoryHash();

  @$internal
  @override
  $ProviderElement<InstalledSourceRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  InstalledSourceRepository create(Ref ref) {
    return installedSourceRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InstalledSourceRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InstalledSourceRepository>(value),
    );
  }
}

String _$installedSourceRepositoryHash() =>
    r'4e149cdf31911bdca8ddca3a6e88d0bf531e8d15';

@ProviderFor(installedSources)
final installedSourcesProvider = InstalledSourcesProvider._();

final class InstalledSourcesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<AppInstalledSource>>,
          List<AppInstalledSource>,
          Stream<List<AppInstalledSource>>
        >
    with
        $FutureModifier<List<AppInstalledSource>>,
        $StreamProvider<List<AppInstalledSource>> {
  InstalledSourcesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'installedSourcesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$installedSourcesHash();

  @$internal
  @override
  $StreamProviderElement<List<AppInstalledSource>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<AppInstalledSource>> create(Ref ref) {
    return installedSources(ref);
  }
}

String _$installedSourcesHash() => r'16cbfa542743407b4dd1591ea23661edce3e8303';

/// How a screen starts a source. A test replaces it with a fake.

@ProviderFor(sourceLoader)
final sourceLoaderProvider = SourceLoaderProvider._();

/// How a screen starts a source. A test replaces it with a fake.

final class SourceLoaderProvider
    extends $FunctionalProvider<SourceLoader, SourceLoader, SourceLoader>
    with $Provider<SourceLoader> {
  /// How a screen starts a source. A test replaces it with a fake.
  SourceLoaderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sourceLoaderProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sourceLoaderHash();

  @$internal
  @override
  $ProviderElement<SourceLoader> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SourceLoader create(Ref ref) {
    return sourceLoader(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SourceLoader value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SourceLoader>(value),
    );
  }
}

String _$sourceLoaderHash() => r'ebe6f2a1c2226f4feea6689684bf8368fa59992c';
