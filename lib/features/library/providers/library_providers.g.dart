// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'library_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(libraryRepository)
final libraryRepositoryProvider = LibraryRepositoryProvider._();

final class LibraryRepositoryProvider
    extends
        $FunctionalProvider<
          LibraryRepository,
          LibraryRepository,
          LibraryRepository
        >
    with $Provider<LibraryRepository> {
  LibraryRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'libraryRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$libraryRepositoryHash();

  @$internal
  @override
  $ProviderElement<LibraryRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  LibraryRepository create(Ref ref) {
    return libraryRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LibraryRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LibraryRepository>(value),
    );
  }
}

String _$libraryRepositoryHash() => r'82956da1269739a1513943fe3cbdf64b61ebadf4';

@ProviderFor(libraryEntries)
final libraryEntriesProvider = LibraryEntriesFamily._();

final class LibraryEntriesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<LibraryEntrySummary>>,
          List<LibraryEntrySummary>,
          Stream<List<LibraryEntrySummary>>
        >
    with
        $FutureModifier<List<LibraryEntrySummary>>,
        $StreamProvider<List<LibraryEntrySummary>> {
  LibraryEntriesProvider._({
    required LibraryEntriesFamily super.from,
    required MediaType? super.argument,
  }) : super(
         retry: null,
         name: r'libraryEntriesProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$libraryEntriesHash();

  @override
  String toString() {
    return r'libraryEntriesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<LibraryEntrySummary>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<LibraryEntrySummary>> create(Ref ref) {
    final argument = this.argument as MediaType?;
    return libraryEntries(ref, mediaType: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is LibraryEntriesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$libraryEntriesHash() => r'b3913ee8a79f69dfbdb70f2491759cc505b159d3';

final class LibraryEntriesFamily extends $Family
    with
        $FunctionalFamilyOverride<
          Stream<List<LibraryEntrySummary>>,
          MediaType?
        > {
  LibraryEntriesFamily._()
    : super(
        retry: null,
        name: r'libraryEntriesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  LibraryEntriesProvider call({MediaType? mediaType}) =>
      LibraryEntriesProvider._(argument: mediaType, from: this);

  @override
  String toString() => r'libraryEntriesProvider';
}

@ProviderFor(entriesNeedingMigration)
final entriesNeedingMigrationProvider = EntriesNeedingMigrationProvider._();

final class EntriesNeedingMigrationProvider
    extends
        $FunctionalProvider<
          Map<MediaType, List<LibraryEntrySummary>>,
          Map<MediaType, List<LibraryEntrySummary>>,
          Map<MediaType, List<LibraryEntrySummary>>
        >
    with $Provider<Map<MediaType, List<LibraryEntrySummary>>> {
  EntriesNeedingMigrationProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'entriesNeedingMigrationProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$entriesNeedingMigrationHash();

  @$internal
  @override
  $ProviderElement<Map<MediaType, List<LibraryEntrySummary>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Map<MediaType, List<LibraryEntrySummary>> create(Ref ref) {
    return entriesNeedingMigration(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<MediaType, List<LibraryEntrySummary>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<Map<MediaType, List<LibraryEntrySummary>>>(value),
    );
  }
}

String _$entriesNeedingMigrationHash() =>
    r'dc8f0e8c8cc3b670124a1f07ffc9d4e96095185f';

@ProviderFor(libraryExternalIds)
final libraryExternalIdsProvider = LibraryExternalIdsFamily._();

final class LibraryExternalIdsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Set<String>>,
          Set<String>,
          Stream<Set<String>>
        >
    with $FutureModifier<Set<String>>, $StreamProvider<Set<String>> {
  LibraryExternalIdsProvider._({
    required LibraryExternalIdsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'libraryExternalIdsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$libraryExternalIdsHash();

  @override
  String toString() {
    return r'libraryExternalIdsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<Set<String>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Set<String>> create(Ref ref) {
    final argument = this.argument as String;
    return libraryExternalIds(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is LibraryExternalIdsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$libraryExternalIdsHash() =>
    r'47da3aa5f97f64bbedf2e39ab2f0ceac1cc68bbb';

final class LibraryExternalIdsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<Set<String>>, String> {
  LibraryExternalIdsFamily._()
    : super(
        retry: null,
        name: r'libraryExternalIdsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  LibraryExternalIdsProvider call(String sourceId) =>
      LibraryExternalIdsProvider._(argument: sourceId, from: this);

  @override
  String toString() => r'libraryExternalIdsProvider';
}

@ProviderFor(libraryUpdates)
final libraryUpdatesProvider = LibraryUpdatesFamily._();

final class LibraryUpdatesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<UpdateChapterSummary>>,
          List<UpdateChapterSummary>,
          Stream<List<UpdateChapterSummary>>
        >
    with
        $FutureModifier<List<UpdateChapterSummary>>,
        $StreamProvider<List<UpdateChapterSummary>> {
  LibraryUpdatesProvider._({
    required LibraryUpdatesFamily super.from,
    required MediaType? super.argument,
  }) : super(
         retry: null,
         name: r'libraryUpdatesProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$libraryUpdatesHash();

  @override
  String toString() {
    return r'libraryUpdatesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<UpdateChapterSummary>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<UpdateChapterSummary>> create(Ref ref) {
    final argument = this.argument as MediaType?;
    return libraryUpdates(ref, mediaType: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is LibraryUpdatesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$libraryUpdatesHash() => r'0fc26b6a4ce2e9bbfada9d3608b78419e168f330';

final class LibraryUpdatesFamily extends $Family
    with
        $FunctionalFamilyOverride<
          Stream<List<UpdateChapterSummary>>,
          MediaType?
        > {
  LibraryUpdatesFamily._()
    : super(
        retry: null,
        name: r'libraryUpdatesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  LibraryUpdatesProvider call({MediaType? mediaType}) =>
      LibraryUpdatesProvider._(argument: mediaType, from: this);

  @override
  String toString() => r'libraryUpdatesProvider';
}

@ProviderFor(libraryHistory)
final libraryHistoryProvider = LibraryHistoryFamily._();

final class LibraryHistoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<HistoryChapterSummary>>,
          List<HistoryChapterSummary>,
          Stream<List<HistoryChapterSummary>>
        >
    with
        $FutureModifier<List<HistoryChapterSummary>>,
        $StreamProvider<List<HistoryChapterSummary>> {
  LibraryHistoryProvider._({
    required LibraryHistoryFamily super.from,
    required MediaType? super.argument,
  }) : super(
         retry: null,
         name: r'libraryHistoryProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$libraryHistoryHash();

  @override
  String toString() {
    return r'libraryHistoryProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<HistoryChapterSummary>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<HistoryChapterSummary>> create(Ref ref) {
    final argument = this.argument as MediaType?;
    return libraryHistory(ref, mediaType: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is LibraryHistoryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$libraryHistoryHash() => r'cd6a68a0a8160499924f183fcf4e8194cdd603e7';

final class LibraryHistoryFamily extends $Family
    with
        $FunctionalFamilyOverride<
          Stream<List<HistoryChapterSummary>>,
          MediaType?
        > {
  LibraryHistoryFamily._()
    : super(
        retry: null,
        name: r'libraryHistoryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  LibraryHistoryProvider call({MediaType? mediaType}) =>
      LibraryHistoryProvider._(argument: mediaType, from: this);

  @override
  String toString() => r'libraryHistoryProvider';
}

@ProviderFor(allChapterDates)
final allChapterDatesProvider = AllChapterDatesFamily._();

final class AllChapterDatesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<UpdateChapterSummary>>,
          List<UpdateChapterSummary>,
          Stream<List<UpdateChapterSummary>>
        >
    with
        $FutureModifier<List<UpdateChapterSummary>>,
        $StreamProvider<List<UpdateChapterSummary>> {
  AllChapterDatesProvider._({
    required AllChapterDatesFamily super.from,
    required MediaType? super.argument,
  }) : super(
         retry: null,
         name: r'allChapterDatesProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$allChapterDatesHash();

  @override
  String toString() {
    return r'allChapterDatesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<UpdateChapterSummary>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<UpdateChapterSummary>> create(Ref ref) {
    final argument = this.argument as MediaType?;
    return allChapterDates(ref, mediaType: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is AllChapterDatesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$allChapterDatesHash() => r'6e290696df64eeaf8d4438d8bd77aa69b80c50ab';

final class AllChapterDatesFamily extends $Family
    with
        $FunctionalFamilyOverride<
          Stream<List<UpdateChapterSummary>>,
          MediaType?
        > {
  AllChapterDatesFamily._()
    : super(
        retry: null,
        name: r'allChapterDatesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  AllChapterDatesProvider call({MediaType? mediaType}) =>
      AllChapterDatesProvider._(argument: mediaType, from: this);

  @override
  String toString() => r'allChapterDatesProvider';
}

@ProviderFor(chapterBookmarked)
final chapterBookmarkedProvider = ChapterBookmarkedFamily._();

final class ChapterBookmarkedProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, Stream<bool>>
    with $FutureModifier<bool>, $StreamProvider<bool> {
  ChapterBookmarkedProvider._({
    required ChapterBookmarkedFamily super.from,
    required (int, String) super.argument,
  }) : super(
         retry: null,
         name: r'chapterBookmarkedProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$chapterBookmarkedHash();

  @override
  String toString() {
    return r'chapterBookmarkedProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $StreamProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<bool> create(Ref ref) {
    final argument = this.argument as (int, String);
    return chapterBookmarked(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is ChapterBookmarkedProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$chapterBookmarkedHash() => r'7cd5a1afe4fea8d2a69e3f53b35a3dda32c3d1d2';

final class ChapterBookmarkedFamily extends $Family
    with $FunctionalFamilyOverride<Stream<bool>, (int, String)> {
  ChapterBookmarkedFamily._()
    : super(
        retry: null,
        name: r'chapterBookmarkedProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ChapterBookmarkedProvider call(int libraryEntryId, String chapterUrl) =>
      ChapterBookmarkedProvider._(
        argument: (libraryEntryId, chapterUrl),
        from: this,
      );

  @override
  String toString() => r'chapterBookmarkedProvider';
}

@ProviderFor(furthestRead)
final furthestReadProvider = FurthestReadFamily._();

final class FurthestReadProvider
    extends $FunctionalProvider<AsyncValue<double?>, double?, Stream<double?>>
    with $FutureModifier<double?>, $StreamProvider<double?> {
  FurthestReadProvider._({
    required FurthestReadFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'furthestReadProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$furthestReadHash();

  @override
  String toString() {
    return r'furthestReadProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<double?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<double?> create(Ref ref) {
    final argument = this.argument as int;
    return furthestRead(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is FurthestReadProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$furthestReadHash() => r'56a6fded9925d17fe1dd850eaacc07a87cce4411';

final class FurthestReadFamily extends $Family
    with $FunctionalFamilyOverride<Stream<double?>, int> {
  FurthestReadFamily._()
    : super(
        retry: null,
        name: r'furthestReadProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  FurthestReadProvider call(int libraryEntryId) =>
      FurthestReadProvider._(argument: libraryEntryId, from: this);

  @override
  String toString() => r'furthestReadProvider';
}

/// Batch furthestRead provider keyed by a comma-joined id list for caching.

@ProviderFor(furthestReadMany)
final furthestReadManyProvider = FurthestReadManyFamily._();

/// Batch furthestRead provider keyed by a comma-joined id list for caching.

final class FurthestReadManyProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<int, double?>>,
          Map<int, double?>,
          Stream<Map<int, double?>>
        >
    with
        $FutureModifier<Map<int, double?>>,
        $StreamProvider<Map<int, double?>> {
  /// Batch furthestRead provider keyed by a comma-joined id list for caching.
  FurthestReadManyProvider._({
    required FurthestReadManyFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'furthestReadManyProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$furthestReadManyHash();

  @override
  String toString() {
    return r'furthestReadManyProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<Map<int, double?>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Map<int, double?>> create(Ref ref) {
    final argument = this.argument as String;
    return furthestReadMany(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is FurthestReadManyProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$furthestReadManyHash() => r'2c1046c5ffd285a1865c9340406ce95923e8603e';

/// Batch furthestRead provider keyed by a comma-joined id list for caching.

final class FurthestReadManyFamily extends $Family
    with $FunctionalFamilyOverride<Stream<Map<int, double?>>, String> {
  FurthestReadManyFamily._()
    : super(
        retry: null,
        name: r'furthestReadManyProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Batch furthestRead provider keyed by a comma-joined id list for caching.

  FurthestReadManyProvider call(String sortedIdsKey) =>
      FurthestReadManyProvider._(argument: sortedIdsKey, from: this);

  @override
  String toString() => r'furthestReadManyProvider';
}

@ProviderFor(timelineBursts)
final timelineBurstsProvider = TimelineBurstsFamily._();

final class TimelineBurstsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ReadingTimelineBurst>>,
          List<ReadingTimelineBurst>,
          Stream<List<ReadingTimelineBurst>>
        >
    with
        $FutureModifier<List<ReadingTimelineBurst>>,
        $StreamProvider<List<ReadingTimelineBurst>> {
  TimelineBurstsProvider._({
    required TimelineBurstsFamily super.from,
    required ({int? libraryEntryId, MediaType? mediaType}) super.argument,
  }) : super(
         retry: null,
         name: r'timelineBurstsProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$timelineBurstsHash();

  @override
  String toString() {
    return r'timelineBurstsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $StreamProviderElement<List<ReadingTimelineBurst>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<ReadingTimelineBurst>> create(Ref ref) {
    final argument =
        this.argument as ({int? libraryEntryId, MediaType? mediaType});
    return timelineBursts(
      ref,
      libraryEntryId: argument.libraryEntryId,
      mediaType: argument.mediaType,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TimelineBurstsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$timelineBurstsHash() => r'a0ce53486052d8cd3a48b60983e966af5bb538c7';

final class TimelineBurstsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          Stream<List<ReadingTimelineBurst>>,
          ({int? libraryEntryId, MediaType? mediaType})
        > {
  TimelineBurstsFamily._()
    : super(
        retry: null,
        name: r'timelineBurstsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  TimelineBurstsProvider call({int? libraryEntryId, MediaType? mediaType}) =>
      TimelineBurstsProvider._(
        argument: (libraryEntryId: libraryEntryId, mediaType: mediaType),
        from: this,
      );

  @override
  String toString() => r'timelineBurstsProvider';
}

@ProviderFor(timelineSessions)
final timelineSessionsProvider = TimelineSessionsFamily._();

final class TimelineSessionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ReadingSessionRecord>>,
          List<ReadingSessionRecord>,
          Stream<List<ReadingSessionRecord>>
        >
    with
        $FutureModifier<List<ReadingSessionRecord>>,
        $StreamProvider<List<ReadingSessionRecord>> {
  TimelineSessionsProvider._({
    required TimelineSessionsFamily super.from,
    required ({int? libraryEntryId, MediaType? mediaType}) super.argument,
  }) : super(
         retry: null,
         name: r'timelineSessionsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$timelineSessionsHash();

  @override
  String toString() {
    return r'timelineSessionsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $StreamProviderElement<List<ReadingSessionRecord>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<ReadingSessionRecord>> create(Ref ref) {
    final argument =
        this.argument as ({int? libraryEntryId, MediaType? mediaType});
    return timelineSessions(
      ref,
      libraryEntryId: argument.libraryEntryId,
      mediaType: argument.mediaType,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TimelineSessionsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$timelineSessionsHash() => r'307aec57e57cb99562d65464ee476c11deb579c1';

final class TimelineSessionsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          Stream<List<ReadingSessionRecord>>,
          ({int? libraryEntryId, MediaType? mediaType})
        > {
  TimelineSessionsFamily._()
    : super(
        retry: null,
        name: r'timelineSessionsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TimelineSessionsProvider call({int? libraryEntryId, MediaType? mediaType}) =>
      TimelineSessionsProvider._(
        argument: (libraryEntryId: libraryEntryId, mediaType: mediaType),
        from: this,
      );

  @override
  String toString() => r'timelineSessionsProvider';
}

@ProviderFor(allReadingSessions)
final allReadingSessionsProvider = AllReadingSessionsProvider._();

final class AllReadingSessionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ReadingSessionRecord>>,
          List<ReadingSessionRecord>,
          Stream<List<ReadingSessionRecord>>
        >
    with
        $FutureModifier<List<ReadingSessionRecord>>,
        $StreamProvider<List<ReadingSessionRecord>> {
  AllReadingSessionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'allReadingSessionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$allReadingSessionsHash();

  @$internal
  @override
  $StreamProviderElement<List<ReadingSessionRecord>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<ReadingSessionRecord>> create(Ref ref) {
    return allReadingSessions(ref);
  }
}

String _$allReadingSessionsHash() =>
    r'60f5b67bcac6760b9a7c5d3e972c893efa76bd67';

@ProviderFor(customCoverPath)
final customCoverPathProvider = CustomCoverPathFamily._();

final class CustomCoverPathProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, Stream<String?>>
    with $FutureModifier<String?>, $StreamProvider<String?> {
  CustomCoverPathProvider._({
    required CustomCoverPathFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'customCoverPathProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$customCoverPathHash();

  @override
  String toString() {
    return r'customCoverPathProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<String?> create(Ref ref) {
    final argument = this.argument as int;
    return customCoverPath(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CustomCoverPathProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$customCoverPathHash() => r'80c06d32c87becdef152eda775cf99f24304c087';

final class CustomCoverPathFamily extends $Family
    with $FunctionalFamilyOverride<Stream<String?>, int> {
  CustomCoverPathFamily._()
    : super(
        retry: null,
        name: r'customCoverPathProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CustomCoverPathProvider call(int entryId) =>
      CustomCoverPathProvider._(argument: entryId, from: this);

  @override
  String toString() => r'customCoverPathProvider';
}

@ProviderFor(libraryCategories)
final libraryCategoriesProvider = LibraryCategoriesFamily._();

final class LibraryCategoriesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Category>>,
          List<Category>,
          Stream<List<Category>>
        >
    with $FutureModifier<List<Category>>, $StreamProvider<List<Category>> {
  LibraryCategoriesProvider._({
    required LibraryCategoriesFamily super.from,
    required MediaType? super.argument,
  }) : super(
         retry: null,
         name: r'libraryCategoriesProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$libraryCategoriesHash();

  @override
  String toString() {
    return r'libraryCategoriesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<Category>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Category>> create(Ref ref) {
    final argument = this.argument as MediaType?;
    return libraryCategories(ref, mediaType: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is LibraryCategoriesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$libraryCategoriesHash() => r'8faa6fab2c3641ef9cdedf6e10d3bed4043ca9f1';

final class LibraryCategoriesFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<Category>>, MediaType?> {
  LibraryCategoriesFamily._()
    : super(
        retry: null,
        name: r'libraryCategoriesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  LibraryCategoriesProvider call({MediaType? mediaType}) =>
      LibraryCategoriesProvider._(argument: mediaType, from: this);

  @override
  String toString() => r'libraryCategoriesProvider';
}

@ProviderFor(visibleCategories)
final visibleCategoriesProvider = VisibleCategoriesFamily._();

final class VisibleCategoriesProvider
    extends $FunctionalProvider<List<Category>, List<Category>, List<Category>>
    with $Provider<List<Category>> {
  VisibleCategoriesProvider._({
    required VisibleCategoriesFamily super.from,
    required MediaType? super.argument,
  }) : super(
         retry: null,
         name: r'visibleCategoriesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$visibleCategoriesHash();

  @override
  String toString() {
    return r'visibleCategoriesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<List<Category>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<Category> create(Ref ref) {
    final argument = this.argument as MediaType?;
    return visibleCategories(ref, mediaType: argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Category> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Category>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is VisibleCategoriesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$visibleCategoriesHash() => r'413df3643dd945664c6374ed02462d2452e8e2a7';

final class VisibleCategoriesFamily extends $Family
    with $FunctionalFamilyOverride<List<Category>, MediaType?> {
  VisibleCategoriesFamily._()
    : super(
        retry: null,
        name: r'visibleCategoriesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  VisibleCategoriesProvider call({MediaType? mediaType}) =>
      VisibleCategoriesProvider._(argument: mediaType, from: this);

  @override
  String toString() => r'visibleCategoriesProvider';
}

@ProviderFor(allEntryCategoryIds)
final allEntryCategoryIdsProvider = AllEntryCategoryIdsProvider._();

final class AllEntryCategoryIdsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<int, Set<int>>>,
          Map<int, Set<int>>,
          Stream<Map<int, Set<int>>>
        >
    with
        $FutureModifier<Map<int, Set<int>>>,
        $StreamProvider<Map<int, Set<int>>> {
  AllEntryCategoryIdsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'allEntryCategoryIdsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$allEntryCategoryIdsHash();

  @$internal
  @override
  $StreamProviderElement<Map<int, Set<int>>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Map<int, Set<int>>> create(Ref ref) {
    return allEntryCategoryIds(ref);
  }
}

String _$allEntryCategoryIdsHash() =>
    r'60cbe4880c42c8951a92accdaa52b5587d85cc92';

@ProviderFor(chapterLocalPath)
final chapterLocalPathProvider = ChapterLocalPathFamily._();

final class ChapterLocalPathProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, Stream<String?>>
    with $FutureModifier<String?>, $StreamProvider<String?> {
  ChapterLocalPathProvider._({
    required ChapterLocalPathFamily super.from,
    required (int, String) super.argument,
  }) : super(
         retry: null,
         name: r'chapterLocalPathProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$chapterLocalPathHash();

  @override
  String toString() {
    return r'chapterLocalPathProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $StreamProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<String?> create(Ref ref) {
    final argument = this.argument as (int, String);
    return chapterLocalPath(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is ChapterLocalPathProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$chapterLocalPathHash() => r'9ea0434b5c7103091dfe7ca8f903b496bb4692c8';

final class ChapterLocalPathFamily extends $Family
    with $FunctionalFamilyOverride<Stream<String?>, (int, String)> {
  ChapterLocalPathFamily._()
    : super(
        retry: null,
        name: r'chapterLocalPathProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ChapterLocalPathProvider call(int libraryEntryId, String chapterUrl) =>
      ChapterLocalPathProvider._(
        argument: (libraryEntryId, chapterUrl),
        from: this,
      );

  @override
  String toString() => r'chapterLocalPathProvider';
}

@ProviderFor(downloadedEntries)
final downloadedEntriesProvider = DownloadedEntriesProvider._();

final class DownloadedEntriesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<DownloadedEntry>>,
          List<DownloadedEntry>,
          Stream<List<DownloadedEntry>>
        >
    with
        $FutureModifier<List<DownloadedEntry>>,
        $StreamProvider<List<DownloadedEntry>> {
  DownloadedEntriesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'downloadedEntriesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$downloadedEntriesHash();

  @$internal
  @override
  $StreamProviderElement<List<DownloadedEntry>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<DownloadedEntry>> create(Ref ref) {
    return downloadedEntries(ref);
  }
}

String _$downloadedEntriesHash() => r'ba03390c9bf73b67a715a3d9009be25002918f2a';

@ProviderFor(entryBranches)
final entryBranchesProvider = EntryBranchesFamily._();

final class EntryBranchesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<EntryBranch>>,
          List<EntryBranch>,
          Stream<List<EntryBranch>>
        >
    with
        $FutureModifier<List<EntryBranch>>,
        $StreamProvider<List<EntryBranch>> {
  EntryBranchesProvider._({
    required EntryBranchesFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'entryBranchesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$entryBranchesHash();

  @override
  String toString() {
    return r'entryBranchesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<EntryBranch>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<EntryBranch>> create(Ref ref) {
    final argument = this.argument as int;
    return entryBranches(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is EntryBranchesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$entryBranchesHash() => r'e77331eac9819fbe6aa7a60d60968cee63b70a31';

final class EntryBranchesFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<EntryBranch>>, int> {
  EntryBranchesFamily._()
    : super(
        retry: null,
        name: r'entryBranchesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  EntryBranchesProvider call(int libraryEntryId) =>
      EntryBranchesProvider._(argument: libraryEntryId, from: this);

  @override
  String toString() => r'entryBranchesProvider';
}

@ProviderFor(activeBranchId)
final activeBranchIdProvider = ActiveBranchIdFamily._();

final class ActiveBranchIdProvider
    extends $FunctionalProvider<AsyncValue<int?>, int?, Stream<int?>>
    with $FutureModifier<int?>, $StreamProvider<int?> {
  ActiveBranchIdProvider._({
    required ActiveBranchIdFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'activeBranchIdProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$activeBranchIdHash();

  @override
  String toString() {
    return r'activeBranchIdProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<int?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<int?> create(Ref ref) {
    final argument = this.argument as int;
    return activeBranchId(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ActiveBranchIdProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$activeBranchIdHash() => r'c98672469d839b13b69e838b4f3e324221d3ce73';

final class ActiveBranchIdFamily extends $Family
    with $FunctionalFamilyOverride<Stream<int?>, int> {
  ActiveBranchIdFamily._()
    : super(
        retry: null,
        name: r'activeBranchIdProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ActiveBranchIdProvider call(int libraryEntryId) =>
      ActiveBranchIdProvider._(argument: libraryEntryId, from: this);

  @override
  String toString() => r'activeBranchIdProvider';
}

@ProviderFor(LibraryUpdateProgress)
final libraryUpdateProgressProvider = LibraryUpdateProgressProvider._();

final class LibraryUpdateProgressProvider
    extends $NotifierProvider<LibraryUpdateProgress, UpdateProgress?> {
  LibraryUpdateProgressProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'libraryUpdateProgressProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$libraryUpdateProgressHash();

  @$internal
  @override
  LibraryUpdateProgress create() => LibraryUpdateProgress();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UpdateProgress? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UpdateProgress?>(value),
    );
  }
}

String _$libraryUpdateProgressHash() =>
    r'4d3cbc12a979fd9f23129946be4a1d681436f06c';

abstract class _$LibraryUpdateProgress extends $Notifier<UpdateProgress?> {
  UpdateProgress? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<UpdateProgress?, UpdateProgress?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<UpdateProgress?, UpdateProgress?>,
              UpdateProgress?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
