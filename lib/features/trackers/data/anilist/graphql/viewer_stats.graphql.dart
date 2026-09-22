import 'package:gql/ast.dart';

class Query$ViewerStats {
  Query$ViewerStats({this.Viewer});

  factory Query$ViewerStats.fromJson(Map<String, dynamic> json) {
    final l$Viewer = json['Viewer'];
    return Query$ViewerStats(
      Viewer: l$Viewer == null
          ? null
          : Query$ViewerStats$Viewer.fromJson(
              (l$Viewer as Map<String, dynamic>),
            ),
    );
  }

  final Query$ViewerStats$Viewer? Viewer;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$Viewer = Viewer;
    _resultData['Viewer'] = l$Viewer?.toJson();
    return _resultData;
  }

  @override
  int get hashCode {
    final l$Viewer = Viewer;
    return Object.hashAll([l$Viewer]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Query$ViewerStats || runtimeType != other.runtimeType) {
      return false;
    }
    final l$Viewer = Viewer;
    final lOther$Viewer = other.Viewer;
    if (l$Viewer != lOther$Viewer) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Query$ViewerStats on Query$ViewerStats {
  CopyWith$Query$ViewerStats<Query$ViewerStats> get copyWith =>
      CopyWith$Query$ViewerStats(this, (i) => i);
}

abstract class CopyWith$Query$ViewerStats<TRes> {
  factory CopyWith$Query$ViewerStats(
    Query$ViewerStats instance,
    TRes Function(Query$ViewerStats) then,
  ) = _CopyWithImpl$Query$ViewerStats;

  factory CopyWith$Query$ViewerStats.stub(TRes res) =
      _CopyWithStubImpl$Query$ViewerStats;

  TRes call({Query$ViewerStats$Viewer? Viewer});
  CopyWith$Query$ViewerStats$Viewer<TRes> get Viewer;
}

class _CopyWithImpl$Query$ViewerStats<TRes>
    implements CopyWith$Query$ViewerStats<TRes> {
  _CopyWithImpl$Query$ViewerStats(this._instance, this._then);

  final Query$ViewerStats _instance;

  final TRes Function(Query$ViewerStats) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({Object? Viewer = _undefined}) => _then(
    Query$ViewerStats(
      Viewer: Viewer == _undefined
          ? _instance.Viewer
          : (Viewer as Query$ViewerStats$Viewer?),
    ),
  );

  CopyWith$Query$ViewerStats$Viewer<TRes> get Viewer {
    final local$Viewer = _instance.Viewer;
    return local$Viewer == null
        ? CopyWith$Query$ViewerStats$Viewer.stub(_then(_instance))
        : CopyWith$Query$ViewerStats$Viewer(
            local$Viewer,
            (e) => call(Viewer: e),
          );
  }
}

class _CopyWithStubImpl$Query$ViewerStats<TRes>
    implements CopyWith$Query$ViewerStats<TRes> {
  _CopyWithStubImpl$Query$ViewerStats(this._res);

  TRes _res;

  call({Query$ViewerStats$Viewer? Viewer}) => _res;

  CopyWith$Query$ViewerStats$Viewer<TRes> get Viewer =>
      CopyWith$Query$ViewerStats$Viewer.stub(_res);
}

const documentNodeQueryViewerStats = DocumentNode(
  definitions: [
    OperationDefinitionNode(
      type: OperationType.query,
      name: NameNode(value: 'ViewerStats'),
      variableDefinitions: [],
      directives: [],
      selectionSet: SelectionSetNode(
        selections: [
          FieldNode(
            name: NameNode(value: 'Viewer'),
            alias: null,
            arguments: [],
            directives: [],
            selectionSet: SelectionSetNode(
              selections: [
                FieldNode(
                  name: NameNode(value: 'statistics'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: SelectionSetNode(
                    selections: [
                      FieldNode(
                        name: NameNode(value: 'anime'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: SelectionSetNode(
                          selections: [
                            FieldNode(
                              name: NameNode(value: 'count'),
                              alias: null,
                              arguments: [],
                              directives: [],
                              selectionSet: null,
                            ),
                            FieldNode(
                              name: NameNode(value: 'episodesWatched'),
                              alias: null,
                              arguments: [],
                              directives: [],
                              selectionSet: null,
                            ),
                            FieldNode(
                              name: NameNode(value: 'minutesWatched'),
                              alias: null,
                              arguments: [],
                              directives: [],
                              selectionSet: null,
                            ),
                            FieldNode(
                              name: NameNode(value: 'meanScore'),
                              alias: null,
                              arguments: [],
                              directives: [],
                              selectionSet: null,
                            ),
                          ],
                        ),
                      ),
                      FieldNode(
                        name: NameNode(value: 'manga'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: SelectionSetNode(
                          selections: [
                            FieldNode(
                              name: NameNode(value: 'count'),
                              alias: null,
                              arguments: [],
                              directives: [],
                              selectionSet: null,
                            ),
                            FieldNode(
                              name: NameNode(value: 'chaptersRead'),
                              alias: null,
                              arguments: [],
                              directives: [],
                              selectionSet: null,
                            ),
                            FieldNode(
                              name: NameNode(value: 'volumesRead'),
                              alias: null,
                              arguments: [],
                              directives: [],
                              selectionSet: null,
                            ),
                            FieldNode(
                              name: NameNode(value: 'meanScore'),
                              alias: null,
                              arguments: [],
                              directives: [],
                              selectionSet: null,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  ],
);

class Query$ViewerStats$Viewer {
  Query$ViewerStats$Viewer({this.statistics});

  factory Query$ViewerStats$Viewer.fromJson(Map<String, dynamic> json) {
    final l$statistics = json['statistics'];
    return Query$ViewerStats$Viewer(
      statistics: l$statistics == null
          ? null
          : Query$ViewerStats$Viewer$statistics.fromJson(
              (l$statistics as Map<String, dynamic>),
            ),
    );
  }

  final Query$ViewerStats$Viewer$statistics? statistics;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$statistics = statistics;
    _resultData['statistics'] = l$statistics?.toJson();
    return _resultData;
  }

  @override
  int get hashCode {
    final l$statistics = statistics;
    return Object.hashAll([l$statistics]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Query$ViewerStats$Viewer ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$statistics = statistics;
    final lOther$statistics = other.statistics;
    if (l$statistics != lOther$statistics) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Query$ViewerStats$Viewer
    on Query$ViewerStats$Viewer {
  CopyWith$Query$ViewerStats$Viewer<Query$ViewerStats$Viewer> get copyWith =>
      CopyWith$Query$ViewerStats$Viewer(this, (i) => i);
}

abstract class CopyWith$Query$ViewerStats$Viewer<TRes> {
  factory CopyWith$Query$ViewerStats$Viewer(
    Query$ViewerStats$Viewer instance,
    TRes Function(Query$ViewerStats$Viewer) then,
  ) = _CopyWithImpl$Query$ViewerStats$Viewer;

  factory CopyWith$Query$ViewerStats$Viewer.stub(TRes res) =
      _CopyWithStubImpl$Query$ViewerStats$Viewer;

  TRes call({Query$ViewerStats$Viewer$statistics? statistics});
  CopyWith$Query$ViewerStats$Viewer$statistics<TRes> get statistics;
}

class _CopyWithImpl$Query$ViewerStats$Viewer<TRes>
    implements CopyWith$Query$ViewerStats$Viewer<TRes> {
  _CopyWithImpl$Query$ViewerStats$Viewer(this._instance, this._then);

  final Query$ViewerStats$Viewer _instance;

  final TRes Function(Query$ViewerStats$Viewer) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({Object? statistics = _undefined}) => _then(
    Query$ViewerStats$Viewer(
      statistics: statistics == _undefined
          ? _instance.statistics
          : (statistics as Query$ViewerStats$Viewer$statistics?),
    ),
  );

  CopyWith$Query$ViewerStats$Viewer$statistics<TRes> get statistics {
    final local$statistics = _instance.statistics;
    return local$statistics == null
        ? CopyWith$Query$ViewerStats$Viewer$statistics.stub(_then(_instance))
        : CopyWith$Query$ViewerStats$Viewer$statistics(
            local$statistics,
            (e) => call(statistics: e),
          );
  }
}

class _CopyWithStubImpl$Query$ViewerStats$Viewer<TRes>
    implements CopyWith$Query$ViewerStats$Viewer<TRes> {
  _CopyWithStubImpl$Query$ViewerStats$Viewer(this._res);

  TRes _res;

  call({Query$ViewerStats$Viewer$statistics? statistics}) => _res;

  CopyWith$Query$ViewerStats$Viewer$statistics<TRes> get statistics =>
      CopyWith$Query$ViewerStats$Viewer$statistics.stub(_res);
}

class Query$ViewerStats$Viewer$statistics {
  Query$ViewerStats$Viewer$statistics({this.anime, this.manga});

  factory Query$ViewerStats$Viewer$statistics.fromJson(
    Map<String, dynamic> json,
  ) {
    final l$anime = json['anime'];
    final l$manga = json['manga'];
    return Query$ViewerStats$Viewer$statistics(
      anime: l$anime == null
          ? null
          : Query$ViewerStats$Viewer$statistics$anime.fromJson(
              (l$anime as Map<String, dynamic>),
            ),
      manga: l$manga == null
          ? null
          : Query$ViewerStats$Viewer$statistics$manga.fromJson(
              (l$manga as Map<String, dynamic>),
            ),
    );
  }

  final Query$ViewerStats$Viewer$statistics$anime? anime;

  final Query$ViewerStats$Viewer$statistics$manga? manga;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$anime = anime;
    _resultData['anime'] = l$anime?.toJson();
    final l$manga = manga;
    _resultData['manga'] = l$manga?.toJson();
    return _resultData;
  }

  @override
  int get hashCode {
    final l$anime = anime;
    final l$manga = manga;
    return Object.hashAll([l$anime, l$manga]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Query$ViewerStats$Viewer$statistics ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$anime = anime;
    final lOther$anime = other.anime;
    if (l$anime != lOther$anime) {
      return false;
    }
    final l$manga = manga;
    final lOther$manga = other.manga;
    if (l$manga != lOther$manga) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Query$ViewerStats$Viewer$statistics
    on Query$ViewerStats$Viewer$statistics {
  CopyWith$Query$ViewerStats$Viewer$statistics<
    Query$ViewerStats$Viewer$statistics
  >
  get copyWith => CopyWith$Query$ViewerStats$Viewer$statistics(this, (i) => i);
}

abstract class CopyWith$Query$ViewerStats$Viewer$statistics<TRes> {
  factory CopyWith$Query$ViewerStats$Viewer$statistics(
    Query$ViewerStats$Viewer$statistics instance,
    TRes Function(Query$ViewerStats$Viewer$statistics) then,
  ) = _CopyWithImpl$Query$ViewerStats$Viewer$statistics;

  factory CopyWith$Query$ViewerStats$Viewer$statistics.stub(TRes res) =
      _CopyWithStubImpl$Query$ViewerStats$Viewer$statistics;

  TRes call({
    Query$ViewerStats$Viewer$statistics$anime? anime,
    Query$ViewerStats$Viewer$statistics$manga? manga,
  });
  CopyWith$Query$ViewerStats$Viewer$statistics$anime<TRes> get anime;
  CopyWith$Query$ViewerStats$Viewer$statistics$manga<TRes> get manga;
}

class _CopyWithImpl$Query$ViewerStats$Viewer$statistics<TRes>
    implements CopyWith$Query$ViewerStats$Viewer$statistics<TRes> {
  _CopyWithImpl$Query$ViewerStats$Viewer$statistics(this._instance, this._then);

  final Query$ViewerStats$Viewer$statistics _instance;

  final TRes Function(Query$ViewerStats$Viewer$statistics) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({Object? anime = _undefined, Object? manga = _undefined}) => _then(
    Query$ViewerStats$Viewer$statistics(
      anime: anime == _undefined
          ? _instance.anime
          : (anime as Query$ViewerStats$Viewer$statistics$anime?),
      manga: manga == _undefined
          ? _instance.manga
          : (manga as Query$ViewerStats$Viewer$statistics$manga?),
    ),
  );

  CopyWith$Query$ViewerStats$Viewer$statistics$anime<TRes> get anime {
    final local$anime = _instance.anime;
    return local$anime == null
        ? CopyWith$Query$ViewerStats$Viewer$statistics$anime.stub(
            _then(_instance),
          )
        : CopyWith$Query$ViewerStats$Viewer$statistics$anime(
            local$anime,
            (e) => call(anime: e),
          );
  }

  CopyWith$Query$ViewerStats$Viewer$statistics$manga<TRes> get manga {
    final local$manga = _instance.manga;
    return local$manga == null
        ? CopyWith$Query$ViewerStats$Viewer$statistics$manga.stub(
            _then(_instance),
          )
        : CopyWith$Query$ViewerStats$Viewer$statistics$manga(
            local$manga,
            (e) => call(manga: e),
          );
  }
}

class _CopyWithStubImpl$Query$ViewerStats$Viewer$statistics<TRes>
    implements CopyWith$Query$ViewerStats$Viewer$statistics<TRes> {
  _CopyWithStubImpl$Query$ViewerStats$Viewer$statistics(this._res);

  TRes _res;

  call({
    Query$ViewerStats$Viewer$statistics$anime? anime,
    Query$ViewerStats$Viewer$statistics$manga? manga,
  }) => _res;

  CopyWith$Query$ViewerStats$Viewer$statistics$anime<TRes> get anime =>
      CopyWith$Query$ViewerStats$Viewer$statistics$anime.stub(_res);

  CopyWith$Query$ViewerStats$Viewer$statistics$manga<TRes> get manga =>
      CopyWith$Query$ViewerStats$Viewer$statistics$manga.stub(_res);
}

class Query$ViewerStats$Viewer$statistics$anime {
  Query$ViewerStats$Viewer$statistics$anime({
    required this.count,
    required this.episodesWatched,
    required this.minutesWatched,
    required this.meanScore,
  });

  factory Query$ViewerStats$Viewer$statistics$anime.fromJson(
    Map<String, dynamic> json,
  ) {
    final l$count = json['count'];
    final l$episodesWatched = json['episodesWatched'];
    final l$minutesWatched = json['minutesWatched'];
    final l$meanScore = json['meanScore'];
    return Query$ViewerStats$Viewer$statistics$anime(
      count: (l$count as int),
      episodesWatched: (l$episodesWatched as int),
      minutesWatched: (l$minutesWatched as int),
      meanScore: (l$meanScore as num).toDouble(),
    );
  }

  final int count;

  final int episodesWatched;

  final int minutesWatched;

  final double meanScore;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$count = count;
    _resultData['count'] = l$count;
    final l$episodesWatched = episodesWatched;
    _resultData['episodesWatched'] = l$episodesWatched;
    final l$minutesWatched = minutesWatched;
    _resultData['minutesWatched'] = l$minutesWatched;
    final l$meanScore = meanScore;
    _resultData['meanScore'] = l$meanScore;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$count = count;
    final l$episodesWatched = episodesWatched;
    final l$minutesWatched = minutesWatched;
    final l$meanScore = meanScore;
    return Object.hashAll([
      l$count,
      l$episodesWatched,
      l$minutesWatched,
      l$meanScore,
    ]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Query$ViewerStats$Viewer$statistics$anime ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$count = count;
    final lOther$count = other.count;
    if (l$count != lOther$count) {
      return false;
    }
    final l$episodesWatched = episodesWatched;
    final lOther$episodesWatched = other.episodesWatched;
    if (l$episodesWatched != lOther$episodesWatched) {
      return false;
    }
    final l$minutesWatched = minutesWatched;
    final lOther$minutesWatched = other.minutesWatched;
    if (l$minutesWatched != lOther$minutesWatched) {
      return false;
    }
    final l$meanScore = meanScore;
    final lOther$meanScore = other.meanScore;
    if (l$meanScore != lOther$meanScore) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Query$ViewerStats$Viewer$statistics$anime
    on Query$ViewerStats$Viewer$statistics$anime {
  CopyWith$Query$ViewerStats$Viewer$statistics$anime<
    Query$ViewerStats$Viewer$statistics$anime
  >
  get copyWith =>
      CopyWith$Query$ViewerStats$Viewer$statistics$anime(this, (i) => i);
}

abstract class CopyWith$Query$ViewerStats$Viewer$statistics$anime<TRes> {
  factory CopyWith$Query$ViewerStats$Viewer$statistics$anime(
    Query$ViewerStats$Viewer$statistics$anime instance,
    TRes Function(Query$ViewerStats$Viewer$statistics$anime) then,
  ) = _CopyWithImpl$Query$ViewerStats$Viewer$statistics$anime;

  factory CopyWith$Query$ViewerStats$Viewer$statistics$anime.stub(TRes res) =
      _CopyWithStubImpl$Query$ViewerStats$Viewer$statistics$anime;

  TRes call({
    int? count,
    int? episodesWatched,
    int? minutesWatched,
    double? meanScore,
  });
}

class _CopyWithImpl$Query$ViewerStats$Viewer$statistics$anime<TRes>
    implements CopyWith$Query$ViewerStats$Viewer$statistics$anime<TRes> {
  _CopyWithImpl$Query$ViewerStats$Viewer$statistics$anime(
    this._instance,
    this._then,
  );

  final Query$ViewerStats$Viewer$statistics$anime _instance;

  final TRes Function(Query$ViewerStats$Viewer$statistics$anime) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? count = _undefined,
    Object? episodesWatched = _undefined,
    Object? minutesWatched = _undefined,
    Object? meanScore = _undefined,
  }) => _then(
    Query$ViewerStats$Viewer$statistics$anime(
      count: count == _undefined || count == null
          ? _instance.count
          : (count as int),
      episodesWatched: episodesWatched == _undefined || episodesWatched == null
          ? _instance.episodesWatched
          : (episodesWatched as int),
      minutesWatched: minutesWatched == _undefined || minutesWatched == null
          ? _instance.minutesWatched
          : (minutesWatched as int),
      meanScore: meanScore == _undefined || meanScore == null
          ? _instance.meanScore
          : (meanScore as double),
    ),
  );
}

class _CopyWithStubImpl$Query$ViewerStats$Viewer$statistics$anime<TRes>
    implements CopyWith$Query$ViewerStats$Viewer$statistics$anime<TRes> {
  _CopyWithStubImpl$Query$ViewerStats$Viewer$statistics$anime(this._res);

  TRes _res;

  call({
    int? count,
    int? episodesWatched,
    int? minutesWatched,
    double? meanScore,
  }) => _res;
}

class Query$ViewerStats$Viewer$statistics$manga {
  Query$ViewerStats$Viewer$statistics$manga({
    required this.count,
    required this.chaptersRead,
    required this.volumesRead,
    required this.meanScore,
  });

  factory Query$ViewerStats$Viewer$statistics$manga.fromJson(
    Map<String, dynamic> json,
  ) {
    final l$count = json['count'];
    final l$chaptersRead = json['chaptersRead'];
    final l$volumesRead = json['volumesRead'];
    final l$meanScore = json['meanScore'];
    return Query$ViewerStats$Viewer$statistics$manga(
      count: (l$count as int),
      chaptersRead: (l$chaptersRead as int),
      volumesRead: (l$volumesRead as int),
      meanScore: (l$meanScore as num).toDouble(),
    );
  }

  final int count;

  final int chaptersRead;

  final int volumesRead;

  final double meanScore;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$count = count;
    _resultData['count'] = l$count;
    final l$chaptersRead = chaptersRead;
    _resultData['chaptersRead'] = l$chaptersRead;
    final l$volumesRead = volumesRead;
    _resultData['volumesRead'] = l$volumesRead;
    final l$meanScore = meanScore;
    _resultData['meanScore'] = l$meanScore;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$count = count;
    final l$chaptersRead = chaptersRead;
    final l$volumesRead = volumesRead;
    final l$meanScore = meanScore;
    return Object.hashAll([
      l$count,
      l$chaptersRead,
      l$volumesRead,
      l$meanScore,
    ]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Query$ViewerStats$Viewer$statistics$manga ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$count = count;
    final lOther$count = other.count;
    if (l$count != lOther$count) {
      return false;
    }
    final l$chaptersRead = chaptersRead;
    final lOther$chaptersRead = other.chaptersRead;
    if (l$chaptersRead != lOther$chaptersRead) {
      return false;
    }
    final l$volumesRead = volumesRead;
    final lOther$volumesRead = other.volumesRead;
    if (l$volumesRead != lOther$volumesRead) {
      return false;
    }
    final l$meanScore = meanScore;
    final lOther$meanScore = other.meanScore;
    if (l$meanScore != lOther$meanScore) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Query$ViewerStats$Viewer$statistics$manga
    on Query$ViewerStats$Viewer$statistics$manga {
  CopyWith$Query$ViewerStats$Viewer$statistics$manga<
    Query$ViewerStats$Viewer$statistics$manga
  >
  get copyWith =>
      CopyWith$Query$ViewerStats$Viewer$statistics$manga(this, (i) => i);
}

abstract class CopyWith$Query$ViewerStats$Viewer$statistics$manga<TRes> {
  factory CopyWith$Query$ViewerStats$Viewer$statistics$manga(
    Query$ViewerStats$Viewer$statistics$manga instance,
    TRes Function(Query$ViewerStats$Viewer$statistics$manga) then,
  ) = _CopyWithImpl$Query$ViewerStats$Viewer$statistics$manga;

  factory CopyWith$Query$ViewerStats$Viewer$statistics$manga.stub(TRes res) =
      _CopyWithStubImpl$Query$ViewerStats$Viewer$statistics$manga;

  TRes call({
    int? count,
    int? chaptersRead,
    int? volumesRead,
    double? meanScore,
  });
}

class _CopyWithImpl$Query$ViewerStats$Viewer$statistics$manga<TRes>
    implements CopyWith$Query$ViewerStats$Viewer$statistics$manga<TRes> {
  _CopyWithImpl$Query$ViewerStats$Viewer$statistics$manga(
    this._instance,
    this._then,
  );

  final Query$ViewerStats$Viewer$statistics$manga _instance;

  final TRes Function(Query$ViewerStats$Viewer$statistics$manga) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? count = _undefined,
    Object? chaptersRead = _undefined,
    Object? volumesRead = _undefined,
    Object? meanScore = _undefined,
  }) => _then(
    Query$ViewerStats$Viewer$statistics$manga(
      count: count == _undefined || count == null
          ? _instance.count
          : (count as int),
      chaptersRead: chaptersRead == _undefined || chaptersRead == null
          ? _instance.chaptersRead
          : (chaptersRead as int),
      volumesRead: volumesRead == _undefined || volumesRead == null
          ? _instance.volumesRead
          : (volumesRead as int),
      meanScore: meanScore == _undefined || meanScore == null
          ? _instance.meanScore
          : (meanScore as double),
    ),
  );
}

class _CopyWithStubImpl$Query$ViewerStats$Viewer$statistics$manga<TRes>
    implements CopyWith$Query$ViewerStats$Viewer$statistics$manga<TRes> {
  _CopyWithStubImpl$Query$ViewerStats$Viewer$statistics$manga(this._res);

  TRes _res;

  call({int? count, int? chaptersRead, int? volumesRead, double? meanScore}) =>
      _res;
}
