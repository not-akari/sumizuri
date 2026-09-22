import 'fragments.graphql.dart';

import 'package:gql/ast.dart';

import 'schema.graphql.dart';

class Variables$Query$UserList {
  factory Variables$Query$UserList({
    required int userId,
    required Enum$MediaType type,
    int? chunk,
    int? perChunk,
  }) => Variables$Query$UserList._({
    r'userId': userId,
    r'type': type,
    if (chunk != null) r'chunk': chunk,
    if (perChunk != null) r'perChunk': perChunk,
  });

  Variables$Query$UserList._(this._$data);

  factory Variables$Query$UserList.fromJson(Map<String, dynamic> data) {
    final result$data = <String, dynamic>{};
    final l$userId = data['userId'];
    result$data['userId'] = (l$userId as int);
    final l$type = data['type'];
    result$data['type'] = fromJson$Enum$MediaType((l$type as String));
    if (data.containsKey('chunk')) {
      final l$chunk = data['chunk'];
      result$data['chunk'] = (l$chunk as int?);
    }
    if (data.containsKey('perChunk')) {
      final l$perChunk = data['perChunk'];
      result$data['perChunk'] = (l$perChunk as int?);
    }
    return Variables$Query$UserList._(result$data);
  }

  Map<String, dynamic> _$data;

  int get userId => (_$data['userId'] as int);

  Enum$MediaType get type => (_$data['type'] as Enum$MediaType);

  int? get chunk => (_$data['chunk'] as int?);

  int? get perChunk => (_$data['perChunk'] as int?);

  Map<String, dynamic> toJson() {
    final result$data = <String, dynamic>{};
    final l$userId = userId;
    result$data['userId'] = l$userId;
    final l$type = type;
    result$data['type'] = toJson$Enum$MediaType(l$type);
    if (_$data.containsKey('chunk')) {
      final l$chunk = chunk;
      result$data['chunk'] = l$chunk;
    }
    if (_$data.containsKey('perChunk')) {
      final l$perChunk = perChunk;
      result$data['perChunk'] = l$perChunk;
    }
    return result$data;
  }

  CopyWith$Variables$Query$UserList<Variables$Query$UserList> get copyWith =>
      CopyWith$Variables$Query$UserList(this, (i) => i);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Variables$Query$UserList ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$userId = userId;
    final lOther$userId = other.userId;
    if (l$userId != lOther$userId) {
      return false;
    }
    final l$type = type;
    final lOther$type = other.type;
    if (l$type != lOther$type) {
      return false;
    }
    final l$chunk = chunk;
    final lOther$chunk = other.chunk;
    if (_$data.containsKey('chunk') != other._$data.containsKey('chunk')) {
      return false;
    }
    if (l$chunk != lOther$chunk) {
      return false;
    }
    final l$perChunk = perChunk;
    final lOther$perChunk = other.perChunk;
    if (_$data.containsKey('perChunk') !=
        other._$data.containsKey('perChunk')) {
      return false;
    }
    if (l$perChunk != lOther$perChunk) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode {
    final l$userId = userId;
    final l$type = type;
    final l$chunk = chunk;
    final l$perChunk = perChunk;
    return Object.hashAll([
      l$userId,
      l$type,
      _$data.containsKey('chunk') ? l$chunk : const {},
      _$data.containsKey('perChunk') ? l$perChunk : const {},
    ]);
  }
}

abstract class CopyWith$Variables$Query$UserList<TRes> {
  factory CopyWith$Variables$Query$UserList(
    Variables$Query$UserList instance,
    TRes Function(Variables$Query$UserList) then,
  ) = _CopyWithImpl$Variables$Query$UserList;

  factory CopyWith$Variables$Query$UserList.stub(TRes res) =
      _CopyWithStubImpl$Variables$Query$UserList;

  TRes call({int? userId, Enum$MediaType? type, int? chunk, int? perChunk});
}

class _CopyWithImpl$Variables$Query$UserList<TRes>
    implements CopyWith$Variables$Query$UserList<TRes> {
  _CopyWithImpl$Variables$Query$UserList(this._instance, this._then);

  final Variables$Query$UserList _instance;

  final TRes Function(Variables$Query$UserList) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? userId = _undefined,
    Object? type = _undefined,
    Object? chunk = _undefined,
    Object? perChunk = _undefined,
  }) => _then(
    Variables$Query$UserList._({
      ..._instance._$data,
      if (userId != _undefined && userId != null) 'userId': (userId as int),
      if (type != _undefined && type != null) 'type': (type as Enum$MediaType),
      if (chunk != _undefined) 'chunk': (chunk as int?),
      if (perChunk != _undefined) 'perChunk': (perChunk as int?),
    }),
  );
}

class _CopyWithStubImpl$Variables$Query$UserList<TRes>
    implements CopyWith$Variables$Query$UserList<TRes> {
  _CopyWithStubImpl$Variables$Query$UserList(this._res);

  TRes _res;

  call({int? userId, Enum$MediaType? type, int? chunk, int? perChunk}) => _res;
}

