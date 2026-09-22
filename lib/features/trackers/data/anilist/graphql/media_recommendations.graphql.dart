import 'fragments.graphql.dart';

import 'package:gql/ast.dart';

class Variables$Query$MediaRecommendations {
  factory Variables$Query$MediaRecommendations({
    required int id,
    int? perPage,
  }) => Variables$Query$MediaRecommendations._({
    r'id': id,
    if (perPage != null) r'perPage': perPage,
  });

  Variables$Query$MediaRecommendations._(this._$data);

  factory Variables$Query$MediaRecommendations.fromJson(
    Map<String, dynamic> data,
  ) {
    final result$data = <String, dynamic>{};
    final l$id = data['id'];
    result$data['id'] = (l$id as int);
    if (data.containsKey('perPage')) {
      final l$perPage = data['perPage'];
      result$data['perPage'] = (l$perPage as int?);
    }
    return Variables$Query$MediaRecommendations._(result$data);
  }

  Map<String, dynamic> _$data;

  int get id => (_$data['id'] as int);

  int? get perPage => (_$data['perPage'] as int?);

  Map<String, dynamic> toJson() {
    final result$data = <String, dynamic>{};
    final l$id = id;
    result$data['id'] = l$id;
    if (_$data.containsKey('perPage')) {
      final l$perPage = perPage;
      result$data['perPage'] = l$perPage;
    }
    return result$data;
  }

  CopyWith$Variables$Query$MediaRecommendations<
    Variables$Query$MediaRecommendations
  >
  get copyWith => CopyWith$Variables$Query$MediaRecommendations(this, (i) => i);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Variables$Query$MediaRecommendations ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$id = id;
    final lOther$id = other.id;
    if (l$id != lOther$id) {
      return false;
    }
    final l$perPage = perPage;
    final lOther$perPage = other.perPage;
    if (_$data.containsKey('perPage') != other._$data.containsKey('perPage')) {
      return false;
    }
    if (l$perPage != lOther$perPage) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode {
    final l$id = id;
    final l$perPage = perPage;
    return Object.hashAll([
      l$id,
      _$data.containsKey('perPage') ? l$perPage : const {},
    ]);
  }
}

abstract class CopyWith$Variables$Query$MediaRecommendations<TRes> {
  factory CopyWith$Variables$Query$MediaRecommendations(
    Variables$Query$MediaRecommendations instance,
    TRes Function(Variables$Query$MediaRecommendations) then,
  ) = _CopyWithImpl$Variables$Query$MediaRecommendations;

  factory CopyWith$Variables$Query$MediaRecommendations.stub(TRes res) =
      _CopyWithStubImpl$Variables$Query$MediaRecommendations;

  TRes call({int? id, int? perPage});
}

class _CopyWithImpl$Variables$Query$MediaRecommendations<TRes>
    implements CopyWith$Variables$Query$MediaRecommendations<TRes> {
  _CopyWithImpl$Variables$Query$MediaRecommendations(
    this._instance,
    this._then,
  );

  final Variables$Query$MediaRecommendations _instance;

  final TRes Function(Variables$Query$MediaRecommendations) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({Object? id = _undefined, Object? perPage = _undefined}) => _then(
    Variables$Query$MediaRecommendations._({
      ..._instance._$data,
      if (id != _undefined && id != null) 'id': (id as int),
      if (perPage != _undefined) 'perPage': (perPage as int?),
    }),
  );
}

class _CopyWithStubImpl$Variables$Query$MediaRecommendations<TRes>
    implements CopyWith$Variables$Query$MediaRecommendations<TRes> {
  _CopyWithStubImpl$Variables$Query$MediaRecommendations(this._res);

  TRes _res;

  call({int? id, int? perPage}) => _res;
}

class Query$MediaRecommendations {
  Query$MediaRecommendations({this.Media});

  factory Query$MediaRecommendations.fromJson(Map<String, dynamic> json) {
    final l$Media = json['Media'];
    return Query$MediaRecommendations(
      Media: l$Media == null
          ? null
          : Query$MediaRecommendations$Media.fromJson(
              (l$Media as Map<String, dynamic>),
            ),
    );
  }

