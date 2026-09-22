// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'translation_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(translationRepository)
final translationRepositoryProvider = TranslationRepositoryProvider._();

final class TranslationRepositoryProvider
    extends
        $FunctionalProvider<
          TranslationRepository,
          TranslationRepository,
          TranslationRepository
        >
    with $Provider<TranslationRepository> {
  TranslationRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'translationRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$translationRepositoryHash();

  @$internal
  @override
  $ProviderElement<TranslationRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TranslationRepository create(Ref ref) {
    return translationRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TranslationRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TranslationRepository>(value),
    );
  }
}

String _$translationRepositoryHash() =>
    r'66727dfb7856964669da2a911c0766f6f75a816e';

@ProviderFor(sourceTranslationEntries)
final sourceTranslationEntriesProvider = SourceTranslationEntriesProvider._();

final class SourceTranslationEntriesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TranslationEntry>>,
          List<TranslationEntry>,
          FutureOr<List<TranslationEntry>>
        >
    with
        $FutureModifier<List<TranslationEntry>>,
        $FutureProvider<List<TranslationEntry>> {
  SourceTranslationEntriesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sourceTranslationEntriesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sourceTranslationEntriesHash();

  @$internal
  @override
  $FutureProviderElement<List<TranslationEntry>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<TranslationEntry>> create(Ref ref) {
    return sourceTranslationEntries(ref);
  }
}

String _$sourceTranslationEntriesHash() =>
    r'72a517012dd36431d992cda90395baef207c1f48';

@ProviderFor(draftLocales)
final draftLocalesProvider = DraftLocalesProvider._();

final class DraftLocalesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<String>>,
          List<String>,
          FutureOr<List<String>>
        >
    with $FutureModifier<List<String>>, $FutureProvider<List<String>> {
  DraftLocalesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'draftLocalesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$draftLocalesHash();

  @$internal
  @override
  $FutureProviderElement<List<String>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<String>> create(Ref ref) {
    return draftLocales(ref);
  }
}

String _$draftLocalesHash() => r'b473a1631b39cd299fcfa812219f0c4f58c05256';

@ProviderFor(AppLocale)
final appLocaleProvider = AppLocaleProvider._();

final class AppLocaleProvider
    extends $AsyncNotifierProvider<AppLocale, String?> {
  AppLocaleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appLocaleProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appLocaleHash();

  @$internal
  @override
  AppLocale create() => AppLocale();
}

String _$appLocaleHash() => r'3bd19c177f87f229181a1781411a2a62fa291472';

abstract class _$AppLocale extends $AsyncNotifier<String?> {
  FutureOr<String?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<String?>, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<String?>, String?>,
              AsyncValue<String?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(sumizuriLocalizationsDelegate)
final sumizuriLocalizationsDelegateProvider =
    SumizuriLocalizationsDelegateProvider._();

final class SumizuriLocalizationsDelegateProvider
    extends
        $FunctionalProvider<
          SumizuriLocalizationsDelegate,
          SumizuriLocalizationsDelegate,
          SumizuriLocalizationsDelegate
        >
    with $Provider<SumizuriLocalizationsDelegate> {
  SumizuriLocalizationsDelegateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sumizuriLocalizationsDelegateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sumizuriLocalizationsDelegateHash();

  @$internal
  @override
  $ProviderElement<SumizuriLocalizationsDelegate> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SumizuriLocalizationsDelegate create(Ref ref) {
    return sumizuriLocalizationsDelegate(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SumizuriLocalizationsDelegate value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SumizuriLocalizationsDelegate>(
        value,
      ),
    );
  }
}

String _$sumizuriLocalizationsDelegateHash() =>
    r'fe2b96a02359bd282511ba03bbb705c9bf98f18f';

@ProviderFor(ActiveDraftLocale)
final activeDraftLocaleProvider = ActiveDraftLocaleProvider._();

final class ActiveDraftLocaleProvider
    extends $NotifierProvider<ActiveDraftLocale, String?> {
  ActiveDraftLocaleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeDraftLocaleProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeDraftLocaleHash();

  @$internal
  @override
  ActiveDraftLocale create() => ActiveDraftLocale();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$activeDraftLocaleHash() => r'b7ac34b2a4db4955a12e68593c0cebf6f0069df2';

abstract class _$ActiveDraftLocale extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(TranslationDraftNotifier)
final translationDraftProvider = TranslationDraftNotifierFamily._();

final class TranslationDraftNotifierProvider
    extends
        $AsyncNotifierProvider<TranslationDraftNotifier, Map<String, String>> {
  TranslationDraftNotifierProvider._({
    required TranslationDraftNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'translationDraftProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$translationDraftNotifierHash();

  @override
  String toString() {
    return r'translationDraftProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  TranslationDraftNotifier create() => TranslationDraftNotifier();

  @override
  bool operator ==(Object other) {
    return other is TranslationDraftNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$translationDraftNotifierHash() =>
    r'63912164b115982c3495890d8c37626cb44a6b3c';

final class TranslationDraftNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          TranslationDraftNotifier,
          AsyncValue<Map<String, String>>,
          Map<String, String>,
          FutureOr<Map<String, String>>,
          String
        > {
  TranslationDraftNotifierFamily._()
    : super(
        retry: null,
        name: r'translationDraftProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  TranslationDraftNotifierProvider call(String locale) =>
      TranslationDraftNotifierProvider._(argument: locale, from: this);

  @override
  String toString() => r'translationDraftProvider';
}

abstract class _$TranslationDraftNotifier
    extends $AsyncNotifier<Map<String, String>> {
  late final _$args = ref.$arg as String;
  String get locale => _$args;

  FutureOr<Map<String, String>> build(String locale);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<Map<String, String>>, Map<String, String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Map<String, String>>, Map<String, String>>,
              AsyncValue<Map<String, String>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

@ProviderFor(activeDraftEntries)
final activeDraftEntriesProvider = ActiveDraftEntriesFamily._();

final class ActiveDraftEntriesProvider
    extends
        $FunctionalProvider<
          List<TranslationEntry>,
          List<TranslationEntry>,
          List<TranslationEntry>
        >
    with $Provider<List<TranslationEntry>> {
  ActiveDraftEntriesProvider._({
    required ActiveDraftEntriesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'activeDraftEntriesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$activeDraftEntriesHash();

  @override
  String toString() {
    return r'activeDraftEntriesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<List<TranslationEntry>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<TranslationEntry> create(Ref ref) {
    final argument = this.argument as String;
    return activeDraftEntries(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<TranslationEntry> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<TranslationEntry>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ActiveDraftEntriesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$activeDraftEntriesHash() =>
    r'f7c10a1d3d3c0fec95e847be9f84c5f691bd5b8c';

final class ActiveDraftEntriesFamily extends $Family
    with $FunctionalFamilyOverride<List<TranslationEntry>, String> {
  ActiveDraftEntriesFamily._()
    : super(
        retry: null,
        name: r'activeDraftEntriesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ActiveDraftEntriesProvider call(String locale) =>
      ActiveDraftEntriesProvider._(argument: locale, from: this);

  @override
  String toString() => r'activeDraftEntriesProvider';
}
