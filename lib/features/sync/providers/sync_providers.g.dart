// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(syncRepository)
final syncRepositoryProvider = SyncRepositoryProvider._();

final class SyncRepositoryProvider
    extends $FunctionalProvider<SyncRepository, SyncRepository, SyncRepository>
    with $Provider<SyncRepository> {
  SyncRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncRepositoryHash();

  @$internal
  @override
  $ProviderElement<SyncRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SyncRepository create(Ref ref) {
    return syncRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SyncRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SyncRepository>(value),
    );
  }
}

String _$syncRepositoryHash() => r'87c8b2d7234d5ca6c79b9d891d1612daa710f03a';

@ProviderFor(syncAccount)
final syncAccountProvider = SyncAccountProvider._();

final class SyncAccountProvider
    extends
        $FunctionalProvider<
          AsyncValue<SyncAccount?>,
          SyncAccount?,
          FutureOr<SyncAccount?>
        >
    with $FutureModifier<SyncAccount?>, $FutureProvider<SyncAccount?> {
  SyncAccountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncAccountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncAccountHash();

  @$internal
  @override
  $FutureProviderElement<SyncAccount?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<SyncAccount?> create(Ref ref) {
    return syncAccount(ref);
  }
}

String _$syncAccountHash() => r'cd04a43e72507cff87492308cf7316cf9da1653e';

@ProviderFor(syncLinkedProfile)
final syncLinkedProfileProvider = SyncLinkedProfileProvider._();

final class SyncLinkedProfileProvider
    extends
        $FunctionalProvider<
          AsyncValue<SyncServerProfile?>,
          SyncServerProfile?,
          FutureOr<SyncServerProfile?>
        >
    with
        $FutureModifier<SyncServerProfile?>,
        $FutureProvider<SyncServerProfile?> {
  SyncLinkedProfileProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncLinkedProfileProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncLinkedProfileHash();

  @$internal
  @override
  $FutureProviderElement<SyncServerProfile?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<SyncServerProfile?> create(Ref ref) {
    return syncLinkedProfile(ref);
  }
}

String _$syncLinkedProfileHash() => r'e01330b6812c1f698eaff591dc20e7d98d1c92d1';

@ProviderFor(syncServerProfiles)
final syncServerProfilesProvider = SyncServerProfilesProvider._();

final class SyncServerProfilesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SyncServerProfile>>,
          List<SyncServerProfile>,
          FutureOr<List<SyncServerProfile>>
        >
    with
        $FutureModifier<List<SyncServerProfile>>,
        $FutureProvider<List<SyncServerProfile>> {
  SyncServerProfilesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncServerProfilesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncServerProfilesHash();

  @$internal
  @override
  $FutureProviderElement<List<SyncServerProfile>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<SyncServerProfile>> create(Ref ref) {
    return syncServerProfiles(ref);
  }
}

String _$syncServerProfilesHash() =>
    r'0a9ee1598ba4014712d07a294389c439eab4117a';

/// Device-clock time the active profile last finished a sync, 0 if never.

@ProviderFor(lastSyncedAt)
final lastSyncedAtProvider = LastSyncedAtProvider._();

/// Device-clock time the active profile last finished a sync, 0 if never.

final class LastSyncedAtProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  /// Device-clock time the active profile last finished a sync, 0 if never.
  LastSyncedAtProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'lastSyncedAtProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$lastSyncedAtHash();

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    return lastSyncedAt(ref);
  }
}

String _$lastSyncedAtHash() => r'62c36b3b3ac729a0bef4e6f9c2065d2f5e27075a';

@ProviderFor(syncPreferences)
final syncPreferencesProvider = SyncPreferencesProvider._();

final class SyncPreferencesProvider
    extends
        $FunctionalProvider<
          AsyncValue<SyncPreferences>,
          SyncPreferences,
          FutureOr<SyncPreferences>
        >
    with $FutureModifier<SyncPreferences>, $FutureProvider<SyncPreferences> {
  SyncPreferencesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncPreferencesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncPreferencesHash();

  @$internal
  @override
  $FutureProviderElement<SyncPreferences> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<SyncPreferences> create(Ref ref) {
    return syncPreferences(ref);
  }
}

String _$syncPreferencesHash() => r'1ad87c23f1816ae7ca1892893780adf440fe1330';

@ProviderFor(SyncGuard)
final syncGuardProvider = SyncGuardProvider._();

final class SyncGuardProvider extends $NotifierProvider<SyncGuard, bool> {
  SyncGuardProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncGuardProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncGuardHash();

  @$internal
  @override
  SyncGuard create() => SyncGuard();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$syncGuardHash() => r'1bf92f35632723debd1abc61433b6ba9dee836eb';

abstract class _$SyncGuard extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(SyncRunner)
final syncRunnerProvider = SyncRunnerProvider._();

final class SyncRunnerProvider
    extends $NotifierProvider<SyncRunner, SyncRunState> {
  SyncRunnerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncRunnerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncRunnerHash();

  @$internal
  @override
  SyncRunner create() => SyncRunner();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SyncRunState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SyncRunState>(value),
    );
  }
}

String _$syncRunnerHash() => r'0e3e4620f3782f40f592de8d6e6aa91f932eda93';

abstract class _$SyncRunner extends $Notifier<SyncRunState> {
  SyncRunState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<SyncRunState, SyncRunState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SyncRunState, SyncRunState>,
              SyncRunState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
