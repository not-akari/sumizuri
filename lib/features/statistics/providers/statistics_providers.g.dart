// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'statistics_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CalendarMonthNotifier)
final calendarMonthProvider = CalendarMonthNotifierProvider._();

final class CalendarMonthNotifierProvider
    extends $NotifierProvider<CalendarMonthNotifier, DateTime> {
  CalendarMonthNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calendarMonthProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calendarMonthNotifierHash();

  @$internal
  @override
  CalendarMonthNotifier create() => CalendarMonthNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTime value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTime>(value),
    );
  }
}

String _$calendarMonthNotifierHash() =>
    r'be7191bb846ae99b814eea5a198688d6e903541a';

abstract class _$CalendarMonthNotifier extends $Notifier<DateTime> {
  DateTime build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<DateTime, DateTime>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DateTime, DateTime>,
              DateTime,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(CalendarCategory)
final calendarCategoryProvider = CalendarCategoryProvider._();

final class CalendarCategoryProvider
    extends $NotifierProvider<CalendarCategory, int?> {
  CalendarCategoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calendarCategoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calendarCategoryHash();

  @$internal
  @override
  CalendarCategory create() => CalendarCategory();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int?>(value),
    );
  }
}

String _$calendarCategoryHash() => r'8dae62d7f4018349c9e142f16aafaaa41a418c34';

abstract class _$CalendarCategory extends $Notifier<int?> {
  int? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<int?, int?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int?, int?>,
              int?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(CalendarSelectedDateNotifier)
final calendarSelectedDateProvider = CalendarSelectedDateNotifierProvider._();

final class CalendarSelectedDateNotifierProvider
    extends $NotifierProvider<CalendarSelectedDateNotifier, DateTime> {
  CalendarSelectedDateNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calendarSelectedDateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calendarSelectedDateNotifierHash();

  @$internal
  @override
  CalendarSelectedDateNotifier create() => CalendarSelectedDateNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTime value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTime>(value),
    );
  }
}

String _$calendarSelectedDateNotifierHash() =>
    r'437fe804a248427586714353880211f163b35691';

abstract class _$CalendarSelectedDateNotifier extends $Notifier<DateTime> {
  DateTime build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<DateTime, DateTime>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DateTime, DateTime>,
              DateTime,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(calendarSelectedDayReleases)
final calendarSelectedDayReleasesProvider =
    CalendarSelectedDayReleasesProvider._();

final class CalendarSelectedDayReleasesProvider
    extends
        $FunctionalProvider<
          List<UpcomingRelease>,
          List<UpcomingRelease>,
          List<UpcomingRelease>
        >
    with $Provider<List<UpcomingRelease>> {
  CalendarSelectedDayReleasesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calendarSelectedDayReleasesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calendarSelectedDayReleasesHash();

  @$internal
  @override
  $ProviderElement<List<UpcomingRelease>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<UpcomingRelease> create(Ref ref) {
    return calendarSelectedDayReleases(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<UpcomingRelease> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<UpcomingRelease>>(value),
    );
  }
}

String _$calendarSelectedDayReleasesHash() =>
    r'2b1293ad3344a54d3a894aa9e24ac6b5112edfdd';
