// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'migration_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(migrationSourceLoader)
final migrationSourceLoaderProvider = MigrationSourceLoaderProvider._();

final class MigrationSourceLoaderProvider
    extends
        $FunctionalProvider<
          MigrationSourceLoader,
          MigrationSourceLoader,
          MigrationSourceLoader
        >
    with $Provider<MigrationSourceLoader> {
  MigrationSourceLoaderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'migrationSourceLoaderProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$migrationSourceLoaderHash();

  @$internal
  @override
  $ProviderElement<MigrationSourceLoader> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MigrationSourceLoader create(Ref ref) {
    return migrationSourceLoader(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MigrationSourceLoader value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MigrationSourceLoader>(value),
    );
  }
}

String _$migrationSourceLoaderHash() =>
    r'af928e4003a787412b98a68ba0e8a17754279b35';

@ProviderFor(MigrationSession)
final migrationSessionProvider = MigrationSessionProvider._();

final class MigrationSessionProvider
    extends $NotifierProvider<MigrationSession, MigrationState> {
  MigrationSessionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'migrationSessionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$migrationSessionHash();

  @$internal
  @override
  MigrationSession create() => MigrationSession();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MigrationState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MigrationState>(value),
    );
  }
}

String _$migrationSessionHash() => r'1989305cb0e7734307bf6e982099436244d5b24b';

abstract class _$MigrationSession extends $Notifier<MigrationState> {
  MigrationState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<MigrationState, MigrationState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<MigrationState, MigrationState>,
              MigrationState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
