// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reader_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ReaderController)
final readerControllerProvider = ReaderControllerFamily._();

final class ReaderControllerProvider
    extends $NotifierProvider<ReaderController, ReaderSessionState> {
  ReaderControllerProvider._({
    required ReaderControllerFamily super.from,
    required ReaderSessionArgs super.argument,
  }) : super(
         retry: null,
         name: r'readerControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$readerControllerHash();

  @override
  String toString() {
    return r'readerControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ReaderController create() => ReaderController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReaderSessionState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReaderSessionState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ReaderControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$readerControllerHash() => r'8dc21ceca82fe88a002922803839b16948db9501';

final class ReaderControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          ReaderController,
          ReaderSessionState,
          ReaderSessionState,
          ReaderSessionState,
          ReaderSessionArgs
        > {
  ReaderControllerFamily._()
    : super(
        retry: null,
        name: r'readerControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ReaderControllerProvider call(ReaderSessionArgs args) =>
      ReaderControllerProvider._(argument: args, from: this);

  @override
  String toString() => r'readerControllerProvider';
}

abstract class _$ReaderController extends $Notifier<ReaderSessionState> {
  late final _$args = ref.$arg as ReaderSessionArgs;
  ReaderSessionArgs get args => _$args;

  ReaderSessionState build(ReaderSessionArgs args);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ReaderSessionState, ReaderSessionState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ReaderSessionState, ReaderSessionState>,
              ReaderSessionState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

@ProviderFor(entryReaderMode)
final entryReaderModeProvider = EntryReaderModeFamily._();

final class EntryReaderModeProvider
    extends
        $FunctionalProvider<
          AsyncValue<ReaderMode?>,
          ReaderMode?,
          Stream<ReaderMode?>
        >
    with $FutureModifier<ReaderMode?>, $StreamProvider<ReaderMode?> {
  EntryReaderModeProvider._({
    required EntryReaderModeFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'entryReaderModeProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$entryReaderModeHash();

  @override
  String toString() {
    return r'entryReaderModeProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<ReaderMode?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<ReaderMode?> create(Ref ref) {
    final argument = this.argument as int;
    return entryReaderMode(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is EntryReaderModeProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$entryReaderModeHash() => r'96dc33b2ab5ff696be9e883a0644665326b1ad7d';

final class EntryReaderModeFamily extends $Family
    with $FunctionalFamilyOverride<Stream<ReaderMode?>, int> {
  EntryReaderModeFamily._()
    : super(
        retry: null,
        name: r'entryReaderModeProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  EntryReaderModeProvider call(int entryId) =>
      EntryReaderModeProvider._(argument: entryId, from: this);

  @override
  String toString() => r'entryReaderModeProvider';
}

@ProviderFor(entryDualPageMode)
final entryDualPageModeProvider = EntryDualPageModeFamily._();

final class EntryDualPageModeProvider
    extends
        $FunctionalProvider<
          AsyncValue<ReaderDualPageMode?>,
          ReaderDualPageMode?,
          Stream<ReaderDualPageMode?>
        >
    with
        $FutureModifier<ReaderDualPageMode?>,
        $StreamProvider<ReaderDualPageMode?> {
  EntryDualPageModeProvider._({
    required EntryDualPageModeFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'entryDualPageModeProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$entryDualPageModeHash();

  @override
  String toString() {
    return r'entryDualPageModeProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<ReaderDualPageMode?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<ReaderDualPageMode?> create(Ref ref) {
    final argument = this.argument as int;
    return entryDualPageMode(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is EntryDualPageModeProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$entryDualPageModeHash() => r'a16343807528f7660a6f5e39f7cc920e6f420cbc';

final class EntryDualPageModeFamily extends $Family
    with $FunctionalFamilyOverride<Stream<ReaderDualPageMode?>, int> {
  EntryDualPageModeFamily._()
    : super(
        retry: null,
        name: r'entryDualPageModeProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  EntryDualPageModeProvider call(int entryId) =>
      EntryDualPageModeProvider._(argument: entryId, from: this);

  @override
  String toString() => r'entryDualPageModeProvider';
}

@ProviderFor(entryOverrides)
final entryOverridesProvider = EntryOverridesFamily._();

final class EntryOverridesProvider
    extends
        $FunctionalProvider<
          AsyncValue<SeriesOverrides>,
          SeriesOverrides,
          Stream<SeriesOverrides>
        >
    with $FutureModifier<SeriesOverrides>, $StreamProvider<SeriesOverrides> {
  EntryOverridesProvider._({
    required EntryOverridesFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'entryOverridesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$entryOverridesHash();

  @override
  String toString() {
    return r'entryOverridesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<SeriesOverrides> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<SeriesOverrides> create(Ref ref) {
    final argument = this.argument as int;
    return entryOverrides(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is EntryOverridesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$entryOverridesHash() => r'26729af804e5b47d9f1334adec077c48030e8134';

final class EntryOverridesFamily extends $Family
    with $FunctionalFamilyOverride<Stream<SeriesOverrides>, int> {
  EntryOverridesFamily._()
    : super(
        retry: null,
        name: r'entryOverridesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  EntryOverridesProvider call(int entryId) =>
      EntryOverridesProvider._(argument: entryId, from: this);

  @override
  String toString() => r'entryOverridesProvider';
}
