// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(settingsRepository)
final settingsRepositoryProvider = SettingsRepositoryProvider._();

final class SettingsRepositoryProvider
    extends
        $FunctionalProvider<
          SettingsRepository,
          SettingsRepository,
          SettingsRepository
        >
    with $Provider<SettingsRepository> {
  SettingsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'settingsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$settingsRepositoryHash();

  @$internal
  @override
  $ProviderElement<SettingsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SettingsRepository create(Ref ref) {
    return settingsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SettingsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SettingsRepository>(value),
    );
  }
}

String _$settingsRepositoryHash() =>
    r'4c8dc195f3eab4b45f48ea973beba52f5f1f4b3e';

@ProviderFor(onboardingCompleted)
final onboardingCompletedProvider = OnboardingCompletedProvider._();

final class OnboardingCompletedProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, Stream<bool>>
    with $FutureModifier<bool>, $StreamProvider<bool> {
  OnboardingCompletedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'onboardingCompletedProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$onboardingCompletedHash();

  @$internal
  @override
  $StreamProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<bool> create(Ref ref) {
    return onboardingCompleted(ref);
  }
}

String _$onboardingCompletedHash() =>
    r'2b36e21ccba6951ec3904be1ebd291cb4e757cef';

@ProviderFor(libraryMode)
final libraryModeProvider = LibraryModeProvider._();

final class LibraryModeProvider
    extends
        $FunctionalProvider<
          AsyncValue<AppLibraryMode>,
          AppLibraryMode,
          Stream<AppLibraryMode>
        >
    with $FutureModifier<AppLibraryMode>, $StreamProvider<AppLibraryMode> {
  LibraryModeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'libraryModeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$libraryModeHash();

  @$internal
  @override
  $StreamProviderElement<AppLibraryMode> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<AppLibraryMode> create(Ref ref) {
    return libraryMode(ref);
  }
}

String _$libraryModeHash() => r'0b7055fd2318c56b8dfccb965fef72b55aa8177d';

@ProviderFor(backgroundIntensity)
final backgroundIntensityProvider = BackgroundIntensityProvider._();

final class BackgroundIntensityProvider
    extends $FunctionalProvider<AsyncValue<double>, double, Stream<double>>
    with $FutureModifier<double>, $StreamProvider<double> {
  BackgroundIntensityProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'backgroundIntensityProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$backgroundIntensityHash();

  @$internal
  @override
  $StreamProviderElement<double> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<double> create(Ref ref) {
    return backgroundIntensity(ref);
  }
}

String _$backgroundIntensityHash() =>
    r'fa42a99b390ddd7821eb94fc23d3c21cd6dc9d6a';

@ProviderFor(BackgroundLookPreview)
final backgroundLookPreviewProvider = BackgroundLookPreviewProvider._();

final class BackgroundLookPreviewProvider
    extends $NotifierProvider<BackgroundLookPreview, BackgroundLookDraft> {
  BackgroundLookPreviewProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'backgroundLookPreviewProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$backgroundLookPreviewHash();

  @$internal
  @override
  BackgroundLookPreview create() => BackgroundLookPreview();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BackgroundLookDraft value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BackgroundLookDraft>(value),
    );
  }
}

String _$backgroundLookPreviewHash() =>
    r'6dde980e18f8d5385a370cc3bce1f5d0e22c74b0';