  final Query$MediaRecommendations$Media? Media;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$Media = Media;
    _resultData['Media'] = l$Media?.toJson();
    return _resultData;
  }

  @override
  int get hashCode {
    final l$Media = Media;
    return Object.hashAll([l$Media]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Query$MediaRecommendations ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$Media = Media;
    final lOther$Media = other.Media;
    if (l$Media != lOther$Media) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Query$MediaRecommendations
    on Query$MediaRecommendations {
  CopyWith$Query$MediaRecommendations<Query$MediaRecommendations>
  get copyWith => CopyWith$Query$MediaRecommendations(this, (i) => i);
}

abstract class CopyWith$Query$MediaRecommendations<TRes> {
  factory CopyWith$Query$MediaRecommendations(
    Query$MediaRecommendations instance,
    TRes Function(Query$MediaRecommendations) then,
  ) = _CopyWithImpl$Query$MediaRecommendations;

  factory CopyWith$Query$MediaRecommendations.stub(TRes res) =
      _CopyWithStubImpl$Query$MediaRecommendations;

  TRes call({Query$MediaRecommendations$Media? Media});
  CopyWith$Query$MediaRecommendations$Media<TRes> get Media;
}

class _CopyWithImpl$Query$MediaRecommendations<TRes>
    implements CopyWith$Query$MediaRecommendations<TRes> {
  _CopyWithImpl$Query$MediaRecommendations(this._instance, this._then);

  final Query$MediaRecommendations _instance;

  final TRes Function(Query$MediaRecommendations) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({Object? Media = _undefined}) => _then(
    Query$MediaRecommendations(
      Media: Media == _undefined
          ? _instance.Media
          : (Media as Query$MediaRecommendations$Media?),
    ),
  );

  CopyWith$Query$MediaRecommendations$Media<TRes> get Media {
    final local$Media = _instance.Media;
    return local$Media == null
        ? CopyWith$Query$MediaRecommendations$Media.stub(_then(_instance))
        : CopyWith$Query$MediaRecommendations$Media(
            local$Media,
            (e) => call(Media: e),
          );
  }
}

class _CopyWithStubImpl$Query$MediaRecommendations<TRes>
    implements CopyWith$Query$MediaRecommendations<TRes> {
  _CopyWithStubImpl$Query$MediaRecommendations(this._res);

  TRes _res;

  call({Query$MediaRecommendations$Media? Media}) => _res;

  CopyWith$Query$MediaRecommendations$Media<TRes> get Media =>
      CopyWith$Query$MediaRecommendations$Media.stub(_res);
}

const documentNodeQueryMediaRecommendations = DocumentNode(
  definitions: [
    OperationDefinitionNode(
      type: OperationType.query,
      name: NameNode(value: 'MediaRecommendations'),
      variableDefinitions: [
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'id')),
          type: NamedTypeNode(name: NameNode(value: 'Int'), isNonNull: true),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'perPage')),
          type: NamedTypeNode(name: NameNode(value: 'Int'), isNonNull: false),
          defaultValue: DefaultValueNode(value: IntValueNode(value: '12')),
          directives: [],
        ),
      ],
      directives: [],
      selectionSet: SelectionSetNode(
        selections: [
          FieldNode(
            name: NameNode(value: 'Media'),
            alias: null,
            arguments: [
              ArgumentNode(
                name: NameNode(value: 'id'),
                value: VariableNode(name: NameNode(value: 'id')),
              ),
            ],
            directives: [],
            selectionSet: SelectionSetNode(
              selections: [
                FieldNode(
                  name: NameNode(value: 'recommendations'),
                  alias: null,
                  arguments: [
                    ArgumentNode(
                      name: NameNode(value: 'sort'),
                      value: ListValueNode(
                        values: [
                          EnumValueNode(name: NameNode(value: 'RATING_DESC')),
                        ],
                      ),
                    ),
                    ArgumentNode(
                      name: NameNode(value: 'perPage'),
                      value: VariableNode(name: NameNode(value: 'perPage')),
                    ),
                  ],
                  directives: [],
                  selectionSet: SelectionSetNode(
                    selections: [
                      FieldNode(
                        name: NameNode(value: 'nodes'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: SelectionSetNode(
                          selections: [
                            FieldNode(
                              name: NameNode(value: 'mediaRecommendation'),
                              alias: null,
                              arguments: [],
                              directives: [],
                              selectionSet: SelectionSetNode(
                                selections: [
                                  FragmentSpreadNode(
                                    name: NameNode(value: 'MediaCore'),
                                    directives: [],
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
      ),
    ),
    fragmentDefinitionMediaCore,
  ],
);

class Query$MediaRecommendations$Media {
  Query$MediaRecommendations$Media({this.recommendations});

  factory Query$MediaRecommendations$Media.fromJson(Map<String, dynamic> json) {
    final l$recommendations = json['recommendations'];
    return Query$MediaRecommendations$Media(
      recommendations: l$recommendations == null
          ? null
          : Query$MediaRecommendations$Media$recommendations.fromJson(
              (l$recommendations as Map<String, dynamic>),
            ),
    );
  }

  final Query$MediaRecommendations$Media$recommendations? recommendations;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$recommendations = recommendations;
    _resultData['recommendations'] = l$recommendations?.toJson();
    return _resultData;
  }

  @override
  int get hashCode {
    final l$recommendations = recommendations;
    return Object.hashAll([l$recommendations]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Query$MediaRecommendations$Media ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$recommendations = recommendations;
    final lOther$recommendations = other.recommendations;
    if (l$recommendations != lOther$recommendations) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Query$MediaRecommendations$Media
    on Query$MediaRecommendations$Media {
  CopyWith$Query$MediaRecommendations$Media<Query$MediaRecommendations$Media>
  get copyWith => CopyWith$Query$MediaRecommendations$Media(this, (i) => i);
}

abstract class CopyWith$Query$MediaRecommendations$Media<TRes> {
  factory CopyWith$Query$MediaRecommendations$Media(
    Query$MediaRecommendations$Media instance,
    TRes Function(Query$MediaRecommendations$Media) then,
  ) = _CopyWithImpl$Query$MediaRecommendations$Media;

  factory CopyWith$Query$MediaRecommendations$Media.stub(TRes res) =
      _CopyWithStubImpl$Query$MediaRecommendations$Media;

  TRes call({
    Query$MediaRecommendations$Media$recommendations? recommendations,
  });
  CopyWith$Query$MediaRecommendations$Media$recommendations<TRes>
  get recommendations;
}

class _CopyWithImpl$Query$MediaRecommendations$Media<TRes>
    implements CopyWith$Query$MediaRecommendations$Media<TRes> {
  _CopyWithImpl$Query$MediaRecommendations$Media(this._instance, this._then);

  final Query$MediaRecommendations$Media _instance;

  final TRes Function(Query$MediaRecommendations$Media) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({Object? recommendations = _undefined}) => _then(
    Query$MediaRecommendations$Media(
      recommendations: recommendations == _undefined
          ? _instance.recommendations
          : (recommendations
                as Query$MediaRecommendations$Media$recommendations?),
    ),
  );

  CopyWith$Query$MediaRecommendations$Media$recommendations<TRes>
  get recommendations {
    final local$recommendations = _instance.recommendations;
    return local$recommendations == null
        ? CopyWith$Query$MediaRecommendations$Media$recommendations.stub(
            _then(_instance),
          )
        : CopyWith$Query$MediaRecommendations$Media$recommendations(
            local$recommendations,
            (e) => call(recommendations: e),
          );
  }
}

class _CopyWithStubImpl$Query$MediaRecommendations$Media<TRes>
    implements CopyWith$Query$MediaRecommendations$Media<TRes> {
  _CopyWithStubImpl$Query$MediaRecommendations$Media(this._res);

  TRes _res;

  call({Query$MediaRecommendations$Media$recommendations? recommendations}) =>
      _res;

  CopyWith$Query$MediaRecommendations$Media$recommendations<TRes>
  get recommendations =>
      CopyWith$Query$MediaRecommendations$Media$recommendations.stub(_res);
}

class Query$MediaRecommendations$Media$recommendations {
  Query$MediaRecommendations$Media$recommendations({this.nodes});

  factory Query$MediaRecommendations$Media$recommendations.fromJson(
    Map<String, dynamic> json,
  ) {
    final l$nodes = json['nodes'];
    return Query$MediaRecommendations$Media$recommendations(
      nodes: (l$nodes as List<dynamic>?)
          ?.map(
            (e) => e == null
                ? null
                : Query$MediaRecommendations$Media$recommendations$nodes.fromJson(
                    (e as Map<String, dynamic>),
                  ),
          )
          .toList(),
    );
  }

  final List<Query$MediaRecommendations$Media$recommendations$nodes?>? nodes;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$nodes = nodes;
    _resultData['nodes'] = l$nodes?.map((e) => e?.toJson()).toList();
    return _resultData;
  }

  @override
  int get hashCode {
    final l$nodes = nodes;
    return Object.hashAll([
      l$nodes == null ? null : Object.hashAll(l$nodes.map((v) => v)),
    ]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Query$MediaRecommendations$Media$recommendations ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$nodes = nodes;
    final lOther$nodes = other.nodes;
    if (l$nodes != null && lOther$nodes != null) {
      if (l$nodes.length != lOther$nodes.length) {
        return false;
      }
      for (int i = 0; i < l$nodes.length; i++) {
        final l$nodes$entry = l$nodes[i];
        final lOther$nodes$entry = lOther$nodes[i];
        if (l$nodes$entry != lOther$nodes$entry) {
          return false;
        }
      }
    } else if (l$nodes != lOther$nodes) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Query$MediaRecommendations$Media$recommendations
    on Query$MediaRecommendations$Media$recommendations {
  CopyWith$Query$MediaRecommendations$Media$recommendations<
    Query$MediaRecommendations$Media$recommendations
  >
  get copyWith =>
      CopyWith$Query$MediaRecommendations$Media$recommendations(this, (i) => i);
}

abstract class CopyWith$Query$MediaRecommendations$Media$recommendations<TRes> {
  factory CopyWith$Query$MediaRecommendations$Media$recommendations(
    Query$MediaRecommendations$Media$recommendations instance,
    TRes Function(Query$MediaRecommendations$Media$recommendations) then,
  ) = _CopyWithImpl$Query$MediaRecommendations$Media$recommendations;

  factory CopyWith$Query$MediaRecommendations$Media$recommendations.stub(
    TRes res,
  ) = _CopyWithStubImpl$Query$MediaRecommendations$Media$recommendations;

  TRes call({
    List<Query$MediaRecommendations$Media$recommendations$nodes?>? nodes,
  });
  TRes nodes(
    Iterable<Query$MediaRecommendations$Media$recommendations$nodes?>? Function(
      Iterable<
        CopyWith$Query$MediaRecommendations$Media$recommendations$nodes<
          Query$MediaRecommendations$Media$recommendations$nodes
        >?
      >?,
    )
    _fn,
  );
}

class _CopyWithImpl$Query$MediaRecommendations$Media$recommendations<TRes>
    implements CopyWith$Query$MediaRecommendations$Media$recommendations<TRes> {
  _CopyWithImpl$Query$MediaRecommendations$Media$recommendations(
    this._instance,
    this._then,
  );

  final Query$MediaRecommendations$Media$recommendations _instance;

  final TRes Function(Query$MediaRecommendations$Media$recommendations) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({Object? nodes = _undefined}) => _then(
    Query$MediaRecommendations$Media$recommendations(
      nodes: nodes == _undefined
          ? _instance.nodes
          : (nodes
                as List<
                  Query$MediaRecommendations$Media$recommendations$nodes?
                >?),
    ),
  );

  TRes nodes(
    Iterable<Query$MediaRecommendations$Media$recommendations$nodes?>? Function(
      Iterable<
        CopyWith$Query$MediaRecommendations$Media$recommendations$nodes<
          Query$MediaRecommendations$Media$recommendations$nodes
        >?
      >?,
    )
    _fn,
  ) => call(
    nodes: _fn(
      _instance.nodes?.map(
        (e) => e == null
            ? null
            : CopyWith$Query$MediaRecommendations$Media$recommendations$nodes(
                e,
                (i) => i,
              ),
      ),
    )?.toList(),
  );
}

class _CopyWithStubImpl$Query$MediaRecommendations$Media$recommendations<TRes>
    implements CopyWith$Query$MediaRecommendations$Media$recommendations<TRes> {
  _CopyWithStubImpl$Query$MediaRecommendations$Media$recommendations(this._res);

  TRes _res;

  call({
    List<Query$MediaRecommendations$Media$recommendations$nodes?>? nodes,
  }) => _res;

  nodes(_fn) => _res;
}

class Query$MediaRecommendations$Media$recommendations$nodes {
  Query$MediaRecommendations$Media$recommendations$nodes({
    this.mediaRecommendation,
  });

  factory Query$MediaRecommendations$Media$recommendations$nodes.fromJson(
    Map<String, dynamic> json,
  ) {
    final l$mediaRecommendation = json['mediaRecommendation'];
    return Query$MediaRecommendations$Media$recommendations$nodes(
      mediaRecommendation: l$mediaRecommendation == null
          ? null
          : Fragment$MediaCore.fromJson(
              (l$mediaRecommendation as Map<String, dynamic>),
            ),
    );
  }

  final Fragment$MediaCore? mediaRecommendation;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$mediaRecommendation = mediaRecommendation;
    _resultData['mediaRecommendation'] = l$mediaRecommendation?.toJson();
    return _resultData;
  }

  @override
  int get hashCode {
    final l$mediaRecommendation = mediaRecommendation;
    return Object.hashAll([l$mediaRecommendation]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Query$MediaRecommendations$Media$recommendations$nodes ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$mediaRecommendation = mediaRecommendation;
    final lOther$mediaRecommendation = other.mediaRecommendation;
    if (l$mediaRecommendation != lOther$mediaRecommendation) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Query$MediaRecommendations$Media$recommendations$nodes
    on Query$MediaRecommendations$Media$recommendations$nodes {
  CopyWith$Query$MediaRecommendations$Media$recommendations$nodes<
    Query$MediaRecommendations$Media$recommendations$nodes
  >
  get copyWith =>
      CopyWith$Query$MediaRecommendations$Media$recommendations$nodes(
        this,
        (i) => i,
      );
}

abstract class CopyWith$Query$MediaRecommendations$Media$recommendations$nodes<
  TRes
> {
  factory CopyWith$Query$MediaRecommendations$Media$recommendations$nodes(
    Query$MediaRecommendations$Media$recommendations$nodes instance,
    TRes Function(Query$MediaRecommendations$Media$recommendations$nodes) then,
  ) = _CopyWithImpl$Query$MediaRecommendations$Media$recommendations$nodes;

  factory CopyWith$Query$MediaRecommendations$Media$recommendations$nodes.stub(
    TRes res,
  ) = _CopyWithStubImpl$Query$MediaRecommendations$Media$recommendations$nodes;

  TRes call({Fragment$MediaCore? mediaRecommendation});
  CopyWith$Fragment$MediaCore<TRes> get mediaRecommendation;
}

class _CopyWithImpl$Query$MediaRecommendations$Media$recommendations$nodes<TRes>
    implements
        CopyWith$Query$MediaRecommendations$Media$recommendations$nodes<TRes> {
  _CopyWithImpl$Query$MediaRecommendations$Media$recommendations$nodes(
    this._instance,
    this._then,
  );

  final Query$MediaRecommendations$Media$recommendations$nodes _instance;

  final TRes Function(Query$MediaRecommendations$Media$recommendations$nodes)
  _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({Object? mediaRecommendation = _undefined}) => _then(
    Query$MediaRecommendations$Media$recommendations$nodes(
      mediaRecommendation: mediaRecommendation == _undefined
          ? _instance.mediaRecommendation
          : (mediaRecommendation as Fragment$MediaCore?),
    ),
  );

  CopyWith$Fragment$MediaCore<TRes> get mediaRecommendation {
    final local$mediaRecommendation = _instance.mediaRecommendation;
    return local$mediaRecommendation == null
        ? CopyWith$Fragment$MediaCore.stub(_then(_instance))
        : CopyWith$Fragment$MediaCore(
            local$mediaRecommendation,
            (e) => call(mediaRecommendation: e),
          );
  }
}

class _CopyWithStubImpl$Query$MediaRecommendations$Media$recommendations$nodes<
  TRes
>
    implements
        CopyWith$Query$MediaRecommendations$Media$recommendations$nodes<TRes> {
  _CopyWithStubImpl$Query$MediaRecommendations$Media$recommendations$nodes(
    this._res,
  );

  TRes _res;

  call({Fragment$MediaCore? mediaRecommendation}) => _res;

  CopyWith$Fragment$MediaCore<TRes> get mediaRecommendation =>
      CopyWith$Fragment$MediaCore.stub(_res);
}