class Query$UserList {
  Query$UserList({this.MediaListCollection});

  factory Query$UserList.fromJson(Map<String, dynamic> json) {
    final l$MediaListCollection = json['MediaListCollection'];
    return Query$UserList(
      MediaListCollection: l$MediaListCollection == null
          ? null
          : Query$UserList$MediaListCollection.fromJson(
              (l$MediaListCollection as Map<String, dynamic>),
            ),
    );
  }

  final Query$UserList$MediaListCollection? MediaListCollection;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$MediaListCollection = MediaListCollection;
    _resultData['MediaListCollection'] = l$MediaListCollection?.toJson();
    return _resultData;
  }

  @override
  int get hashCode {
    final l$MediaListCollection = MediaListCollection;
    return Object.hashAll([l$MediaListCollection]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Query$UserList || runtimeType != other.runtimeType) {
      return false;
    }
    final l$MediaListCollection = MediaListCollection;
    final lOther$MediaListCollection = other.MediaListCollection;
    if (l$MediaListCollection != lOther$MediaListCollection) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Query$UserList on Query$UserList {
  CopyWith$Query$UserList<Query$UserList> get copyWith =>
      CopyWith$Query$UserList(this, (i) => i);
}

abstract class CopyWith$Query$UserList<TRes> {
  factory CopyWith$Query$UserList(
    Query$UserList instance,
    TRes Function(Query$UserList) then,
  ) = _CopyWithImpl$Query$UserList;

  factory CopyWith$Query$UserList.stub(TRes res) =
      _CopyWithStubImpl$Query$UserList;

  TRes call({Query$UserList$MediaListCollection? MediaListCollection});
  CopyWith$Query$UserList$MediaListCollection<TRes> get MediaListCollection;
}

class _CopyWithImpl$Query$UserList<TRes>
    implements CopyWith$Query$UserList<TRes> {
  _CopyWithImpl$Query$UserList(this._instance, this._then);

  final Query$UserList _instance;

  final TRes Function(Query$UserList) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({Object? MediaListCollection = _undefined}) => _then(
    Query$UserList(
      MediaListCollection: MediaListCollection == _undefined
          ? _instance.MediaListCollection
          : (MediaListCollection as Query$UserList$MediaListCollection?),
    ),
  );

  CopyWith$Query$UserList$MediaListCollection<TRes> get MediaListCollection {
    final local$MediaListCollection = _instance.MediaListCollection;
    return local$MediaListCollection == null
        ? CopyWith$Query$UserList$MediaListCollection.stub(_then(_instance))
        : CopyWith$Query$UserList$MediaListCollection(
            local$MediaListCollection,
            (e) => call(MediaListCollection: e),
          );
  }
}

class _CopyWithStubImpl$Query$UserList<TRes>
    implements CopyWith$Query$UserList<TRes> {
  _CopyWithStubImpl$Query$UserList(this._res);

  TRes _res;

  call({Query$UserList$MediaListCollection? MediaListCollection}) => _res;

  CopyWith$Query$UserList$MediaListCollection<TRes> get MediaListCollection =>
      CopyWith$Query$UserList$MediaListCollection.stub(_res);
}

const documentNodeQueryUserList = DocumentNode(
  definitions: [
    OperationDefinitionNode(
      type: OperationType.query,
      name: NameNode(value: 'UserList'),
      variableDefinitions: [
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'userId')),
          type: NamedTypeNode(name: NameNode(value: 'Int'), isNonNull: true),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'type')),
          type: NamedTypeNode(
            name: NameNode(value: 'MediaType'),
            isNonNull: true,
          ),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'chunk')),
          type: NamedTypeNode(name: NameNode(value: 'Int'), isNonNull: false),
          defaultValue: DefaultValueNode(value: IntValueNode(value: '1')),
          directives: [],
        ),
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'perChunk')),
          type: NamedTypeNode(name: NameNode(value: 'Int'), isNonNull: false),
          defaultValue: DefaultValueNode(value: IntValueNode(value: '100')),
          directives: [],
        ),
      ],
      directives: [],
      selectionSet: SelectionSetNode(
        selections: [
          FieldNode(
            name: NameNode(value: 'MediaListCollection'),
            alias: null,
            arguments: [
              ArgumentNode(
                name: NameNode(value: 'userId'),
                value: VariableNode(name: NameNode(value: 'userId')),
              ),
              ArgumentNode(
                name: NameNode(value: 'type'),
                value: VariableNode(name: NameNode(value: 'type')),
              ),
              ArgumentNode(
                name: NameNode(value: 'chunk'),
                value: VariableNode(name: NameNode(value: 'chunk')),
              ),
              ArgumentNode(
                name: NameNode(value: 'perChunk'),
                value: VariableNode(name: NameNode(value: 'perChunk')),
              ),
              ArgumentNode(
                name: NameNode(value: 'forceSingleCompletedList'),
                value: BooleanValueNode(value: true),
              ),
            ],
            directives: [],
            selectionSet: SelectionSetNode(
              selections: [
                FieldNode(
                  name: NameNode(value: 'hasNextChunk'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: null,
                ),
                FieldNode(
                  name: NameNode(value: 'lists'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: SelectionSetNode(
                    selections: [
                      FieldNode(
                        name: NameNode(value: 'entries'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: SelectionSetNode(
                          selections: [
                            FragmentSpreadNode(
                              name: NameNode(value: 'ListEntry'),
                              directives: [],
                            ),
                            FieldNode(
                              name: NameNode(value: 'media'),
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
    fragmentDefinitionListEntry,
    fragmentDefinitionMediaCore,
  ],
);

class Query$UserList$MediaListCollection {
  Query$UserList$MediaListCollection({this.hasNextChunk, this.lists});

  factory Query$UserList$MediaListCollection.fromJson(
    Map<String, dynamic> json,
  ) {
    final l$hasNextChunk = json['hasNextChunk'];
    final l$lists = json['lists'];
    return Query$UserList$MediaListCollection(
      hasNextChunk: (l$hasNextChunk as bool?),
      lists: (l$lists as List<dynamic>?)
          ?.map(
            (e) => e == null
                ? null
                : Query$UserList$MediaListCollection$lists.fromJson(
                    (e as Map<String, dynamic>),
                  ),
          )
          .toList(),
    );
  }

  final bool? hasNextChunk;

  final List<Query$UserList$MediaListCollection$lists?>? lists;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$hasNextChunk = hasNextChunk;
    _resultData['hasNextChunk'] = l$hasNextChunk;
    final l$lists = lists;
    _resultData['lists'] = l$lists?.map((e) => e?.toJson()).toList();
    return _resultData;
  }

  @override
  int get hashCode {
    final l$hasNextChunk = hasNextChunk;
    final l$lists = lists;
    return Object.hashAll([
      l$hasNextChunk,
      l$lists == null ? null : Object.hashAll(l$lists.map((v) => v)),
    ]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Query$UserList$MediaListCollection ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$hasNextChunk = hasNextChunk;
    final lOther$hasNextChunk = other.hasNextChunk;
    if (l$hasNextChunk != lOther$hasNextChunk) {
      return false;
    }
    final l$lists = lists;
    final lOther$lists = other.lists;
    if (l$lists != null && lOther$lists != null) {
      if (l$lists.length != lOther$lists.length) {
        return false;
      }
      for (int i = 0; i < l$lists.length; i++) {
        final l$lists$entry = l$lists[i];
        final lOther$lists$entry = lOther$lists[i];
        if (l$lists$entry != lOther$lists$entry) {
          return false;
        }
      }
    } else if (l$lists != lOther$lists) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Query$UserList$MediaListCollection
    on Query$UserList$MediaListCollection {
  CopyWith$Query$UserList$MediaListCollection<
    Query$UserList$MediaListCollection
  >
  get copyWith => CopyWith$Query$UserList$MediaListCollection(this, (i) => i);
}

abstract class CopyWith$Query$UserList$MediaListCollection<TRes> {
  factory CopyWith$Query$UserList$MediaListCollection(
    Query$UserList$MediaListCollection instance,
    TRes Function(Query$UserList$MediaListCollection) then,
  ) = _CopyWithImpl$Query$UserList$MediaListCollection;

  factory CopyWith$Query$UserList$MediaListCollection.stub(TRes res) =
      _CopyWithStubImpl$Query$UserList$MediaListCollection;

  TRes call({
    bool? hasNextChunk,
    List<Query$UserList$MediaListCollection$lists?>? lists,
  });
  TRes lists(
    Iterable<Query$UserList$MediaListCollection$lists?>? Function(
      Iterable<
        CopyWith$Query$UserList$MediaListCollection$lists<
          Query$UserList$MediaListCollection$lists
        >?
      >?,
    )
    _fn,
  );
}

class _CopyWithImpl$Query$UserList$MediaListCollection<TRes>
    implements CopyWith$Query$UserList$MediaListCollection<TRes> {
  _CopyWithImpl$Query$UserList$MediaListCollection(this._instance, this._then);

  final Query$UserList$MediaListCollection _instance;

  final TRes Function(Query$UserList$MediaListCollection) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({Object? hasNextChunk = _undefined, Object? lists = _undefined}) =>
      _then(
        Query$UserList$MediaListCollection(
          hasNextChunk: hasNextChunk == _undefined
              ? _instance.hasNextChunk
              : (hasNextChunk as bool?),
          lists: lists == _undefined
              ? _instance.lists
              : (lists as List<Query$UserList$MediaListCollection$lists?>?),
        ),
      );

  TRes lists(
    Iterable<Query$UserList$MediaListCollection$lists?>? Function(
      Iterable<
        CopyWith$Query$UserList$MediaListCollection$lists<
          Query$UserList$MediaListCollection$lists
        >?
      >?,
    )
    _fn,
  ) => call(
    lists: _fn(
      _instance.lists?.map(
        (e) => e == null
            ? null
            : CopyWith$Query$UserList$MediaListCollection$lists(e, (i) => i),
      ),
    )?.toList(),
  );
}

class _CopyWithStubImpl$Query$UserList$MediaListCollection<TRes>
    implements CopyWith$Query$UserList$MediaListCollection<TRes> {
  _CopyWithStubImpl$Query$UserList$MediaListCollection(this._res);

  TRes _res;

  call({
    bool? hasNextChunk,
    List<Query$UserList$MediaListCollection$lists?>? lists,
  }) => _res;

  lists(_fn) => _res;
}

class Query$UserList$MediaListCollection$lists {
  Query$UserList$MediaListCollection$lists({this.entries});

  factory Query$UserList$MediaListCollection$lists.fromJson(
    Map<String, dynamic> json,
  ) {
    final l$entries = json['entries'];
    return Query$UserList$MediaListCollection$lists(
      entries: (l$entries as List<dynamic>?)
          ?.map(
            (e) => e == null
                ? null
                : Query$UserList$MediaListCollection$lists$entries.fromJson(
                    (e as Map<String, dynamic>),
                  ),
          )
          .toList(),
    );
  }

  final List<Query$UserList$MediaListCollection$lists$entries?>? entries;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$entries = entries;
    _resultData['entries'] = l$entries?.map((e) => e?.toJson()).toList();
    return _resultData;
  }

  @override
  int get hashCode {
    final l$entries = entries;
    return Object.hashAll([
      l$entries == null ? null : Object.hashAll(l$entries.map((v) => v)),
    ]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Query$UserList$MediaListCollection$lists ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$entries = entries;
    final lOther$entries = other.entries;
    if (l$entries != null && lOther$entries != null) {
      if (l$entries.length != lOther$entries.length) {
        return false;
      }
      for (int i = 0; i < l$entries.length; i++) {
        final l$entries$entry = l$entries[i];
        final lOther$entries$entry = lOther$entries[i];
        if (l$entries$entry != lOther$entries$entry) {
          return false;
        }
      }
    } else if (l$entries != lOther$entries) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Query$UserList$MediaListCollection$lists
    on Query$UserList$MediaListCollection$lists {
  CopyWith$Query$UserList$MediaListCollection$lists<
    Query$UserList$MediaListCollection$lists
  >
  get copyWith =>
      CopyWith$Query$UserList$MediaListCollection$lists(this, (i) => i);
}

abstract class CopyWith$Query$UserList$MediaListCollection$lists<TRes> {
  factory CopyWith$Query$UserList$MediaListCollection$lists(
    Query$UserList$MediaListCollection$lists instance,
    TRes Function(Query$UserList$MediaListCollection$lists) then,
  ) = _CopyWithImpl$Query$UserList$MediaListCollection$lists;

  factory CopyWith$Query$UserList$MediaListCollection$lists.stub(TRes res) =
      _CopyWithStubImpl$Query$UserList$MediaListCollection$lists;

  TRes call({List<Query$UserList$MediaListCollection$lists$entries?>? entries});
  TRes entries(
    Iterable<Query$UserList$MediaListCollection$lists$entries?>? Function(
      Iterable<
        CopyWith$Query$UserList$MediaListCollection$lists$entries<
          Query$UserList$MediaListCollection$lists$entries
        >?
      >?,
    )
    _fn,
  );
}

class _CopyWithImpl$Query$UserList$MediaListCollection$lists<TRes>
    implements CopyWith$Query$UserList$MediaListCollection$lists<TRes> {
  _CopyWithImpl$Query$UserList$MediaListCollection$lists(
    this._instance,
    this._then,
  );

  final Query$UserList$MediaListCollection$lists _instance;

  final TRes Function(Query$UserList$MediaListCollection$lists) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({Object? entries = _undefined}) => _then(
    Query$UserList$MediaListCollection$lists(
      entries: entries == _undefined
          ? _instance.entries
          : (entries
                as List<Query$UserList$MediaListCollection$lists$entries?>?),
    ),
  );

  TRes entries(
    Iterable<Query$UserList$MediaListCollection$lists$entries?>? Function(
      Iterable<
        CopyWith$Query$UserList$MediaListCollection$lists$entries<
          Query$UserList$MediaListCollection$lists$entries
        >?
      >?,
    )
    _fn,
  ) => call(
    entries: _fn(
      _instance.entries?.map(
        (e) => e == null
            ? null
            : CopyWith$Query$UserList$MediaListCollection$lists$entries(
                e,
                (i) => i,
              ),
      ),
    )?.toList(),
  );
}

class _CopyWithStubImpl$Query$UserList$MediaListCollection$lists<TRes>
    implements CopyWith$Query$UserList$MediaListCollection$lists<TRes> {
  _CopyWithStubImpl$Query$UserList$MediaListCollection$lists(this._res);

  TRes _res;

  call({List<Query$UserList$MediaListCollection$lists$entries?>? entries}) =>
      _res;

  entries(_fn) => _res;
}

class Query$UserList$MediaListCollection$lists$entries
    implements Fragment$ListEntry {
  Query$UserList$MediaListCollection$lists$entries({
    required this.id,
    required this.mediaId,
    this.status,
    this.progress,
    this.progressVolumes,
    this.score,
    this.repeat,
    this.startedAt,
    this.completedAt,
    this.updatedAt,
    this.media,
  });

  factory Query$UserList$MediaListCollection$lists$entries.fromJson(
    Map<String, dynamic> json,
  ) {
    final l$id = json['id'];
    final l$mediaId = json['mediaId'];
    final l$status = json['status'];
    final l$progress = json['progress'];
    final l$progressVolumes = json['progressVolumes'];
    final l$score = json['score'];
    final l$repeat = json['repeat'];
    final l$startedAt = json['startedAt'];
    final l$completedAt = json['completedAt'];
    final l$updatedAt = json['updatedAt'];
    final l$media = json['media'];
    return Query$UserList$MediaListCollection$lists$entries(
      id: (l$id as int),
      mediaId: (l$mediaId as int),
      status: l$status == null
          ? null
          : fromJson$Enum$MediaListStatus((l$status as String)),
      progress: (l$progress as int?),
      progressVolumes: (l$progressVolumes as int?),
      score: (l$score as num?)?.toDouble(),
      repeat: (l$repeat as int?),
      startedAt: l$startedAt == null
          ? null
          : Query$UserList$MediaListCollection$lists$entries$startedAt.fromJson(
              (l$startedAt as Map<String, dynamic>),
            ),
      completedAt: l$completedAt == null
          ? null
          : Query$UserList$MediaListCollection$lists$entries$completedAt.fromJson(
              (l$completedAt as Map<String, dynamic>),
            ),
      updatedAt: (l$updatedAt as int?),
      media: l$media == null
          ? null
          : Fragment$MediaCore.fromJson((l$media as Map<String, dynamic>)),
    );
  }

  final int id;

  final int mediaId;

  final Enum$MediaListStatus? status;

  final int? progress;

  final int? progressVolumes;

  final double? score;

  final int? repeat;

  final Query$UserList$MediaListCollection$lists$entries$startedAt? startedAt;

  final Query$UserList$MediaListCollection$lists$entries$completedAt?
  completedAt;

  final int? updatedAt;

  final Fragment$MediaCore? media;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$id = id;
    _resultData['id'] = l$id;
    final l$mediaId = mediaId;
    _resultData['mediaId'] = l$mediaId;
    final l$status = status;
    _resultData['status'] = l$status == null
        ? null
        : toJson$Enum$MediaListStatus(l$status);
    final l$progress = progress;
    _resultData['progress'] = l$progress;
    final l$progressVolumes = progressVolumes;
    _resultData['progressVolumes'] = l$progressVolumes;
    final l$score = score;
    _resultData['score'] = l$score;
    final l$repeat = repeat;
    _resultData['repeat'] = l$repeat;
    final l$startedAt = startedAt;
    _resultData['startedAt'] = l$startedAt?.toJson();
    final l$completedAt = completedAt;
    _resultData['completedAt'] = l$completedAt?.toJson();
    final l$updatedAt = updatedAt;
    _resultData['updatedAt'] = l$updatedAt;
    final l$media = media;
    _resultData['media'] = l$media?.toJson();
    return _resultData;
  }

  @override
  int get hashCode {
    final l$id = id;
    final l$mediaId = mediaId;
    final l$status = status;
    final l$progress = progress;
    final l$progressVolumes = progressVolumes;
    final l$score = score;
    final l$repeat = repeat;
    final l$startedAt = startedAt;
    final l$completedAt = completedAt;
    final l$updatedAt = updatedAt;
    final l$media = media;
    return Object.hashAll([
      l$id,
      l$mediaId,
      l$status,
      l$progress,
      l$progressVolumes,
      l$score,
      l$repeat,
      l$startedAt,
      l$completedAt,
      l$updatedAt,
      l$media,
    ]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Query$UserList$MediaListCollection$lists$entries ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$id = id;
    final lOther$id = other.id;
    if (l$id != lOther$id) {
      return false;
    }
    final l$mediaId = mediaId;
    final lOther$mediaId = other.mediaId;
    if (l$mediaId != lOther$mediaId) {
      return false;
    }
    final l$status = status;
    final lOther$status = other.status;
    if (l$status != lOther$status) {
      return false;
    }
    final l$progress = progress;
    final lOther$progress = other.progress;
    if (l$progress != lOther$progress) {
      return false;
    }
    final l$progressVolumes = progressVolumes;
    final lOther$progressVolumes = other.progressVolumes;
    if (l$progressVolumes != lOther$progressVolumes) {
      return false;
    }
    final l$score = score;
    final lOther$score = other.score;
    if (l$score != lOther$score) {
      return false;
    }
    final l$repeat = repeat;
    final lOther$repeat = other.repeat;
    if (l$repeat != lOther$repeat) {
      return false;
    }
    final l$startedAt = startedAt;
    final lOther$startedAt = other.startedAt;
    if (l$startedAt != lOther$startedAt) {
      return false;
    }
    final l$completedAt = completedAt;
    final lOther$completedAt = other.completedAt;
    if (l$completedAt != lOther$completedAt) {
      return false;
    }
    final l$updatedAt = updatedAt;
    final lOther$updatedAt = other.updatedAt;
    if (l$updatedAt != lOther$updatedAt) {
      return false;
    }
    final l$media = media;
    final lOther$media = other.media;
    if (l$media != lOther$media) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Query$UserList$MediaListCollection$lists$entries
    on Query$UserList$MediaListCollection$lists$entries {
  CopyWith$Query$UserList$MediaListCollection$lists$entries<
    Query$UserList$MediaListCollection$lists$entries
  >
  get copyWith =>
      CopyWith$Query$UserList$MediaListCollection$lists$entries(this, (i) => i);
}

abstract class CopyWith$Query$UserList$MediaListCollection$lists$entries<TRes> {
  factory CopyWith$Query$UserList$MediaListCollection$lists$entries(
    Query$UserList$MediaListCollection$lists$entries instance,
    TRes Function(Query$UserList$MediaListCollection$lists$entries) then,
  ) = _CopyWithImpl$Query$UserList$MediaListCollection$lists$entries;

  factory CopyWith$Query$UserList$MediaListCollection$lists$entries.stub(
    TRes res,
  ) = _CopyWithStubImpl$Query$UserList$MediaListCollection$lists$entries;

  TRes call({
    int? id,
    int? mediaId,
    Enum$MediaListStatus? status,
    int? progress,
    int? progressVolumes,
    double? score,
    int? repeat,
    Query$UserList$MediaListCollection$lists$entries$startedAt? startedAt,
    Query$UserList$MediaListCollection$lists$entries$completedAt? completedAt,
    int? updatedAt,
    Fragment$MediaCore? media,
  });
  CopyWith$Query$UserList$MediaListCollection$lists$entries$startedAt<TRes>
  get startedAt;
  CopyWith$Query$UserList$MediaListCollection$lists$entries$completedAt<TRes>
  get completedAt;
  CopyWith$Fragment$MediaCore<TRes> get media;
}

class _CopyWithImpl$Query$UserList$MediaListCollection$lists$entries<TRes>
    implements CopyWith$Query$UserList$MediaListCollection$lists$entries<TRes> {
  _CopyWithImpl$Query$UserList$MediaListCollection$lists$entries(
    this._instance,
    this._then,
  );

  final Query$UserList$MediaListCollection$lists$entries _instance;

  final TRes Function(Query$UserList$MediaListCollection$lists$entries) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? id = _undefined,
    Object? mediaId = _undefined,
    Object? status = _undefined,
    Object? progress = _undefined,
    Object? progressVolumes = _undefined,
    Object? score = _undefined,
    Object? repeat = _undefined,
    Object? startedAt = _undefined,
    Object? completedAt = _undefined,
    Object? updatedAt = _undefined,
    Object? media = _undefined,
  }) => _then(
    Query$UserList$MediaListCollection$lists$entries(
      id: id == _undefined || id == null ? _instance.id : (id as int),
      mediaId: mediaId == _undefined || mediaId == null
          ? _instance.mediaId
          : (mediaId as int),
      status: status == _undefined
          ? _instance.status
          : (status as Enum$MediaListStatus?),
      progress: progress == _undefined
          ? _instance.progress
          : (progress as int?),
      progressVolumes: progressVolumes == _undefined
          ? _instance.progressVolumes
          : (progressVolumes as int?),
      score: score == _undefined ? _instance.score : (score as double?),
      repeat: repeat == _undefined ? _instance.repeat : (repeat as int?),
      startedAt: startedAt == _undefined
          ? _instance.startedAt
          : (startedAt
                as Query$UserList$MediaListCollection$lists$entries$startedAt?),
      completedAt: completedAt == _undefined
          ? _instance.completedAt
          : (completedAt
                as Query$UserList$MediaListCollection$lists$entries$completedAt?),
      updatedAt: updatedAt == _undefined
          ? _instance.updatedAt
          : (updatedAt as int?),
      media: media == _undefined
          ? _instance.media
          : (media as Fragment$MediaCore?),
    ),
  );

  CopyWith$Query$UserList$MediaListCollection$lists$entries$startedAt<TRes>
  get startedAt {
    final local$startedAt = _instance.startedAt;
    return local$startedAt == null
        ? CopyWith$Query$UserList$MediaListCollection$lists$entries$startedAt.stub(
            _then(_instance),
          )
        : CopyWith$Query$UserList$MediaListCollection$lists$entries$startedAt(
            local$startedAt,
            (e) => call(startedAt: e),
          );
  }

  CopyWith$Query$UserList$MediaListCollection$lists$entries$completedAt<TRes>
  get completedAt {
    final local$completedAt = _instance.completedAt;
    return local$completedAt == null
        ? CopyWith$Query$UserList$MediaListCollection$lists$entries$completedAt.stub(
            _then(_instance),
          )
        : CopyWith$Query$UserList$MediaListCollection$lists$entries$completedAt(
            local$completedAt,
            (e) => call(completedAt: e),
          );
  }

  CopyWith$Fragment$MediaCore<TRes> get media {
    final local$media = _instance.media;
    return local$media == null
        ? CopyWith$Fragment$MediaCore.stub(_then(_instance))
        : CopyWith$Fragment$MediaCore(local$media, (e) => call(media: e));
  }
}

class _CopyWithStubImpl$Query$UserList$MediaListCollection$lists$entries<TRes>
    implements CopyWith$Query$UserList$MediaListCollection$lists$entries<TRes> {
  _CopyWithStubImpl$Query$UserList$MediaListCollection$lists$entries(this._res);

  TRes _res;

  call({
    int? id,
    int? mediaId,
    Enum$MediaListStatus? status,
    int? progress,
    int? progressVolumes,
    double? score,
    int? repeat,
    Query$UserList$MediaListCollection$lists$entries$startedAt? startedAt,
    Query$UserList$MediaListCollection$lists$entries$completedAt? completedAt,
    int? updatedAt,
    Fragment$MediaCore? media,
  }) => _res;

  CopyWith$Query$UserList$MediaListCollection$lists$entries$startedAt<TRes>
  get startedAt =>
      CopyWith$Query$UserList$MediaListCollection$lists$entries$startedAt.stub(
        _res,
      );

  CopyWith$Query$UserList$MediaListCollection$lists$entries$completedAt<TRes>
  get completedAt =>
      CopyWith$Query$UserList$MediaListCollection$lists$entries$completedAt.stub(
        _res,
      );

  CopyWith$Fragment$MediaCore<TRes> get media =>
      CopyWith$Fragment$MediaCore.stub(_res);
}

class Query$UserList$MediaListCollection$lists$entries$startedAt
    implements Fragment$ListEntry$startedAt {
  Query$UserList$MediaListCollection$lists$entries$startedAt({
    this.year,
    this.month,
    this.day,
  });

  factory Query$UserList$MediaListCollection$lists$entries$startedAt.fromJson(
    Map<String, dynamic> json,
  ) {
    final l$year = json['year'];
    final l$month = json['month'];
    final l$day = json['day'];
    return Query$UserList$MediaListCollection$lists$entries$startedAt(
      year: (l$year as int?),
      month: (l$month as int?),
      day: (l$day as int?),
    );
  }

  final int? year;

  final int? month;

  final int? day;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$year = year;
    _resultData['year'] = l$year;
    final l$month = month;
    _resultData['month'] = l$month;
    final l$day = day;
    _resultData['day'] = l$day;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$year = year;
    final l$month = month;
    final l$day = day;
    return Object.hashAll([l$year, l$month, l$day]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Query$UserList$MediaListCollection$lists$entries$startedAt ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$year = year;
    final lOther$year = other.year;
    if (l$year != lOther$year) {
      return false;
    }
    final l$month = month;
    final lOther$month = other.month;
    if (l$month != lOther$month) {
      return false;
    }
    final l$day = day;
    final lOther$day = other.day;
    if (l$day != lOther$day) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Query$UserList$MediaListCollection$lists$entries$startedAt
    on Query$UserList$MediaListCollection$lists$entries$startedAt {
  CopyWith$Query$UserList$MediaListCollection$lists$entries$startedAt<
    Query$UserList$MediaListCollection$lists$entries$startedAt
  >
  get copyWith =>
      CopyWith$Query$UserList$MediaListCollection$lists$entries$startedAt(
        this,
        (i) => i,
      );
}

abstract class CopyWith$Query$UserList$MediaListCollection$lists$entries$startedAt<
  TRes
> {
  factory CopyWith$Query$UserList$MediaListCollection$lists$entries$startedAt(
    Query$UserList$MediaListCollection$lists$entries$startedAt instance,
    TRes Function(Query$UserList$MediaListCollection$lists$entries$startedAt)
    then,
  ) = _CopyWithImpl$Query$UserList$MediaListCollection$lists$entries$startedAt;

  factory CopyWith$Query$UserList$MediaListCollection$lists$entries$startedAt.stub(
    TRes res,
  ) = _CopyWithStubImpl$Query$UserList$MediaListCollection$lists$entries$startedAt;

  TRes call({int? year, int? month, int? day});
}

class _CopyWithImpl$Query$UserList$MediaListCollection$lists$entries$startedAt<
  TRes
>
    implements
        CopyWith$Query$UserList$MediaListCollection$lists$entries$startedAt<
          TRes
        > {
  _CopyWithImpl$Query$UserList$MediaListCollection$lists$entries$startedAt(
    this._instance,
    this._then,
  );

  final Query$UserList$MediaListCollection$lists$entries$startedAt _instance;

  final TRes Function(
    Query$UserList$MediaListCollection$lists$entries$startedAt,
  )
  _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? year = _undefined,
    Object? month = _undefined,
    Object? day = _undefined,
  }) => _then(
    Query$UserList$MediaListCollection$lists$entries$startedAt(
      year: year == _undefined ? _instance.year : (year as int?),
      month: month == _undefined ? _instance.month : (month as int?),
      day: day == _undefined ? _instance.day : (day as int?),
    ),
  );
}

class _CopyWithStubImpl$Query$UserList$MediaListCollection$lists$entries$startedAt<
  TRes
>
    implements
        CopyWith$Query$UserList$MediaListCollection$lists$entries$startedAt<
          TRes
        > {
  _CopyWithStubImpl$Query$UserList$MediaListCollection$lists$entries$startedAt(
    this._res,
  );

  TRes _res;

  call({int? year, int? month, int? day}) => _res;
}

class Query$UserList$MediaListCollection$lists$entries$completedAt
    implements Fragment$ListEntry$completedAt {
  Query$UserList$MediaListCollection$lists$entries$completedAt({
    this.year,
    this.month,
    this.day,
  });

  factory Query$UserList$MediaListCollection$lists$entries$completedAt.fromJson(
    Map<String, dynamic> json,
  ) {
    final l$year = json['year'];
    final l$month = json['month'];
    final l$day = json['day'];
    return Query$UserList$MediaListCollection$lists$entries$completedAt(
      year: (l$year as int?),
      month: (l$month as int?),
      day: (l$day as int?),
    );
  }

  final int? year;

  final int? month;

  final int? day;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$year = year;
    _resultData['year'] = l$year;
    final l$month = month;
    _resultData['month'] = l$month;
    final l$day = day;
    _resultData['day'] = l$day;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$year = year;
    final l$month = month;
    final l$day = day;
    return Object.hashAll([l$year, l$month, l$day]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other
            is! Query$UserList$MediaListCollection$lists$entries$completedAt ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$year = year;
    final lOther$year = other.year;
    if (l$year != lOther$year) {
      return false;
    }
    final l$month = month;
    final lOther$month = other.month;
    if (l$month != lOther$month) {
      return false;
    }
    final l$day = day;
    final lOther$day = other.day;
    if (l$day != lOther$day) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Query$UserList$MediaListCollection$lists$entries$completedAt
    on Query$UserList$MediaListCollection$lists$entries$completedAt {
  CopyWith$Query$UserList$MediaListCollection$lists$entries$completedAt<
    Query$UserList$MediaListCollection$lists$entries$completedAt
  >
  get copyWith =>
      CopyWith$Query$UserList$MediaListCollection$lists$entries$completedAt(
        this,
        (i) => i,
      );
}

abstract class CopyWith$Query$UserList$MediaListCollection$lists$entries$completedAt<
  TRes
> {
  factory CopyWith$Query$UserList$MediaListCollection$lists$entries$completedAt(
    Query$UserList$MediaListCollection$lists$entries$completedAt instance,
    TRes Function(Query$UserList$MediaListCollection$lists$entries$completedAt)
    then,
  ) = _CopyWithImpl$Query$UserList$MediaListCollection$lists$entries$completedAt;

  factory CopyWith$Query$UserList$MediaListCollection$lists$entries$completedAt.stub(
    TRes res,
  ) = _CopyWithStubImpl$Query$UserList$MediaListCollection$lists$entries$completedAt;

  TRes call({int? year, int? month, int? day});
}

class _CopyWithImpl$Query$UserList$MediaListCollection$lists$entries$completedAt<
  TRes
>
    implements
        CopyWith$Query$UserList$MediaListCollection$lists$entries$completedAt<
          TRes
        > {
  _CopyWithImpl$Query$UserList$MediaListCollection$lists$entries$completedAt(
    this._instance,
    this._then,
  );

  final Query$UserList$MediaListCollection$lists$entries$completedAt _instance;

  final TRes Function(
    Query$UserList$MediaListCollection$lists$entries$completedAt,
  )
  _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? year = _undefined,
    Object? month = _undefined,
    Object? day = _undefined,
  }) => _then(
    Query$UserList$MediaListCollection$lists$entries$completedAt(
      year: year == _undefined ? _instance.year : (year as int?),
      month: month == _undefined ? _instance.month : (month as int?),
      day: day == _undefined ? _instance.day : (day as int?),
    ),
  );
}

class _CopyWithStubImpl$Query$UserList$MediaListCollection$lists$entries$completedAt<
  TRes
>
    implements
        CopyWith$Query$UserList$MediaListCollection$lists$entries$completedAt<
          TRes
        > {
  _CopyWithStubImpl$Query$UserList$MediaListCollection$lists$entries$completedAt(
    this._res,
  );

  TRes _res;

  call({int? year, int? month, int? day}) => _res;
}