abstract class _$BackgroundLookPreview extends $Notifier<BackgroundLookDraft> {
  BackgroundLookDraft build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<BackgroundLookDraft, BackgroundLookDraft>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<BackgroundLookDraft, BackgroundLookDraft>,
              BackgroundLookDraft,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(effectiveBackgroundIntensity)
final effectiveBackgroundIntensityProvider =
    EffectiveBackgroundIntensityProvider._();

final class EffectiveBackgroundIntensityProvider
    extends $FunctionalProvider<double, double, double>
    with $Provider<double> {
  EffectiveBackgroundIntensityProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'effectiveBackgroundIntensityProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$effectiveBackgroundIntensityHash();

  @$internal
  @override
  $ProviderElement<double> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  double create(Ref ref) {
    return effectiveBackgroundIntensity(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(double value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<double>(value),
    );
  }
}

String _$effectiveBackgroundIntensityHash() =>
    r'29931bcdad9b3c50744aa665d33e61b6f4a45520';

@ProviderFor(hiddenThemePresets)
final hiddenThemePresetsProvider = HiddenThemePresetsProvider._();

final class HiddenThemePresetsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Set<AppColorScheme>>,
          Set<AppColorScheme>,
          Stream<Set<AppColorScheme>>
        >
    with
        $FutureModifier<Set<AppColorScheme>>,
        $StreamProvider<Set<AppColorScheme>> {
  HiddenThemePresetsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'hiddenThemePresetsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$hiddenThemePresetsHash();

  @$internal
  @override
  $StreamProviderElement<Set<AppColorScheme>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Set<AppColorScheme>> create(Ref ref) {
    return hiddenThemePresets(ref);
  }
}

String _$hiddenThemePresetsHash() =>
    r'87a0dd4628090d55f12f660141239154fff77a6c';

@ProviderFor(themeScheme)
final themeSchemeProvider = ThemeSchemeProvider._();

final class ThemeSchemeProvider
    extends $FunctionalProvider<AsyncValue<String>, String, Stream<String>>
    with $FutureModifier<String>, $StreamProvider<String> {
  ThemeSchemeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'themeSchemeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$themeSchemeHash();

  @$internal
  @override
  $StreamProviderElement<String> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<String> create(Ref ref) {
    return themeScheme(ref);
  }
}

String _$themeSchemeHash() => r'587cb2ef9b4b5ad4122bb648d72045805f8ae5cd';

@ProviderFor(darkModePreference)
final darkModePreferenceProvider = DarkModePreferenceProvider._();

final class DarkModePreferenceProvider
    extends
        $FunctionalProvider<
          AsyncValue<AppDarkModePreference>,
          AppDarkModePreference,
          Stream<AppDarkModePreference>
        >
    with
        $FutureModifier<AppDarkModePreference>,
        $StreamProvider<AppDarkModePreference> {
  DarkModePreferenceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'darkModePreferenceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$darkModePreferenceHash();

  @$internal
  @override
  $StreamProviderElement<AppDarkModePreference> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<AppDarkModePreference> create(Ref ref) {
    return darkModePreference(ref);
  }
}

String _$darkModePreferenceHash() =>
    r'492f51f98da25c251e39c1e96b0cdc4f1bb04bbb';

@ProviderFor(amoledDark)
final amoledDarkProvider = AmoledDarkProvider._();

final class AmoledDarkProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, Stream<bool>>
    with $FutureModifier<bool>, $StreamProvider<bool> {
  AmoledDarkProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'amoledDarkProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$amoledDarkHash();

  @$internal
  @override
  $StreamProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<bool> create(Ref ref) {
    return amoledDark(ref);
  }
}

String _$amoledDarkHash() => r'd7278f1995be0d960a549aa3992147a244d6f094';

@ProviderFor(colorIntensity)
final colorIntensityProvider = ColorIntensityProvider._();

final class ColorIntensityProvider
    extends
        $FunctionalProvider<
          AsyncValue<ColorIntensity>,
          ColorIntensity,
          Stream<ColorIntensity>
        >
    with $FutureModifier<ColorIntensity>, $StreamProvider<ColorIntensity> {
  ColorIntensityProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'colorIntensityProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$colorIntensityHash();

  @$internal
  @override
  $StreamProviderElement<ColorIntensity> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<ColorIntensity> create(Ref ref) {
    return colorIntensity(ref);
  }
}

String _$colorIntensityHash() => r'c647cdc8f34b2979ab181e3c51fb3f1062f2ce12';

@ProviderFor(navDestinations)
final navDestinationsProvider = NavDestinationsProvider._();

final class NavDestinationsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<NavDestinationKind>>,
          List<NavDestinationKind>,
          Stream<List<NavDestinationKind>>
        >
    with
        $FutureModifier<List<NavDestinationKind>>,
        $StreamProvider<List<NavDestinationKind>> {
  NavDestinationsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'navDestinationsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$navDestinationsHash();

  @$internal
  @override
  $StreamProviderElement<List<NavDestinationKind>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<NavDestinationKind>> create(Ref ref) {
    return navDestinations(ref);
  }
}

String _$navDestinationsHash() => r'961de6f80b8c3a4605aeb0377ac41f0170dc2799';

@ProviderFor(enabledMediaTypes)
final enabledMediaTypesProvider = EnabledMediaTypesProvider._();

final class EnabledMediaTypesProvider
    extends
        $FunctionalProvider<
          AsyncValue<Set<MediaType>>,
          Set<MediaType>,
          Stream<Set<MediaType>>
        >
    with $FutureModifier<Set<MediaType>>, $StreamProvider<Set<MediaType>> {
  EnabledMediaTypesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'enabledMediaTypesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$enabledMediaTypesHash();

  @$internal
  @override
  $StreamProviderElement<Set<MediaType>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Set<MediaType>> create(Ref ref) {
    return enabledMediaTypes(ref);
  }
}

String _$enabledMediaTypesHash() => r'4e9dc0d96d86688c336d8d1f89b21e8c9e1ddc36';

@ProviderFor(globalReaderMode)
final globalReaderModeProvider = GlobalReaderModeProvider._();

final class GlobalReaderModeProvider
    extends
        $FunctionalProvider<
          AsyncValue<ReaderMode>,
          ReaderMode,
          Stream<ReaderMode>
        >
    with $FutureModifier<ReaderMode>, $StreamProvider<ReaderMode> {
  GlobalReaderModeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'globalReaderModeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$globalReaderModeHash();

  @$internal
  @override
  $StreamProviderElement<ReaderMode> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<ReaderMode> create(Ref ref) {
    return globalReaderMode(ref);
  }
}

String _$globalReaderModeHash() => r'4fbf49d585ab041001286d03a674d1ee236c7185';

@ProviderFor(globalReaderScaleType)
final globalReaderScaleTypeProvider = GlobalReaderScaleTypeProvider._();

final class GlobalReaderScaleTypeProvider
    extends
        $FunctionalProvider<
          AsyncValue<ReaderScaleType>,
          ReaderScaleType,
          Stream<ReaderScaleType>
        >
    with $FutureModifier<ReaderScaleType>, $StreamProvider<ReaderScaleType> {
  GlobalReaderScaleTypeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'globalReaderScaleTypeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$globalReaderScaleTypeHash();

  @$internal
  @override
  $StreamProviderElement<ReaderScaleType> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<ReaderScaleType> create(Ref ref) {
    return globalReaderScaleType(ref);
  }
}

String _$globalReaderScaleTypeHash() =>
    r'1f1a80ecadaebb78206478f549a44ccb6f028e6c';

@ProviderFor(globalReaderBackground)
final globalReaderBackgroundProvider = GlobalReaderBackgroundProvider._();

final class GlobalReaderBackgroundProvider
    extends
        $FunctionalProvider<
          AsyncValue<ReaderBackground>,
          ReaderBackground,
          Stream<ReaderBackground>
        >
    with $FutureModifier<ReaderBackground>, $StreamProvider<ReaderBackground> {
  GlobalReaderBackgroundProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'globalReaderBackgroundProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$globalReaderBackgroundHash();

  @$internal
  @override
  $StreamProviderElement<ReaderBackground> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<ReaderBackground> create(Ref ref) {
    return globalReaderBackground(ref);
  }
}

String _$globalReaderBackgroundHash() =>
    r'32250e721c9f87868c0265df1b4e45c71a959a0b';

@ProviderFor(globalReaderPageGap)
final globalReaderPageGapProvider = GlobalReaderPageGapProvider._();

final class GlobalReaderPageGapProvider
    extends
        $FunctionalProvider<
          AsyncValue<ReaderPageGap>,
          ReaderPageGap,
          Stream<ReaderPageGap>
        >
    with $FutureModifier<ReaderPageGap>, $StreamProvider<ReaderPageGap> {
  GlobalReaderPageGapProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'globalReaderPageGapProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$globalReaderPageGapHash();

  @$internal
  @override
  $StreamProviderElement<ReaderPageGap> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<ReaderPageGap> create(Ref ref) {
    return globalReaderPageGap(ref);
  }
}

String _$globalReaderPageGapHash() =>
    r'7d68dc2d7642de782651141dc8a366f6c3b9df62';

@ProviderFor(readerKeepScreenOn)
final readerKeepScreenOnProvider = ReaderKeepScreenOnProvider._();

final class ReaderKeepScreenOnProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, Stream<bool>>
    with $FutureModifier<bool>, $StreamProvider<bool> {
  ReaderKeepScreenOnProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'readerKeepScreenOnProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$readerKeepScreenOnHash();

  @$internal
  @override
  $StreamProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<bool> create(Ref ref) {
    return readerKeepScreenOn(ref);
  }
}

String _$readerKeepScreenOnHash() =>
    r'd432af6d6097a4b03c20b31b81d0200a30b4a433';

@ProviderFor(readerVolumeKeys)
final readerVolumeKeysProvider = ReaderVolumeKeysProvider._();

final class ReaderVolumeKeysProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, Stream<bool>>
    with $FutureModifier<bool>, $StreamProvider<bool> {
  ReaderVolumeKeysProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'readerVolumeKeysProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$readerVolumeKeysHash();

  @$internal
  @override
  $StreamProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<bool> create(Ref ref) {
    return readerVolumeKeys(ref);
  }
}

String _$readerVolumeKeysHash() => r'05bce6734c7d50d293d975b46117170f24228fec';

@ProviderFor(readerVerticalNavigator)
final readerVerticalNavigatorProvider = ReaderVerticalNavigatorProvider._();

final class ReaderVerticalNavigatorProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, Stream<bool>>
    with $FutureModifier<bool>, $StreamProvider<bool> {
  ReaderVerticalNavigatorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'readerVerticalNavigatorProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$readerVerticalNavigatorHash();

  @$internal
  @override
  $StreamProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<bool> create(Ref ref) {
    return readerVerticalNavigator(ref);
  }
}

String _$readerVerticalNavigatorHash() =>
    r'7ae3746aca30b3217f77740b504dbf4d4931a15b';

@ProviderFor(boolSetting)
final boolSettingProvider = BoolSettingFamily._();

final class BoolSettingProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, Stream<bool>>
    with $FutureModifier<bool>, $StreamProvider<bool> {
  BoolSettingProvider._({
    required BoolSettingFamily super.from,
    required SettingDef<bool> super.argument,
  }) : super(
         retry: null,
         name: r'boolSettingProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$boolSettingHash();

  @override
  String toString() {
    return r'boolSettingProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<bool> create(Ref ref) {
    final argument = this.argument as SettingDef<bool>;
    return boolSetting(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is BoolSettingProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$boolSettingHash() => r'483a6bc02f8f61cb073f9495211090121881d97f';

final class BoolSettingFamily extends $Family
    with $FunctionalFamilyOverride<Stream<bool>, SettingDef<bool>> {
  BoolSettingFamily._()
    : super(
        retry: null,
        name: r'boolSettingProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  BoolSettingProvider call(SettingDef<bool> def) =>
      BoolSettingProvider._(argument: def, from: this);

  @override
  String toString() => r'boolSettingProvider';
}

@ProviderFor(intSetting)
final intSettingProvider = IntSettingFamily._();

final class IntSettingProvider
    extends $FunctionalProvider<AsyncValue<int>, int, Stream<int>>
    with $FutureModifier<int>, $StreamProvider<int> {
  IntSettingProvider._({
    required IntSettingFamily super.from,
    required SettingDef<int> super.argument,
  }) : super(
         retry: null,
         name: r'intSettingProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$intSettingHash();

  @override
  String toString() {
    return r'intSettingProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<int> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<int> create(Ref ref) {
    final argument = this.argument as SettingDef<int>;
    return intSetting(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is IntSettingProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$intSettingHash() => r'704a49427d591e6e7ebf25869a55c5997b537ac5';

final class IntSettingFamily extends $Family
    with $FunctionalFamilyOverride<Stream<int>, SettingDef<int>> {
  IntSettingFamily._()
    : super(
        retry: null,
        name: r'intSettingProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  IntSettingProvider call(SettingDef<int> def) =>
      IntSettingProvider._(argument: def, from: this);

  @override
  String toString() => r'intSettingProvider';
}

@ProviderFor(stringSetting)
final stringSettingProvider = StringSettingFamily._();

final class StringSettingProvider
    extends $FunctionalProvider<AsyncValue<String>, String, Stream<String>>
    with $FutureModifier<String>, $StreamProvider<String> {
  StringSettingProvider._({
    required StringSettingFamily super.from,
    required SettingDef<String> super.argument,
  }) : super(
         retry: null,
         name: r'stringSettingProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$stringSettingHash();

  @override
  String toString() {
    return r'stringSettingProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<String> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<String> create(Ref ref) {
    final argument = this.argument as SettingDef<String>;
    return stringSetting(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is StringSettingProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$stringSettingHash() => r'0ef97eb9cb14cfa39d77aab446face789f3671e2';

final class StringSettingFamily extends $Family
    with $FunctionalFamilyOverride<Stream<String>, SettingDef<String>> {
  StringSettingFamily._()
    : super(
        retry: null,
        name: r'stringSettingProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  StringSettingProvider call(SettingDef<String> def) =>
      StringSettingProvider._(argument: def, from: this);

  @override
  String toString() => r'stringSettingProvider';
}

@ProviderFor(appGestures)
final appGesturesProvider = AppGesturesProvider._();

final class AppGesturesProvider
    extends
        $FunctionalProvider<
          AsyncValue<AppGestures>,
          AppGestures,
          Stream<AppGestures>
        >
    with $FutureModifier<AppGestures>, $StreamProvider<AppGestures> {
  AppGesturesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appGesturesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appGesturesHash();

  @$internal
  @override
  $StreamProviderElement<AppGestures> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<AppGestures> create(Ref ref) {
    return appGestures(ref);
  }
}

String _$appGesturesHash() => r'9a3b830b941f968326507d913d044f122287aff0';

@ProviderFor(readerControls)
final readerControlsProvider = ReaderControlsProvider._();

final class ReaderControlsProvider
    extends
        $FunctionalProvider<
          AsyncValue<ReaderControls>,
          ReaderControls,
          Stream<ReaderControls>
        >
    with $FutureModifier<ReaderControls>, $StreamProvider<ReaderControls> {
  ReaderControlsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'readerControlsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$readerControlsHash();

  @$internal
  @override
  $StreamProviderElement<ReaderControls> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<ReaderControls> create(Ref ref) {
    return readerControls(ref);
  }
}

String _$readerControlsHash() => r'3cc62997ba8017d0bf3f3340ec287503a5aa67e0';

@ProviderFor(globalReaderInvertTaps)
final globalReaderInvertTapsProvider = GlobalReaderInvertTapsProvider._();

final class GlobalReaderInvertTapsProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, Stream<bool>>
    with $FutureModifier<bool>, $StreamProvider<bool> {
  GlobalReaderInvertTapsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'globalReaderInvertTapsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$globalReaderInvertTapsHash();

  @$internal
  @override
  $StreamProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<bool> create(Ref ref) {
    return globalReaderInvertTaps(ref);
  }
}

String _$globalReaderInvertTapsHash() =>
    r'de8722a99a0b9e840a0fb4c7aaa3936b04365bbf';

@ProviderFor(navStyle)
final navStyleProvider = NavStyleProvider._();

final class NavStyleProvider
    extends
        $FunctionalProvider<
          AsyncValue<AppNavStyle>,
          AppNavStyle,
          Stream<AppNavStyle>
        >
    with $FutureModifier<AppNavStyle>, $StreamProvider<AppNavStyle> {
  NavStyleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'navStyleProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$navStyleHash();

  @$internal
  @override
  $StreamProviderElement<AppNavStyle> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<AppNavStyle> create(Ref ref) {
    return navStyle(ref);
  }
}

String _$navStyleHash() => r'27dfdb69409118c48476ec37784ff5bf2fc3e1a9';

@ProviderFor(incognitoMode)
final incognitoModeProvider = IncognitoModeProvider._();

final class IncognitoModeProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, Stream<bool>>
    with $FutureModifier<bool>, $StreamProvider<bool> {
  IncognitoModeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'incognitoModeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$incognitoModeHash();

  @$internal
  @override
  $StreamProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<bool> create(Ref ref) {
    return incognitoMode(ref);
  }
}

String _$incognitoModeHash() => r'8149900e824ef3ca256166f686e5fd7d5940104a';

@ProviderFor(libraryUpdateSkip)
final libraryUpdateSkipProvider = LibraryUpdateSkipProvider._();

final class LibraryUpdateSkipProvider
    extends $FunctionalProvider<AsyncValue<int>, int, Stream<int>>
    with $FutureModifier<int>, $StreamProvider<int> {
  LibraryUpdateSkipProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'libraryUpdateSkipProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$libraryUpdateSkipHash();

  @$internal
  @override
  $StreamProviderElement<int> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<int> create(Ref ref) {
    return libraryUpdateSkip(ref);
  }
}

String _$libraryUpdateSkipHash() => r'dbaec8038d1b09c7df178dbc6854ffd2556a6d36';

@ProviderFor(autoLibraryUpdateWifiOnly)
final autoLibraryUpdateWifiOnlyProvider = AutoLibraryUpdateWifiOnlyProvider._();

final class AutoLibraryUpdateWifiOnlyProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, Stream<bool>>
    with $FutureModifier<bool>, $StreamProvider<bool> {
  AutoLibraryUpdateWifiOnlyProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'autoLibraryUpdateWifiOnlyProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$autoLibraryUpdateWifiOnlyHash();

  @$internal
  @override
  $StreamProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<bool> create(Ref ref) {
    return autoLibraryUpdateWifiOnly(ref);
  }
}

String _$autoLibraryUpdateWifiOnlyHash() =>
    r'78154c921c3325c24af9cbb05843a425c3e88563';

@ProviderFor(appLockEnabled)
final appLockEnabledProvider = AppLockEnabledProvider._();

final class AppLockEnabledProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, Stream<bool>>
    with $FutureModifier<bool>, $StreamProvider<bool> {
  AppLockEnabledProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appLockEnabledProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appLockEnabledHash();

  @$internal
  @override
  $StreamProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<bool> create(Ref ref) {
    return appLockEnabled(ref);
  }
}

String _$appLockEnabledHash() => r'abc0d3332ee3ac8ea6866791873490cb07f66c6c';

@ProviderFor(appLockUseBiometric)
final appLockUseBiometricProvider = AppLockUseBiometricProvider._();

final class AppLockUseBiometricProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, Stream<bool>>
    with $FutureModifier<bool>, $StreamProvider<bool> {
  AppLockUseBiometricProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appLockUseBiometricProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appLockUseBiometricHash();

  @$internal
  @override
  $StreamProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<bool> create(Ref ref) {
    return appLockUseBiometric(ref);
  }
}

String _$appLockUseBiometricHash() =>
    r'2b9460a52d6ce3ccfcb8e13f54bc7d4aad465518';

@ProviderFor(appLockGracePeriodMinutes)
final appLockGracePeriodMinutesProvider = AppLockGracePeriodMinutesProvider._();

final class AppLockGracePeriodMinutesProvider
    extends $FunctionalProvider<AsyncValue<int>, int, Stream<int>>
    with $FutureModifier<int>, $StreamProvider<int> {
  AppLockGracePeriodMinutesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appLockGracePeriodMinutesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appLockGracePeriodMinutesHash();

  @$internal
  @override
  $StreamProviderElement<int> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<int> create(Ref ref) {
    return appLockGracePeriodMinutes(ref);
  }
}

String _$appLockGracePeriodMinutesHash() =>
    r'11c9adb0e586f165e79cfd21515751a37034813a';

@ProviderFor(notificationsEnabled)
final notificationsEnabledProvider = NotificationsEnabledProvider._();

final class NotificationsEnabledProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, Stream<bool>>
    with $FutureModifier<bool>, $StreamProvider<bool> {
  NotificationsEnabledProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationsEnabledProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationsEnabledHash();

  @$internal
  @override
  $StreamProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<bool> create(Ref ref) {
    return notificationsEnabled(ref);
  }
}

String _$notificationsEnabledHash() =>
    r'd0118a303359c0a9ce2c57d3611de33fd14c8314';

@ProviderFor(reduceMotion)
final reduceMotionProvider = ReduceMotionProvider._();

final class ReduceMotionProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, Stream<bool>>
    with $FutureModifier<bool>, $StreamProvider<bool> {
  ReduceMotionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reduceMotionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reduceMotionHash();

  @$internal
  @override
  $StreamProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<bool> create(Ref ref) {
    return reduceMotion(ref);
  }
}

String _$reduceMotionHash() => r'cb1985e50fe5638789f9f5afb29b3fe392f25803';

@ProviderFor(globalReaderDualPageMode)
final globalReaderDualPageModeProvider = GlobalReaderDualPageModeProvider._();

final class GlobalReaderDualPageModeProvider
    extends
        $FunctionalProvider<
          AsyncValue<ReaderDualPageMode>,
          ReaderDualPageMode,
          Stream<ReaderDualPageMode>
        >
    with
        $FutureModifier<ReaderDualPageMode>,
        $StreamProvider<ReaderDualPageMode> {
  GlobalReaderDualPageModeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'globalReaderDualPageModeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$globalReaderDualPageModeHash();

  @$internal
  @override
  $StreamProviderElement<ReaderDualPageMode> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<ReaderDualPageMode> create(Ref ref) {
    return globalReaderDualPageMode(ref);
  }
}

String _$globalReaderDualPageModeHash() =>
    r'11c275e0ebe39708af95c74145f4cd9c3f85dc6d';

@ProviderFor(downloadDirectoryPath)
final downloadDirectoryPathProvider = DownloadDirectoryPathProvider._();

final class DownloadDirectoryPathProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, Stream<String?>>
    with $FutureModifier<String?>, $StreamProvider<String?> {
  DownloadDirectoryPathProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'downloadDirectoryPathProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$downloadDirectoryPathHash();

  @$internal
  @override
  $StreamProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<String?> create(Ref ref) {
    return downloadDirectoryPath(ref);
  }
}

String _$downloadDirectoryPathHash() =>
    r'5f88ab3917ae34728b3f8209c2ef429cb1a4c20d';

@ProviderFor(networkTimeoutSeconds)
final networkTimeoutSecondsProvider = NetworkTimeoutSecondsProvider._();

final class NetworkTimeoutSecondsProvider
    extends $FunctionalProvider<AsyncValue<int>, int, Stream<int>>
    with $FutureModifier<int>, $StreamProvider<int> {
  NetworkTimeoutSecondsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'networkTimeoutSecondsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$networkTimeoutSecondsHash();

  @$internal
  @override
  $StreamProviderElement<int> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<int> create(Ref ref) {
    return networkTimeoutSeconds(ref);
  }
}

String _$networkTimeoutSecondsHash() =>
    r'74670cc90af3183f436f1801ec882fa44688c371';

@ProviderFor(networkUserAgent)
final networkUserAgentProvider = NetworkUserAgentProvider._();

final class NetworkUserAgentProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, Stream<String?>>
    with $FutureModifier<String?>, $StreamProvider<String?> {
  NetworkUserAgentProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'networkUserAgentProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$networkUserAgentHash();

  @$internal
  @override
  $StreamProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<String?> create(Ref ref) {
    return networkUserAgent(ref);
  }
}

String _$networkUserAgentHash() => r'e0da7dc298fa5f067f73dcee52e42c9a1a75b974';

@ProviderFor(novelFontFamily)
final novelFontFamilyProvider = NovelFontFamilyProvider._();

final class NovelFontFamilyProvider
    extends
        $FunctionalProvider<
          AsyncValue<ReaderFontFamily>,
          ReaderFontFamily,
          Stream<ReaderFontFamily>
        >
    with $FutureModifier<ReaderFontFamily>, $StreamProvider<ReaderFontFamily> {
  NovelFontFamilyProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'novelFontFamilyProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$novelFontFamilyHash();

  @$internal
  @override
  $StreamProviderElement<ReaderFontFamily> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<ReaderFontFamily> create(Ref ref) {
    return novelFontFamily(ref);
  }
}

String _$novelFontFamilyHash() => r'31403b9ce1263a9a74b88d40cf6f57c5e6295aa3';

@ProviderFor(novelFontSize)
final novelFontSizeProvider = NovelFontSizeProvider._();

final class NovelFontSizeProvider
    extends $FunctionalProvider<AsyncValue<double>, double, Stream<double>>
    with $FutureModifier<double>, $StreamProvider<double> {
  NovelFontSizeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'novelFontSizeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$novelFontSizeHash();

  @$internal
  @override
  $StreamProviderElement<double> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<double> create(Ref ref) {
    return novelFontSize(ref);
  }
}

String _$novelFontSizeHash() => r'e7bacaa132215c9b2f950c027d8e14c7583f819d';

@ProviderFor(novelLineHeight)
final novelLineHeightProvider = NovelLineHeightProvider._();

final class NovelLineHeightProvider
    extends $FunctionalProvider<AsyncValue<double>, double, Stream<double>>
    with $FutureModifier<double>, $StreamProvider<double> {
  NovelLineHeightProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'novelLineHeightProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$novelLineHeightHash();

  @$internal
  @override
  $StreamProviderElement<double> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<double> create(Ref ref) {
    return novelLineHeight(ref);
  }
}

String _$novelLineHeightHash() => r'5cd48f3d0e199501f7c0409e25ea29636a18a351';

@ProviderFor(novelParagraphSpacing)
final novelParagraphSpacingProvider = NovelParagraphSpacingProvider._();

final class NovelParagraphSpacingProvider
    extends $FunctionalProvider<AsyncValue<double>, double, Stream<double>>
    with $FutureModifier<double>, $StreamProvider<double> {
  NovelParagraphSpacingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'novelParagraphSpacingProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$novelParagraphSpacingHash();

  @$internal
  @override
  $StreamProviderElement<double> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<double> create(Ref ref) {
    return novelParagraphSpacing(ref);
  }
}

String _$novelParagraphSpacingHash() =>
    r'd343b30364ab728c16a5f5092a9246a11414a43f';

@ProviderFor(checkForUpdatesOnStartup)
final checkForUpdatesOnStartupProvider = CheckForUpdatesOnStartupProvider._();

final class CheckForUpdatesOnStartupProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, Stream<bool>>
    with $FutureModifier<bool>, $StreamProvider<bool> {
  CheckForUpdatesOnStartupProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'checkForUpdatesOnStartupProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$checkForUpdatesOnStartupHash();

  @$internal
  @override
  $StreamProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<bool> create(Ref ref) {
    return checkForUpdatesOnStartup(ref);
  }
}

String _$checkForUpdatesOnStartupHash() =>
    r'8266e3db9294b8b6974600c04c4b64c8de1d7be6';

@ProviderFor(globalReaderColumnWidth)
final globalReaderColumnWidthProvider = GlobalReaderColumnWidthProvider._();

final class GlobalReaderColumnWidthProvider
    extends
        $FunctionalProvider<
          AsyncValue<ReaderColumnWidth>,
          ReaderColumnWidth,
          Stream<ReaderColumnWidth>
        >
    with
        $FutureModifier<ReaderColumnWidth>,
        $StreamProvider<ReaderColumnWidth> {
  GlobalReaderColumnWidthProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'globalReaderColumnWidthProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$globalReaderColumnWidthHash();

  @$internal
  @override
  $StreamProviderElement<ReaderColumnWidth> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<ReaderColumnWidth> create(Ref ref) {
    return globalReaderColumnWidth(ref);
  }
}

String _$globalReaderColumnWidthHash() =>
    r'e94905c32440998bc0a8106f9544e46a21b5bbcd';

@ProviderFor(globalReaderImageQuality)
final globalReaderImageQualityProvider = GlobalReaderImageQualityProvider._();

final class GlobalReaderImageQualityProvider
    extends
        $FunctionalProvider<
          AsyncValue<ReaderImageQuality>,
          ReaderImageQuality,
          Stream<ReaderImageQuality>
        >
    with
        $FutureModifier<ReaderImageQuality>,
        $StreamProvider<ReaderImageQuality> {
  GlobalReaderImageQualityProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'globalReaderImageQualityProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$globalReaderImageQualityHash();

  @$internal
  @override
  $StreamProviderElement<ReaderImageQuality> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<ReaderImageQuality> create(Ref ref) {
    return globalReaderImageQuality(ref);
  }
}

String _$globalReaderImageQualityHash() =>
    r'de55e03e89db2b6ac59dcae43863d29d0cb7133a';

@ProviderFor(showPerformanceOverlay)
final showPerformanceOverlayProvider = ShowPerformanceOverlayProvider._();

final class ShowPerformanceOverlayProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, Stream<bool>>
    with $FutureModifier<bool>, $StreamProvider<bool> {
  ShowPerformanceOverlayProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'showPerformanceOverlayProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$showPerformanceOverlayHash();

  @$internal
  @override
  $StreamProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<bool> create(Ref ref) {
    return showPerformanceOverlay(ref);
  }
}

String _$showPerformanceOverlayHash() =>
    r'867b8f6b9c76a0c2dd727ba77c62cd377c6a5822';
